// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./library/GhostsLib.sol";
import "./library/ComHandler.sol";
import "@openzeppelin/token/ERC721/IERC721.sol";

interface IGhosts {
    function getUserAcc(address who) external view returns(GhostsLib.User memory);
}


contract GhostsFeats {
    address internal deployer;
    address internal ghostsAddr;

    mapping(address => mapping(bytes32=>uint))  internal protocolActions; // allow protocol data to be stored in mapping
    mapping(address=>GhostsLib.User)            internal addrToUser; // stores the list of feats for each user    
    mapping(address=>GhostsLib.Feat[])          internal addrToFeats; // stores the list of feats for each user
    mapping(uint=>GhostsLib.UserFeats)          internal getUser; // stores the list of feats for each user    
    mapping(uint=>bytes[])                      internal idToComment; // PostId => commentID = comment
    mapping(uint=>uint)                         internal collabNFTs; // Collab ID to NFT
    mapping(uint=>uint)                         internal finalRaceNFTs; // ID to final race NFT
    mapping(uint=>mapping(uint => uint))        internal tokIdToType;  // Token ID > Race ID
    mapping(uint=>uint[])                       internal idToFollowers; // User ID => userID array of who liked the post
    mapping(uint=>uint[])                       internal idToFollowing; // User ID => userID array of who liked the post
    GhostsLib.User[]                            internal allUsers; // Contains all users
    GhostsLib.MiniPost[]                        internal allPosts; // Contains all Posts
    GhostsLib.Feat[]                            internal allFeats; // Contains all feats
    GhostsLib.UserFeats[]                       internal allUserFeats; // Contains all user feats
    GhostsLib.ProtocolMeta                      internal protocolMeta; // Contains all protocol-wide meta
    GhostsLib.RaceNFT[]                         internal allRaceNFTs; // Contains all race NFTs
    GhostsLib.CollabNFT[]                       internal allCollabNFTs; // Contains all collab NFTs
    

    function _createUser(address who, string memory handle, string[] calldata hashes, uint32 userCount) internal returns(uint) {
        return GhostsLib.createUser(addrToUser, getUser, allUserFeats, handle, hashes, userCount);
    }

    function _createFeats(
        bytes32 name,
        bytes32 symbol,
        bytes32 essenceURI,
        bytes32 description,
        uint64 weight,
        uint64 essID,
        uint64 essTier
        ) internal {
        if(!GhostsLib.onlyGhosts(msg.sender, deployer)){
            revert GhostsLib.NotAuthed();
        }

        uint featLen = allFeats.length;
        uint64 featId = featLen == 0 ? 1 : uint64(featLen++);

        GhostsLib.Feat memory feat = GhostsLib.Feat({
            name: name,
            desc: description,
            imageUrl: essenceURI,
            weight: weight,
            essID: featId,
            essTier: essTier,
            earnedAt: uint160(block.timestamp)
        });

        allFeats.push(feat);
    }

    function _startNextRace() internal {
       bool yes = GhostsLib.startNextRace(addrToUser, tokIdToType, allRaceNFTs, finalRaceNFTs, protocolMeta.tokenCount + 1);

         if(!yes){
              revert GhostsLib.NotAuthed();
         }
    }

    function _submitRace(bytes32 answers) internal{
        bool submitted = GhostsLib.submitRace(addrToUser, allRaceNFTs, finalRaceNFTs, answers, protocolMeta.raceCount, protocolMeta.collabCount);
        if(!submitted) revert GhostsLib.NotAuthed();
    }

    function _startNextCollab(uint8 collabID) internal {
        uint tokenID = protocolMeta.tokenCount + 1;
        bool goodToGo = GhostsLib.startNextCollab(addrToUser, tokIdToType, allCollabNFTs, collabID, uint32(tokenID));
        if(!goodToGo) revert GhostsLib.NotAuthed();
    }

    function _submitCollab(bytes32[] calldata guesses, uint32 collabID) internal {
        uint32 collabCount = protocolMeta.collabCount +1;
        uint32 raceCount = protocolMeta.raceCount + 1;
        bool submitted = GhostsLib.submitCollab(addrToUser, allCollabNFTs, guesses, collabCount, raceCount, collabID);
        if(!submitted){
            revert GhostsLib.NotAuthed();
        }
    }

    function _userAwardFeats(uint16 featId, uint16 tier, address userAddr, uint32 profileId) internal {
        GhostsLib.Feat memory feat = allFeats[featId];
        GhostsLib.User memory user = addrToUser[userAddr];
        GhostsLib.UserFeats memory u = getUser[profileId];
        uint16[] memory empty;

        if(u.userAddress == address(0)){
            GhostsLib.createUserFeats(getUser, allUserFeats, user.ccID, user.ghostsID);
        }

        u = getUser[profileId];

        if(u.featsEarned[featId][tier] == tier){
        }else{
            u.featsEarned[featId][tier] = tier;
            feat.earnedAt = uint160(block.timestamp);
            feat.essTier = tier;
            addrToFeats[userAddr].push(feat);            
            ccCollectEss(userAddr, profileId, feat.essID);
        }               
    
    }

    function _followUser(uint32 idToFollow, uint32 idToBeFollowed, address addrToFollow) internal {
        if(idToFollow == idToBeFollowed) revert GhostsLib.NoSuccess();
        bool valid = ComHandler.followUser(idToFollowers, idToFollowing, getUser, addrToUser, idToFollow, addrToFollow);
        if(!valid){
            revert GhostsLib.NotAuthed();
        }
    }


//      /**
//         * @dev Stores the action to the user addr then subscribes to the CC profile
//         * @notice This is the protocol's follow user function
//         * @param idToFollow the address of the user being followed
//         * @param idFollowing the address of the user following another user
//      */
//     function followUser(
//         uint idToFollow,
//         uint idFollowing,
//         address userToFollow
//     ) internal returns (bool) {
//         GhostsLib.UserFeats storage caller = getUser[msg.sender];
//         GhostsLib.UserFeats storage user = getUser[userToFollow];
//         uint[] memory followersArr = user.followers;
//         uint len = followersArr.length;
//         if (msg.sender == userToFollow) {
//             return false;
//         }

//         for (uint i = 0; i < len; ++i) {
//             if(followersArr[i] == idFollowing) revert GhostsLib.AlreadyFollowed(userToFollow);
//         }

//         caller.following.push(idToFollow);
//         user.followers.push(idFollowing);
//         caller.followCount ++;
//         user.followerCount ++;
//         protocolActions[msg.sender][GhostsLib.FOLLOWUSER] ++;
//         emit GhostsLib.NewFollow(idFollowing, idToFollow);
//         delete followersArr;
//         return true;
//     }

//     function unfollowUser(
//         uint idToUnfollow,
//         uint idUnfollowing,
//         address userToUnfollow
//     ) internal returns (bool) {
//         getUser[userToUnfollow].followerCount -= 1;
//         getUser[msg.sender].followCount -= 1;

//         protocolActions[msg.sender][GhostsLib.UNFOLLOWUSER] += 1;

//         delete userIdToFollowed[msg.sender][idToUnfollow];
//         delete userIdToFollowers[userToUnfollow][idUnfollowing];

//         emit GhostsLib.Unfollowed(idUnfollowing, idToUnfollow);
//         return true;
//     }
    
//     function consumeContent(uint256 profileId, uint256 essID) internal {
//         protocolActions[msg.sender][GhostsLib.CONSUMECONTENT] += 1;
//         getUser[msg.sender].consumeCount += 1;
//         ccCollectEss(msg.sender, profileId, essID);
//     }

//     /**
//         * @dev Create Content for protocol uses this function to perform the following:
//         * 1. update protocolAction[] stores the amount of calls to this function
//         * 2. update User.createCount, increment by 1
//         * 3. call function ccRegEssence() to register the essence with the profile
//      */
//     function createContent(
//         uint256 profileId,
//         string calldata name,
//         string calldata symbol,
//         string calldata essenceURI,
//         address /**/,
//         bool /**/,
//         bool /**/,
//         bool allowComments
//          ) internal returns (uint) {
//             GhostsLib.UserFeats storage caller = getUser[msg.sender];
//             bytes[] memory emptyComments;
            
//             if(postCount == 0) {
//                 GhostsLib.MiniPost memory newPostt;
//                 newPostt.creator = msg.sender;
//                 newPostt.creatorCCID = profileId;
//                 newPostt.postId = postCount;
//                 newPostt.likes = 0;
//                 newPostt.dislikes = 0;
//                 newPostt.allowComments = allowComments;
//                 newPostt.uri = essenceURI;
//                 newPostt.comments = emptyComments;               

//                 userPosts[msg.sender].push(newPostt);
//                 posts[postCount] = newPostt;
//                 postCount++;
//                 delete newPostt;
//             }
//             uint actions = protocolActions[msg.sender][GhostsLib.CREATECONTENT] += 1;
            
//             {
//                 bytes memory payload = abi.encodeWithSignature(
//                     "ccRegEssence(uint256, string, string, string, bytes32)",
//                     ghostsCCID, name, symbol, essenceURI, address(0));
                
//                 (bool success,) = ghostsAddr.call(payload);
//                 if(!success) revert GhostsLib.NoSuccess();
//             }
            

//             GhostsLib.MiniPost memory newPost;
//                 newPost.creator = msg.sender;
//                 newPost.creatorCCID = profileId;
//                 newPost.postId = postCount;
//                 newPost.likes = 0;
//                 newPost.dislikes = 0;
//                 newPost.allowComments = allowComments;
//                 newPost.uri = essenceURI;
//                 newPost.comments = emptyComments;               

//                 userPosts[msg.sender].push(newPost);
//                 posts[postCount] = newPost;
//                 delete newPost;
                

//             caller.createCount = actions;
//             ++postCount;
//             return caller.createCount;
//     }

//     function commentContent(
//         bytes calldata comment,
//         uint postId
//     ) internal {
//         GhostsLib.MiniPost storage post = posts[postId];
//         if(post.comments.length == 0){
//             idToComment[postId].push(bytes("."));
//             getUser[ghostsAddr].commentCount = 1;
//             post.comments.push(bytes("."));
//         }

//         if(post.allowComments){
//             uint count = getUser[msg.sender].commentCount;
//             if(count == 0) {
//                 protocolActions[msg.sender][GhostsLib.COMMENTCONTENT] = 1;
//                 getUser[msg.sender].commentCount = 1;
//                 idToComment[postId].push(comment);
//                 post.comments.push(comment);
//             }else{
//                 protocolActions[msg.sender][GhostsLib.COMMENTCONTENT] += 1;
//                 getUser[msg.sender].commentCount += 1;
//                 idToComment[postId].push(comment);
//                 post.comments.push(comment);
//             }
//         }else{revert GhostsLib.NoComments();}
//     }
//     function likePost(uint postId) external {
//         GhostsLib.MiniPost storage post = posts[postId];
//         post.likes = post.likes + 1;
//         postLikes[postId] = postLikes[postId] + 1;
//     }

//     function dislikePost(uint postId) external {
//         GhostsLib.MiniPost storage post = posts[postId];
//         post.dislikes = post.dislikes + 1;
//         postDislikes[postId] = postDislikes[postId] + 1;
//     }

//     function getPost(uint postId) external view returns (GhostsLib.MiniPost memory){
//         return posts[postId];
//     }

//     function getAllUserPosts(address userAddr) external view returns (GhostsLib.MiniPost[] memory){
//         return userPosts[userAddr];
//     }

//     function getPostLikeCount(uint postId) external view returns (uint256) {
//         return postLikes[postId];
//     }

//     function getPostDislikeCount(uint postId) external view returns (uint256) {
//         return postDislikes[postId];
//     }

//     function getPostComments(uint postId) external view returns (bytes[] memory) {
//         return idToComment[postId];
//     }
//     /**
//         * @dev check User.raceID and returns feat level based on completion
//      */



//     /////////////////////////////////
//     ///                           ///
//     ///     Internal Functions    ///
//     ///                           ///
//     /////////////////////////////////
    function ccGetSubNFTAddr(uint256 profileId)
        internal
        view
        returns (address)
    {
        return GhostsLib.ccProfileNFT.getSubscribeNFT(profileId);
    }

    function ccGetEssNFTAddr(uint256 profileId, uint256 essId)
        internal
        view
        returns (address)
    {
        return GhostsLib.ccProfileNFT.getEssenceNFT(profileId, essId);
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


    function _ccRegEssence(DataTypes.RegisterEssenceParams memory params)
        internal
        returns (uint256)
    {
        uint id = GhostsLib.ccProfileNFT.registerEssence(params, '');
        return id; 
    }

    function _ccCollectEss(DataTypes.CollectParams memory params) internal {
        GhostsLib.ccProfileNFT.collect(params, "", "");
    }
}


        /**
//      * @notice Check if the profile issued EssenceNFT is collected by me.
//      *
//      * @param profileId The profile id.
//      * @param essenceId The essence id.
//      * @param me The address to check.
//      * @param _namespace The address of the ccProfileNFT
//      */
//     function isCollectedByMe(
//         uint256 profileId,
//         uint256 essenceId,
//         address me,
//         address _namespace
//     ) external view returns (bool) {
//         address essNFTAddr = IProfileNFT(_namespace).getEssenceNFT(
//             profileId,
//             essenceId
//         );
//         if (essNFTAddr == address(0)) {
//             return false;
//         }

//         return IERC721(essNFTAddr).balanceOf(me) > 0;
//     }

//     /**
//      * @notice Check if the profile is subscribed by me.
//      *
//      * @param profileId The profile id.
//      * @param me The address to check.
//      * @param _namespace The address of the ProfileNFT
//      */
//     function isSubscribedByMe(uint256 profileId, address me, address _namespace)
//         external
//         view
//         returns (bool)
//     {
//         address subNFTAddr = IProfileNFT(_namespace).getSubscribeNFT(profileId);
//         if (subNFTAddr == address(0)) {
//             return false;
//         }
//         return IERC721(subNFTAddr).balanceOf(me) > 0;
//     }

//     function createGhostsCC(string memory handle, string[] memory hashes, address op) internal returns(uint id) {        
//         if(!GhostsLib.onlyGhosts(msg.sender, deployer)){
//             id = 0;
//             revert GhostsLib.NotAuthed();
//         }

//         DataTypes.CreateProfileParams memory params;
//         params.to = msg.sender;
//         params.handle = handle; 
//         params.avatar = hashes[0];
//         params.metadata = hashes[1];
//         params.operator = op;
//         GhostsLib.ccProfileNFT.createProfile(params, '','');
//         uint ccID = GhostsLib.ccProfileNFT.getProfileIdByHandle(handle);
//         GhostsLib.UserFeats memory u = getUser[ghostsAddr];
//         uint[] memory empty;
//         if(u.userAddress == address(0)){
//             GhostsLib.UserFeats memory newUser = GhostsLib.UserFeats({
//                 userAddress: ghostsAddr,
//                 ccID: ccID,
//                 followCount: 0,
//                 followerCount: 0,
//                 commentCount: 0,
//                 consumeCount: 0,
//                 createCount: 0,
//                 followers: empty,
//                 following: empty
//             });
//             getUser[ghostsAddr] = newUser;
//             ghostsCCID = ccID;
//             delete newUser;
//             delete u;
//             return ghostsCCID;
//        }
//     }
// }