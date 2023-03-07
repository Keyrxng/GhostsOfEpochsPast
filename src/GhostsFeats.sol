// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {DataTypes, IProfileNFT} from "./interfaces/IProfileNFT.sol";
import {IGhosts, IGhostsData} from "./interfaces/IGhosts.sol";
import {ICyberNFTBase} from "./interfaces/ICyberNFTBase.sol";

import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "forge-std/Test.sol";

contract GhostsFeats is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 internal constant FOLLOWUSER = keccak256("FollowUser");
    bytes32 internal constant UNFOLLOWUSER = keccak256("UnfollowUser");
    bytes32 internal constant CONSUMECONTENT = keccak256("ConsumeContent");
    bytes32 internal constant CREATECONTENT = keccak256("CreateContent");
    bytes32 internal constant COMMENTCONTENT = keccak256("CreateContent");
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    
    address internal ghostsAddr;
    IProfileNFT internal constant ccProfileNFT =
        IProfileNFT(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271);
    uint public ghostsCCID;
    uint public postCount;
    

    IGhostsData.Feat[] public featsMasterList; // list of feats
    mapping(uint => IGhostsData.Feat) public feats; // feat ID => feat data
    mapping(address => IGhostsData.UserFeats) public getUser; // stores the list of feats for each user
    mapping(address => IGhostsData.Feat[]) public earnedFeats; // feat ID => feat data

    mapping(address => mapping(uint=>uint)) public addrToFeatToTiers; // user > featId > tier
    mapping(address => mapping(bytes32=>uint)) internal protocolActions; // allow protocol data to be stored in mapping
    mapping(uint=>uint) internal featsIdToEssID; // mapping featID => essID

    mapping(uint=>bytes[]) public idToComment; // postId => commentID => comment
    mapping(address=> uint[]) public userIdToFollowers; // userId => list of followers
    mapping(address=> uint[]) public userIdToFollowed; // userId => list of followed
    mapping(uint=>uint) public postLikes; // postId => likes
    mapping(uint=>uint) public postDislikes; // postId => dislikes
    mapping(address=>IGhostsData.MiniPost[]) public userPosts; // user => postList
    mapping(uint=>IGhostsData.MiniPost) public posts; // postId => mini post

    event NewFollow(uint indexed follower, uint indexed followed);
    event Unfollowed(uint indexed follower, uint indexed followed);
    error NoComments();
    error AlreadyFollowed(address userAddress);

    // constructor() {
    //     _disableInitializers();
    // }

    function __GhostsFeats_init(address who) initializer public {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, who);
        _grantRole(UPGRADER_ROLE, who);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        onlyRole(UPGRADER_ROLE)
        override
    {}


    /**
        * @dev Creates the Essence NFT representing each achievement
        * @param name - essence name (the feat name?)
        * @param symbol - essence symbol
        * @param essenceURI - essence URI
     */
    function createAchievements(
        string calldata name,
        string calldata symbol,
        string calldata essenceURI,
        string calldata description,
        uint16 weight,
        uint16 essTier,
        bytes memory payload
        ) internal {
        
        {(bool succ,) = ghostsAddr.call(payload);}
        uint featLen = featsMasterList.length;
        uint featId = featLen == 0 ? 1 : featLen++;

       { IGhostsData.Feat memory feat = IGhostsData.Feat({
            name: bytes(name),
            desc: bytes(description),
            imageUrl: bytes(essenceURI),
            weight: weight,
            essId: featId,
            essTier: essTier,
            earnedAt: block.timestamp
        });

        feats[featId] = feat;
        featsMasterList.push(feat);
        featsIdToEssID[featId] = featId;  
        delete feat;}
    }

    function awardAchievements(address userAddr, uint profileId) public {
        _userFeatCheck(userAddr, profileId);
    }

    function _userFeatCheck(address userAddr, uint profileId) internal {
        uint raceFeat = raceFeatCheck(userAddr);
        uint stbFeat = stbFeatCheck(userAddr);
        uint contribFeat = contribFeatCheck(userAddr);
        uint followingFeat = followingFeatCheck(userAddr);
        uint followerFeat = followerFeatCheck(userAddr);
        uint subscriberFeat = subscriberFeatCheck(userAddr);
        uint contentCreateFeat = contentFeatCheck(userAddr);
        uint contentConsumeFeat = gigaBrainCheck(userAddr);

        uint[] memory tmp = new uint[](8);
        tmp[0] = raceFeat;
        tmp[1] = stbFeat;
        tmp[2] = contribFeat;
        tmp[3] = followerFeat;
        tmp[4] = followingFeat;
        tmp[5] = subscriberFeat;
        tmp[6] = contentCreateFeat;
        tmp[7] = contentConsumeFeat;

        for(uint256 i = 0; i < 8; i++) {
            if(tmp[i] > 0) {
                userAwardFeats(i, tmp[i], userAddr, profileId);
            }
        }
        delete tmp;
    }

    /**
        * @dev adds a feat to User.feats unless the feat is already owned by the user
        * @param featId the feat ID
        * @param tier Tier of feat the User has earned; ex "low = 1, medium = 2, high = 3, T4 = 4"
        * @param userAddr the user's address
     */
    function userAwardFeats(uint featId, uint tier, address userAddr, uint profileId) internal {
        IGhostsData.Feat memory feat = feats[featId];
        IGhostsData.UserFeats storage u = getUser[userAddr];
        uint[] memory empty;

        if(u.userAddress == address(0)){
            IGhostsData.UserFeats memory newUser = IGhostsData.UserFeats({
                userAddress: userAddr,
                ccID: profileId,
                followCount: 0,
                followerCount: 0,
                commentCount: 0,
                consumeCount: 0,
                createCount: 0,
                followers: empty,
                following: empty
            });
            getUser[userAddr] = newUser;
            delete newUser;
            return;
        }else{
        require(featId < featsMasterList.length, "featId out of range");

        if(addrToFeatToTiers[userAddr][featId] >= tier) {
            return;
        }

        uint256 profileId = ghostsCCID; // get users raceID

        IGhostsData.Feat memory tmp = featsMasterList[featId];
        tmp.earnedAt = block.timestamp;
        tmp.essTier = uint16(tier);

        addrToFeatToTiers[userAddr][featId] = tier;

        earnedFeats[userAddr].push(tmp);

        ccCollectEss(userAddr, profileId, feat.essId);
    }
    }

     /**
        * @dev Stores the action to the user addr then subscribes to the CC profile
        * @notice This is the protocol's follow user function
        * @param idToFollow the address of the user being followed
        * @param idFollowing the address of the user following another user
     */
    function followUser(
        uint idToFollow,
        uint idFollowing,
        address userToFollow
    ) public returns (bool) {
        IGhostsData.UserFeats storage caller = getUser[msg.sender];
        IGhostsData.UserFeats storage user = getUser[userToFollow];
        uint[] memory followersArr = user.followers;
        uint len = followersArr.length;
        if (msg.sender == userToFollow) {
            return false;
        }

        for (uint i = 0; i < len; ++i) {
            require(followersArr[i] != idFollowing, "You already follow this user");
        }

        caller.following.push(idToFollow);
        user.followers.push(idFollowing);
        caller.followCount ++;
        user.followerCount ++;
        protocolActions[msg.sender][FOLLOWUSER] ++;
        emit NewFollow(idFollowing, idToFollow);
        delete followersArr;
        return true;
    }

    function unfollowUser(
        uint idToUnfollow,
        uint idUnfollowing,
        address userToUnfollow
    ) public returns (bool) {
        getUser[userToUnfollow].followerCount -= 1;
        getUser[msg.sender].followCount -= 1;

        protocolActions[msg.sender][UNFOLLOWUSER] += 1;

        delete userIdToFollowed[msg.sender][idToUnfollow];
        delete userIdToFollowers[userToUnfollow][idUnfollowing];

        emit Unfollowed(idUnfollowing, idToUnfollow);
        return true;
    }
    
    function consumeContent(uint256 profileId, uint256 essID) public {
        protocolActions[msg.sender][CONSUMECONTENT] += 1;
        getUser[msg.sender].consumeCount += 1;
        ccCollectEss(msg.sender, profileId, essID);
    }

    /**
        * @dev Create Content for protocol uses this function to perform the following:
        * 1. update protocolAction[] stores the amount of calls to this function
        * 2. update User.createCount, increment by 1
        * 3. call function ccRegEssence() to register the essence with the profile
     */
    function createContent(
        uint256 profileId,
        string calldata name,
        string calldata symbol,
        string calldata essenceURI,
        address essenceMw,
        bool transferable,
        bool deployAtReg,
        bool allowComments
         ) public returns (uint) {
            IGhostsData.UserFeats storage caller = getUser[msg.sender];
            bytes[] memory emptyComments;
            
            if(postCount == 0) {
                IGhostsData.MiniPost memory newPost;
                newPost.creator = msg.sender;
                newPost.creatorCCID = profileId;
                newPost.postId = postCount;
                newPost.likes = 0;
                newPost.dislikes = 0;
                newPost.allowComments = allowComments;
                newPost.uri = essenceURI;
                newPost.comments = emptyComments;               

                userPosts[msg.sender].push(newPost);
                posts[postCount] = newPost;
                postCount++;
                delete newPost;
            }
            uint actions = protocolActions[msg.sender][CREATECONTENT] += 1;
            {bytes memory payload = abi.encodeWithSignature(
            "ccRegEssence(uint256, string, string, string, bytes32)",
             ghostsCCID, name, symbol, essenceURI, address(0));
            (bool success,) = ghostsAddr.call(payload);}            

            IGhostsData.MiniPost memory newPost;
                newPost.creator = msg.sender;
                newPost.creatorCCID = profileId;
                newPost.postId = postCount;
                newPost.likes = 0;
                newPost.dislikes = 0;
                newPost.allowComments = allowComments;
                newPost.uri = essenceURI;
                newPost.comments = emptyComments;               

                userPosts[msg.sender].push(newPost);
                posts[postCount] = newPost;
                delete newPost;
                

            caller.createCount = actions;
            ++postCount;
            return caller.createCount;
    }

    function commentContent(
        bytes calldata comment,
        uint postId
    ) public {
        IGhostsData.MiniPost storage post = posts[postId];
        if(post.comments.length == 0){
            idToComment[postId].push(bytes("."));
            getUser[ghostsAddr].commentCount = 1;
            post.comments.push(bytes("."));
        }

        if(post.allowComments){
            uint count = getUser[msg.sender].commentCount;
            if(count == 0) {
                protocolActions[msg.sender][COMMENTCONTENT] = 1;
                getUser[msg.sender].commentCount = 1;
                idToComment[postId].push(comment);
                post.comments.push(comment);
            }else{
                protocolActions[msg.sender][COMMENTCONTENT] += 1;
                getUser[msg.sender].commentCount += 1;
                idToComment[postId].push(comment);
                post.comments.push(comment);
            }
        }else{revert NoComments();}
    }
    function likePost(uint postId) external {
        IGhostsData.MiniPost storage post = posts[postId];
        post.likes = post.likes + 1;
        postLikes[postId] = postLikes[postId] + 1;
    }

    function dislikePost(uint postId) external {
        IGhostsData.MiniPost storage post = posts[postId];
        post.dislikes = post.dislikes + 1;
        postDislikes[postId] = postDislikes[postId] + 1;
    }

    function getPost(uint postId) external view returns (IGhostsData.MiniPost memory){
        return posts[postId];
    }

    function getAllUserPosts(address userAddr) external view returns (IGhostsData.MiniPost[] memory){
        return userPosts[userAddr];
    }

    function getPostLikeCount(uint postId) external view returns (uint256) {
        return postLikes[postId];
    }

    function getPostDislikeCount(uint postId) external view returns (uint256) {
        return postDislikes[postId];
    }

    function getPostComments(uint postId) external view returns (bytes[] memory) {
        return idToComment[postId];
    }
    /**
        * @dev check User.raceID and returns feat level based on completion
     */
    function raceFeatCheck(address userAddr) internal returns (uint8 tier) {
        IGhostsData.User memory user = IGhosts(ghostsAddr).getGhostsProfile(userAddr);
        uint256 currentRaceID = user.raceId;

        if (currentRaceID >= 2) {
            if (currentRaceID < 8) {
                 delete user;
                tier = 1;
            }
        } else if (currentRaceID >= 8) {
            if (currentRaceID < 15) {
         delete user;
                tier = 2;
            }
        } else if (currentRaceID >= 15) {
            if (currentRaceID < 22) {
         delete user;
                tier = 3;
            }
        } else if (currentRaceID >= 22) {
         delete user;
            tier = 4;
        } else {
         delete user;
            tier = 0;
        }
    }

    /**
        * @dev check User.spotTheBugs and returns feat level based on completion
     */
    function stbFeatCheck(address userAddr) internal returns (uint8 tier) {
        uint256 spotTheBugs = IGhosts(ghostsAddr).getGhostsProfile(userAddr).spotTheBugs; // get users spotTheBugs count
        if (spotTheBugs >= 5) {
            if (spotTheBugs < 20) {
                tier = 1;
            }
        } else if (spotTheBugs >= 20) {
            if (spotTheBugs < 50) {
                tier = 2;
            }
        } else if (spotTheBugs >= 50) {
            if (spotTheBugs < 100) {
                tier = 3;
            }
        } else if (spotTheBugs >= 100) {
            tier = 4;
        } else {
            tier = 0;
        }
    }

    /**
        * @dev check User.ctfStbContribs and returns feat level based on completion
     */
    function contribFeatCheck(address userAddr)
        internal
        returns (uint8 tier)
    {
        uint256 contribCount = IGhosts(ghostsAddr).getGhostsProfile(userAddr).ctfStbContribs; // get users contribCount
        if (contribCount >= 1) {
            if (contribCount < 5) {
                tier = 1;
            }
        } else if (contribCount >= 5) {
            if (contribCount < 15) {
                tier = 2;
            }
        } else if (contribCount >= 15) {
            if (contribCount < 30) {
                tier = 3;
            }
        } else if (contribCount >= 30) {
            tier = 4;
        } else {
            tier = 0;
        }
    }

    /**
        * @dev checks protocolActions[userAddr][activityType] and returns feat level based on count
     */
    function followingFeatCheck(address userAddr) internal view returns (uint8 tier) {
        uint256 activityCount = protocolActions[userAddr][FOLLOWUSER]; // get users social activity count
        if (activityCount >= 1) {
            if (activityCount < 5) {
                tier = 1;
            }
        } else if (activityCount >= 5) {
            if (activityCount < 15) {
                tier = 2;
            }
        } else if (activityCount >= 15) {
            if (activityCount < 30) {
                tier = 3;
            }
        } else if (activityCount >= 30) {
            tier = 4;
        } else {
            tier = 0;
        }
    }

    function followerFeatCheck(address userAddr) internal view returns (uint8 tier) {

        uint256 activityCount = getUser[userAddr].followerCount; // get users social activity count

        if (activityCount >= 1) {
            if (activityCount < 5) {
                tier = 1;
                }
            } else if (activityCount >= 5) {
                if (activityCount < 15) {
                    tier = 2;
                }
            } else if (activityCount >= 15) {
                if (activityCount < 30) {
                    tier = 3;
                }
            } else if(activityCount >= 30) {
                tier = 4;
            }else{
                tier = 0;
            }
        }

    /**
        * @dev checks getUser[userAddr].followCount and returns feat level based on count
     */
    function subscriberFeatCheck(address userAddr) internal returns (uint8 tier) {
        
        uint profileId = IGhosts(ghostsAddr).getGhostsProfile(userAddr).ccID;
        address subNFT = ccProfileNFT.getSubscribeNFT(profileId);

        if(subNFT != address(0)) {

            uint subCount = ICyberNFTBase(subNFT).totalMinted();

            if (subCount >= 1) {
                if (subCount < 5) {
                    tier = 1;
                }
            } else if (subCount >= 5) {
                if (subCount < 15) {
                    tier = 2;
                }
            } else if (subCount >= 15) {
                if (subCount < 30) {
                    tier = 3;
                }
            } else if (subCount >= 30) {
                tier = 4;
            } else {
                tier = 0;
            }
        }else{
            tier = 0;
        }
    }

    /**
        * @dev check User.contentPosts and returns feat level based on completion
     */
    function contentFeatCheck(address userAddr) internal view returns (uint8 tier) {
        uint256 contentCount = protocolActions[userAddr][CREATECONTENT]; // get users post count
        if (contentCount >= 1) {
            if (contentCount < 5) {
                tier = 1;
            }
        } else if (contentCount >= 5) {
            if (contentCount < 15) {
                tier = 2;
            }
        } else if (contentCount >= 15) {
            if (contentCount < 30) {
                tier = 3;
            }
        } else if (contentCount >= 30) {
            tier = 4;
        } else {
            tier = 0;
        }
    }

    /**
        * @dev checks getUser[userAddr].consumeContent and returns feat level based on count

     */
    function gigaBrainCheck(address userAddr) internal view returns (uint8 tier) {
        uint256 consumeCount = protocolActions[userAddr][CONSUMECONTENT]; // get users post count
        if (consumeCount >= 1) {
            if (consumeCount < 5) {
                tier = 1;
            }
        } else if (consumeCount >= 5) {
            if (consumeCount < 15) {
                tier = 2;
            }
        } else if (consumeCount >= 15) {
            if (consumeCount < 30) {
                tier = 3;
            }
        } else if (consumeCount >= 30) {
            tier = 4;
        } else {
            tier = 0;
        }
    }

    function tier4Check(address userAddr) external returns(uint8[4] memory tier) {
        
    }


    /////////////////////////////////
    ///                           ///
    ///     Internal Functions    ///
    ///                           ///
    /////////////////////////////////
    function ccGetMetadata(uint256 profileId)
        public
        view
        returns (string memory)
    {
        return ccProfileNFT.getMetadata(profileId);
    }

    function ccGetAvatar(uint256 profileId)
        public
        view
        returns (string memory)
    {
        return ccProfileNFT.getAvatar(profileId);
    }

    function ccGetSubNFTAddr(uint256 profileId)
        public
        view
        returns (address)
    {
        return ccProfileNFT.getSubscribeNFT(profileId);
    }

    function ccGetSubURI(uint256 profileId)
        public
        view
        returns (string memory)
    {
        return ccProfileNFT.getSubscribeNFTTokenURI(profileId);
    }

    function ccGetEssNFTAddr(uint256 profileId, uint256 essId)
        public
        view
        returns (address)
    {
        return ccProfileNFT.getEssenceNFT(profileId, essId);
    }

    function ccGetEssURI(uint256 profileId, uint256 essId)
        public
        view
        returns (string memory)
    {
        return ccProfileNFT.getEssenceNFTTokenURI(profileId, essId);
    }


    function ccRegEssence(
        uint256 profileId,
        string calldata name,
        string calldata symbol,
        string calldata essenceURI,
        address essenceMw
    ) internal returns (uint256) {
        DataTypes.RegisterEssenceParams memory params;

        params.profileId = profileId;
        params.name = name;
        params.symbol = symbol;
        params.essenceTokenURI = essenceURI;
        params.essenceMw = essenceMw;
        params.transferable = true;
        params.deployAtRegister = true;

        return _ccRegEssence(params);
    }

    function ccCollectEss(
        address who,
        uint256 profileId,
        uint256 essenceId
    ) internal {
        DataTypes.CollectParams memory params;
        params.collector = who;
        params.profileId = profileId;
        params.essenceId = essenceId;

        _ccCollectEss(params);
    }

    function ccSetMetadata(uint256 profileId, string calldata metadata)
        public
    {
        _ccSetMetadata(profileId, metadata);
    }

    function ccSetSubData(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata mwData
    ) public {
        _ccSetSubData(profileId, uri, mw, mwData);
    }

    function ccSetEssData(
        uint256 profileId,
        uint256 essId,
        string calldata uri,
        address mw,
        bytes calldata mwData
    ) public {
        _ccSetEssData(profileId, essId, uri, mw, mwData);
    }

    function ccSetPrimary(uint256 profileId) public {
        _ccSetPrimary(profileId);
    }

    function _ccRegEssence(DataTypes.RegisterEssenceParams memory params)
        internal
        returns (uint256)
    {
        uint id = ccProfileNFT.registerEssence(params, '');
        return id; 
    }

    function _ccCollectEss(DataTypes.CollectParams memory params) internal {
        ccProfileNFT.collect(params, "", "");
    }

    function _ccSetMetadata(uint256 profileId, string calldata metadata)
        internal
    {
        ccProfileNFT.setMetadata(profileId, metadata);
    }

    function _ccSetSubData(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata mwData
    ) internal {
        ccProfileNFT.setSubscribeData(profileId, uri, mw, mwData);
    }

    function _ccSetEssData(
        uint256 profileId,
        uint256 essId,
        string calldata uri,
        address mw,
        bytes calldata mwData
    ) internal {
        ccProfileNFT.setEssenceData(profileId, essId, uri, mw, mwData);
    }

    function _ccSetPrimary(uint256 profileId) internal {
        ccProfileNFT.setPrimaryProfile(profileId);
    }

     /**
     * @notice Check if the profile issued EssenceNFT is collected by me.
     *
     * @param profileId The profile id.
     * @param essenceId The essence id.
     * @param me The address to check.
     * @param _namespace The address of the ccProfileNFT
     */
    function isCollectedByMe(
        uint256 profileId,
        uint256 essenceId,
        address me,
        address _namespace
    ) external view returns (bool) {
        address essNFTAddr = IProfileNFT(_namespace).getEssenceNFT(
            profileId,
            essenceId
        );
        if (essNFTAddr == address(0)) {
            return false;
        }

        return IERC721Upgradeable(essNFTAddr).balanceOf(me) > 0;
    }

    /**
     * @notice Check if the profile is subscribed by me.
     *
     * @param profileId The profile id.
     * @param me The address to check.
     * @param _namespace The address of the ProfileNFT
     */
    function isSubscribedByMe(uint256 profileId, address me, address _namespace)
        external
        view
        returns (bool)
    {
        address subNFTAddr = IProfileNFT(_namespace).getSubscribeNFT(profileId);
        if (subNFTAddr == address(0)) {
            return false;
        }
        return IERC721Upgradeable(subNFTAddr).balanceOf(me) > 0;
    }

    function createGhostsCC(string memory handle, string[] memory hashes, address op) internal returns(uint) {        
        DataTypes.CreateProfileParams memory params;
        params.to = msg.sender;
        params.handle = handle; 
        params.avatar = hashes[0];
        params.metadata = hashes[1];
        params.operator = op;
        ccProfileNFT.createProfile(params, '','');
        uint ccID = ccProfileNFT.getProfileIdByHandle(handle);
        IGhostsData.UserFeats memory u = getUser[ghostsAddr];
        uint[] memory empty;
        if(u.userAddress == address(0)){
            IGhostsData.UserFeats memory newUser = IGhostsData.UserFeats({
                userAddress: ghostsAddr,
                ccID: ccID,
                followCount: 0,
                followerCount: 0,
                commentCount: 0,
                consumeCount: 0,
                createCount: 0,
                followers: empty,
                following: empty
            });
            getUser[ghostsAddr] = newUser;
            ghostsCCID = ccID;
            delete newUser;
            delete u;
            return 0;
       }
    }
}