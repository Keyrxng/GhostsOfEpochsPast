// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.9;

// import {DataTypes, IProfileNFT} from "./interfaces/IProfileNFT.sol";
// import {IGhosts, IGhostsData} from "./interfaces/IGhosts.sol";
// import {Ownable} from  "@openzeppelin/access/Ownable.sol";
// import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";
// import {ICyberNFTBase} from "./interfaces/ICyberNFTBase.sol";

// contract GhostsFeats  {
//     bytes32 internal constant FOLLOWUSER = keccak256("FollowUser");
//     bytes32 internal constant UNFOLLOWUSER = keccak256("UnfollowUser");
//     bytes32 internal constant CONSUMECONTENT = keccak256("ConsumeContent");
//     bytes32 internal constant CREATECONTENT = keccak256("CreateContent");
//     bytes32 internal constant COMMENTCONTENT = keccak256("CreateContent");

//     address internal ghostsAddr;
//     IProfileNFT internal constant ccProfileNFT =
//         IProfileNFT(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271);
//     uint public ghostsCCID;
//     uint public postCount;
    
//     IGhostsData.Feat[] public featsMasterList; // list of feats
//     mapping(uint256 => IGhostsData.Feat) public feats; // feat ID => feat data
//     mapping(address => IGhostsData.UserFeats) public getUser; // stores the list of feats for each user
//     mapping(address => IGhostsData.Feat[]) public earnedFeats; // feat ID => feat data

//     mapping(address => mapping(uint=>uint)) public addrToFeatToTiers; // user > featId > tier
//     mapping(address => mapping(bytes32=>uint)) internal protocolActions; // allow protocol data to be stored in mapping
//     mapping(uint=>uint) internal featsIdToEssID; // mapping featID => essID

//     mapping(uint=>bytes[]) public idToComment; // postId => commentID => comment
//     mapping(uint=> uint[]) public userIdToFollowers; // userId => list of followers
//     mapping(uint=> uint[]) public userIdToFollowed; // userId => list of followed
//     mapping(uint=>uint) public postLikes; // postId => likes
//     mapping(uint=>uint) public postDislikes; // postId => dislikes
//     mapping(address=>miniPost[]) public userPosts; // user => postList
//     mapping(uint=>miniPost) public posts; // postId => mini post

//     struct miniPost{
//         address creator;
//         uint creatorCCID;
//         uint postId;
//         bool allowComments;
//         string uri;
//         bytes[] comments;
//     }

//     event NewFollow(uint indexed follower, uint indexed followed);
//     event Unfollowed(uint indexed follower, uint indexed followed);
//     error NoComments();

//     /**
//         * @dev Creates the Essence NFT representing each achievement
//         * @param name - essence name (the feat name?)
//         * @param symbol - essence symbol
//         * @param essenceURI - essence URI
//      */
//     function createAchievements(
//         string calldata name,
//         string calldata symbol,
//         string calldata essenceURI,
//         string calldata description,
//         uint16 weight,
//         uint16 essTier
//         ) internal {
//         uint essID = ccRegEssence(ghostsCCID, name, symbol, essenceURI, address(0), true, true);

//         uint featId = featsMasterList.length;

//         if(featId == 0){
//             IGhostsData.Feat memory placeholder = IGhostsData.Feat({
//                 name: bytes('placeholder'),
//                 desc: bytes('placeholder'),
//                 imageUrl: bytes('placeholder'),
//                 weight: 1,
//                 essId: 1,
//                 essTier: 0,
//                 earnedAt: 1
//             });
//             featsMasterList.push(placeholder);
//             feats[featId] = placeholder;
//             featsIdToEssID[featId] = essID;
//         }

//         IGhostsData.Feat memory feat = IGhostsData.Feat({
//             name: bytes(name),
//             desc: bytes(description),
//             imageUrl: bytes(essenceURI),
//             weight: weight,
//             essId: essID,
//             essTier: essTier,
//             earnedAt: block.timestamp
//         });

//         feats[featId] = feat;
//         featsMasterList.push(feat);
//         featsIdToEssID[featId] = essID;  
//     }

//     function awardAchievements(address userAddr, uint profileId) public {
//         _userFeatCheck(userAddr, profileId);
//     }

//     function _userFeatCheck(address userAddr, uint profileId) internal {
//         uint raceFeat = raceFeatCheck(userAddr);
//         uint stbFeat = stbFeatCheck(userAddr);
//         uint contribFeat = contribFeatCheck(userAddr);
//         uint followingFeat = followingFeatCheck(userAddr);
//         uint followerFeat = followerFeatCheck(userAddr);
//         uint subscriberFeat = subscriberFeatCheck(userAddr);
//         uint contentCreateFeat = contentFeatCheck(userAddr);
//         uint contentConsumeFeat = gigaBrainCheck(userAddr);

//         uint[] memory tmp = new uint[](8);
//         tmp[0] = raceFeat;
//         tmp[1] = stbFeat;
//         tmp[2] = contribFeat;
//         tmp[3] = followerFeat;
//         tmp[4] = followingFeat;
//         tmp[5] = subscriberFeat;
//         tmp[6] = contentCreateFeat;
//         tmp[7] = contentConsumeFeat;

//         for(uint256 i = 0; i < 8; i++) {
//             if(tmp[i] > 0) {
//                 userAwardFeats(i, tmp[i], userAddr, profileId);
//             }
//         }
//         delete tmp;
//     }

//     /**
//         * @dev adds a feat to User.feats unless the feat is already owned by the user
//         * @param featId the feat ID
//         * @param tier Tier of feat the User has earned; ex "low = 1, medium = 2, high = 3, T4 = 4"
//         * @param userAddr the user's address
//      */
//     function userAwardFeats(uint featId, uint tier, address userAddr, uint profileId) internal {
//         IGhostsData.Feat memory feat = feats[featId];
//         IGhostsData.UserFeats storage u = getUser[userAddr];

//         if(u.userAddress == address(0)){
//             IGhostsData.UserFeats memory newUser = IGhostsData.UserFeats({
//                 userAddress: userAddr,
//                 ccID: profileId,
//                 followCount: 0,
//                 followerCount: 0,
//                 commentCount: 0,
//                 consumeCount: 0,
//                 createCount: 0
//             });
//             getUser[userAddr] = newUser;
//             delete newUser;
//             return;
//         }else{

        
//         require(featId < featsMasterList.length, "featId out of range");


//         if(addrToFeatToTiers[userAddr][featId] >= tier) {
//             return;
//         }

//         uint256 profileId = ghostsCCID; // get users raceID

//         IGhostsData.Feat memory tmp = featsMasterList[featId];
//         tmp.earnedAt = block.timestamp;
//         tmp.essTier = uint16(tier);

//         addrToFeatToTiers[userAddr][featId] = tier;

//         earnedFeats[userAddr].push(tmp);

//         ccCollectEss(userAddr, profileId, feat.essId);
//     }
//     }

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
//     ) public returns (bool) {
//         getUser[userToFollow].followerCount += 1;
//         getUser[msg.sender].followCount += 1;

//         protocolActions[msg.sender][FOLLOWUSER] += 1;
//         userIdToFollowers[idToFollow].push(idFollowing);

//         userIdToFollowed[idFollowing].push(idToFollow);

//         emit NewFollow(idFollowing, idToFollow);
//         return true;
//     }

//     function unfollowUser(
//         uint idToUnfollow,
//         uint idUnfollowing,
//         address userToUnfollow
//     ) public returns (bool) {
//         getUser[userToUnfollow].followerCount -= 1;
//         getUser[msg.sender].followCount -= 1;

//         protocolActions[msg.sender][UNFOLLOWUSER] += 1;

//         delete userIdToFollowed[idUnfollowing][idToUnfollow];
//         delete userIdToFollowers[idToUnfollow][idUnfollowing];

//         emit Unfollowed(idUnfollowing, idToUnfollow);
//         return true;
//     }
    
//     function consumeContent(uint256 profileId, uint256 essID) public {
//         protocolActions[msg.sender][CONSUMECONTENT] += 1;
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
//         address essenceMw,
//         bool transferable,
//         bool deployAtReg,
//         bool allowComments
//          ) public {
//         ++postCount;
//         protocolActions[msg.sender][CREATECONTENT] += 1;
//         getUser[msg.sender].createCount += 1;
//         uint id = ccRegEssence(profileId, name, symbol, essenceURI, essenceMw, transferable, deployAtReg);
//         bytes[] memory emptyComments;
//         miniPost memory newPost = miniPost(msg.sender, profileId,id,allowComments, essenceURI,emptyComments);
//         userPosts[msg.sender].push(newPost);
//         posts[postCount] = newPost;
//         delete newPost;
//     }

//     function commentContent(
//         bytes calldata comment,
//         uint postId
//     ) public {
//         miniPost storage post = posts[postId];
//         if(post.allowComments){

//         protocolActions[msg.sender][COMMENTCONTENT] += 1;
//         getUser[msg.sender].commentCount += 1;
//         idToComment[postId].push(comment);
//         post.comments.push(comment);
//         }else{revert NoComments();}
//     }

//     function deleteComment(
//         uint postId,
//         address userAddr
//     ) public  {
//         if (userAddr == msg.sender) {
//             delete idToComment[postId];
//             getUser[msg.sender].commentCount -= 1;
//         }
//     }

//     /**
//         * @dev check User.raceID and returns feat level based on completion
//      */
//     function raceFeatCheck(address userAddr) internal returns (uint256) {
//         IGhostsData.User memory user = IGhosts(ghostsAddr).getGhostsProfile(userAddr);
//         uint256 currentRaceID = user.raceId;

//         if (currentRaceID >= 2) {
//             if (currentRaceID < 8) {
//                  delete user;
//                 return 1;
//             }
//         } else if (currentRaceID >= 8) {
//             if (currentRaceID < 15) {
//          delete user;
//                 return 2;
//             }
//         } else if (currentRaceID >= 15) {
//             if (currentRaceID < 22) {
//          delete user;
//                 return 3;
//             }
//         } else if (currentRaceID >= 22) {
//          delete user;
//             return 4;
//         } else {
//          delete user;
//             return 0;
//         }
//     }

//     /**
//         * @dev check User.spotTheBugs and returns feat level based on completion
//      */
//     function stbFeatCheck(address userAddr) internal returns (uint256) {
//         uint256 spotTheBugs = IGhosts(ghostsAddr).getGhostsProfile(userAddr).spotTheBugs; // get users spotTheBugs count
//         if (spotTheBugs >= 5) {
//             if (spotTheBugs < 20) {
//                 return 1;
//             }
//         } else if (spotTheBugs >= 20) {
//             if (spotTheBugs < 50) {
//                 return 2;
//             }
//         } else if (spotTheBugs >= 50) {
//             if (spotTheBugs < 100) {
//                 return 3;
//             }
//         } else if (spotTheBugs >= 100) {
//             return 4;
//         } else {
//             return 0;
//         }
//         return 0;
//     }

//     /**
//         * @dev check User.ctfStbContribs and returns feat level based on completion
//      */
//     function contribFeatCheck(address userAddr)
//         internal
//         returns (uint256)
//     {
//         uint256 contribCount = IGhosts(ghostsAddr).getGhostsProfile(userAddr).ctfStbContribs; // get users contribCount
//         if (contribCount >= 1) {
//             if (contribCount < 5) {
//                 return 1;
//             }
//         } else if (contribCount >= 5) {
//             if (contribCount < 15) {
//                 return 2;
//             }
//         } else if (contribCount >= 15) {
//             if (contribCount < 30) {
//                 return 3;
//             }
//         } else if (contribCount >= 30) {
//             return 4;
//         } else {
//             return 0;
//         }
//         return 0;
//     }

//     /**
//         * @dev checks protocolActions[userAddr][activityType] and returns feat level based on count
//      */
//     function followingFeatCheck(address userAddr) internal view returns (uint256) {
//         uint256 activityCount = protocolActions[userAddr][FOLLOWUSER]; // get users social activity count
//         if (activityCount >= 1) {
//             if (activityCount < 5) {
//                 return 1;
//             }
//         } else if (activityCount >= 5) {
//             if (activityCount < 15) {
//                 return 2;
//             }
//         } else if (activityCount >= 15) {
//             if (activityCount < 30) {
//                 return 3;
//             }
//         } else if (activityCount >= 30) {
//             return 4;
//         } else {
//             return 0;
//         }
//         return 0;
//     }

//     function followerFeatCheck(address userAddr) internal view returns (uint256) {

//         uint256 activityCount = getUser[userAddr].followerCount; // get users social activity count

//         if (activityCount >= 1) {
//             if (activityCount < 5) {
//                 return 1;
//                 }
//             } else if (activityCount >= 5) {
//                 if (activityCount < 15) {
//                     return 2;
//                 }
//             } else if (activityCount >= 15) {
//                 if (activityCount < 30) {
//                     return 3;
//                 }
//             } else if(activityCount >= 30) {
//                 return 4;
//             }else{
//                 return 0;
//             }
//         }

//     /**
//         * @dev checks getUser[userAddr].followCount and returns feat level based on count
//      */
//     function subscriberFeatCheck(address userAddr) internal returns (uint256) {
        
//         uint profileId = IGhosts(ghostsAddr).getGhostsProfile(userAddr).ccID;
//         address subNFT = ccProfileNFT.getSubscribeNFT(profileId);

//         if(subNFT != address(0)) {

//             uint subCount = ICyberNFTBase(subNFT).totalMinted();

//             if (subCount >= 1) {
//                 if (subCount < 5) {
//                     return 1;
//                 }
//             } else if (subCount >= 5) {
//                 if (subCount < 15) {
//                     return 2;
//                 }
//             } else if (subCount >= 15) {
//                 if (subCount < 30) {
//                     return 3;
//                 }
//             } else if (subCount >= 30) {
//                 return 4;
//             } else {
//                 return 0;
//             }
//             return 0;
//         }else{
//             return 0;}
//     }

//     /**
//         * @dev check User.contentPosts and returns feat level based on completion
//      */
//     function contentFeatCheck(address userAddr) internal view returns (uint256) {
//         uint256 contentCount = protocolActions[userAddr][CREATECONTENT]; // get users post count
//         if (contentCount >= 1) {
//             if (contentCount < 5) {
//                 return 1;
//             }
//         } else if (contentCount >= 5) {
//             if (contentCount < 15) {
//                 return 2;
//             }
//         } else if (contentCount >= 15) {
//             if (contentCount < 30) {
//                 return 3;
//             }
//         } else if (contentCount >= 30) {
//             return 4;
//         } else {
//             return 0;
//         }
//         return 0;
//     }

//     /**
//         * @dev checks getUser[userAddr].consumeContent and returns feat level based on count

//      */
//     function gigaBrainCheck(address userAddr) internal view returns (uint256) {
//         uint256 consumeCount = protocolActions[userAddr][CONSUMECONTENT]; // get users post count
//         if (consumeCount >= 1) {
//             if (consumeCount < 5) {
//                 return 1;
//             }
//         } else if (consumeCount >= 5) {
//             if (consumeCount < 15) {
//                 return 2;
//             }
//         } else if (consumeCount >= 15) {
//             if (consumeCount < 30) {
//                 return 3;
//             }
//         } else if (consumeCount >= 30) {
//             return 4;
//         } else {
//             return 0;
//         }
//         return 0;
//     }


//     /////////////////////////////////
//     ///                           ///
//     ///     Internal Functions    ///
//     ///                           ///
//     /////////////////////////////////
//     function ccGetMetadata(uint256 profileId)
//         public
//         view
//         returns (string memory)
//     {
//         return ccProfileNFT.getMetadata(profileId);
//     }

//     function ccGetAvatar(uint256 profileId)
//         public
//         view
//         returns (string memory)
//     {
//         return ccProfileNFT.getAvatar(profileId);
//     }

//     function ccGetSubNFTAddr(uint256 profileId)
//         public
//         view
//         returns (address)
//     {
//         return ccProfileNFT.getSubscribeNFT(profileId);
//     }

//     function ccGetSubURI(uint256 profileId)
//         public
//         view
//         returns (string memory)
//     {
//         return ccProfileNFT.getSubscribeNFTTokenURI(profileId);
//     }

//     function ccGetEssNFTAddr(uint256 profileId, uint256 essId)
//         public
//         view
//         returns (address)
//     {
//         return ccProfileNFT.getEssenceNFT(profileId, essId);
//     }

//     function ccGetEssURI(uint256 profileId, uint256 essId)
//         public
//         view
//         returns (string memory)
//     {
//         return ccProfileNFT.getEssenceNFTTokenURI(profileId, essId);
//     }

//     /**
//      * @dev sets the namespace owner of the ccProfileNFT to the provided address.
//      * @param addr of new namespace owner
//      */
//     function ccSetNSOwner(address addr) public {
//         ccProfileNFT.setNamespaceOwner(addr);
//     }

//     function ccRegEssence(
//         uint256 profileId,
//         string calldata name,
//         string calldata symbol,
//         string calldata essenceURI,
//         address essenceMw,
//         bool transferable,
//         bool deployAtReg
//     ) public returns (uint256) {
//         DataTypes.RegisterEssenceParams memory params;

//         params.profileId = profileId;
//         params.name = name;
//         params.symbol = symbol;
//         params.essenceTokenURI = essenceURI;
//         params.essenceMw = essenceMw;
//         params.transferable = transferable;
//         params.deployAtRegister = deployAtReg;

//         return _ccRegEssence(params);
//     }

//     function ccCollectEss(
//         address who,
//         uint256 profileId,
//         uint256 essenceId
//     ) public {
//         DataTypes.CollectParams memory params;
//         params.collector = who;
//         params.profileId = profileId;
//         params.essenceId = essenceId;

//         _ccCollectEss(params);
//     }

//     function ccSetMetadata(uint256 profileId, string calldata metadata)
//         public
//     {
//         _ccSetMetadata(profileId, metadata);
//     }

//     function ccSetSubData(
//         uint256 profileId,
//         string calldata uri,
//         address mw,
//         bytes calldata mwData
//     ) public {
//         _ccSetSubData(profileId, uri, mw, mwData);
//     }

//     function ccSetEssData(
//         uint256 profileId,
//         uint256 essId,
//         string calldata uri,
//         address mw,
//         bytes calldata mwData
//     ) public {
//         _ccSetEssData(profileId, essId, uri, mw, mwData);
//     }

//     function ccSetPrimary(uint256 profileId) public {
//         _ccSetPrimary(profileId);
//     }

//     function _ccRegEssence(DataTypes.RegisterEssenceParams memory params)
//         internal
//         returns (uint256)
//     {
//         uint id = ccProfileNFT.registerEssence(params, '');
//         return id; 
//     }

//     function _ccCollectEss(DataTypes.CollectParams memory params) internal {
//         ccProfileNFT.collect(params, "", "");
//     }

//     function _ccSetMetadata(uint256 profileId, string calldata metadata)
//         internal
//     {
//         ccProfileNFT.setMetadata(profileId, metadata);
//     }

//     function _ccSetSubData(
//         uint256 profileId,
//         string calldata uri,
//         address mw,
//         bytes calldata mwData
//     ) internal {
//         ccProfileNFT.setSubscribeData(profileId, uri, mw, mwData);
//     }

//     function _ccSetEssData(
//         uint256 profileId,
//         uint256 essId,
//         string calldata uri,
//         address mw,
//         bytes calldata mwData
//     ) internal {
//         ccProfileNFT.setEssenceData(profileId, essId, uri, mw, mwData);
//     }

//     function _ccSetPrimary(uint256 profileId) internal {
//         ccProfileNFT.setPrimaryProfile(profileId);
//     }

//      /**
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

//     function createGhostsCC(string memory handle, string[] memory hashes, address op) internal returns(uint) {        
//         DataTypes.CreateProfileParams memory params;
//         params.to = msg.sender;
//         params.handle = handle; 
//         params.avatar = hashes[0];
//         params.metadata = hashes[1];
//         params.operator = op;
//         ccProfileNFT.createProfile(params, '','');
//         uint ccID = ccProfileNFT.getProfileIdByHandle(handle);
//         ghostsCCID = ccID;
//         return ccID;
//     }

// }
