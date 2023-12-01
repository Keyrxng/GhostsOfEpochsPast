// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {DataTypes, IProfileNFT} from "../interfaces/IProfileNFT.sol";
import "forge-std/Test.sol";
interface ICyberNFTBase {
    function totalMinted() external returns (uint);
}
library GhostsLib {
    using DataTypes for *;
    bytes32 internal constant FOLLOWUSER    = keccak256("FollowUser");
    bytes32 internal constant UNFOLLOWUSER  = keccak256("UnfollowUser");
    bytes32 internal constant CONSUMECONTENT= keccak256("ConsumeContent");
    bytes32 internal constant CREATECONTENT = keccak256("CreateContent");
    bytes32 internal constant COMMENTCONTENT= keccak256("CreateContent");
    
    IProfileNFT internal constant ccProfileNFT =
        IProfileNFT(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271);

        
    // Packed to 2 slots
    struct ProtocolMeta {
        uint8 raceCount;
        uint8 collabCount;
        uint16 ghostsCCID;
        uint16 postCount;
        address deployer;
        uint32 tokenCount;
        uint32 userCount;
        string uri;
    }

    // Packed to 1 slot
    struct User {
        uint8 raceID; // the race they are currently on
        uint8 completedTasks; // completed tasks
        uint8 spotTheBugs; // completed spot the bugs tasks
        uint8 ctfStbContribs; // CTF or STB contributions made
        bool racing; // true/false
        bool collabing; // true/false
        uint8 collabID; // the collab they are currently on
        uint8 curRaceID; // current race id
        uint8 curColID;
        uint8 contentPosts; // content posted
        uint32 performance; // a percentage based on previous task performance
        uint32 ccID; // their CC id
        uint32 ghostsID; // their Ghosts id
    }

    // Packed to 3 slots
    struct RaceNFT {
        bytes32 submittedAnswers; // submitted answers by the user      
        bytes32 answer;
        address userAddress;
        uint32 tokenID;
        uint8 raceID;
        bool completed;
    }

    // Packed to 4 slots
    struct CollabNFT {
        bytes32 author;
        bytes32 title;
        bytes32[] answers;
        address userAddress;
        uint32 tokenID;
        uint8 collabID;
        bool completed;
    }

    // Packed to 4 slots
    struct Feat {
        bytes32 name; // feat name (~ 40 words | ~ 250 chars)
        bytes32 desc; // description of feat (~ 40 words | ~ 250 chars)
        bytes32 imageUrl; // imgUrl of image of feat (hash)
        uint64 weight; // low = 10, med = 50, high = 100
        uint64 essID; // Essence NFT ID
        uint64 essTier; // Essence Index of Tier
        uint160 earnedAt; // earned at timestamp
    }

    // Packed to 2 slots
    struct UserFeats {
        address userAddress; // user address
        uint32 ccID; // CyberConnect ID
        uint32 ghostsID; // Ghosts ID
        uint16 followCount; // number of users following this user
        uint16 followerCount; // number of users this user is following
        uint16 commentCount; // number of comments this user has made
        uint16 consumeCount; // number of pieces of content consumed
        uint16 createCount; // number of pieces of content created
        uint16 postCount; // number of community posts
        uint16[][4] featsEarned; // 2
        uint16[] postIds; //2
        uint16[] followers; //2 
        uint16[] following; //2 
    }

    // Packed to 2 slots
    struct MiniPost{
        bytes32 uri;
        address creator;
        uint32 creatorCCID;
        uint16 postId;
        uint16 likes;
        uint16 dislikes;
        uint16 allowComments;
        bytes[] comments;
    }

    error NoComments();
    error AlreadyFollowed(address userAddress);
    error NotAuthed();
    error Incorrect();
    error AccountExists(address who, uint ccID);
    error AlreadySubmitted(uint raceID);
    error FinishFirst(uint taskId);
    error Soulbound();
    error NoSuccess();
    error OutOfRange();
    error NoExists(uint id);
    error NoAccount();
    error AlreadyAwarded();
    error NotYetStarted();

    event NewFollow(uint indexed follower, uint indexed followed);
    event Unfollowed(uint indexed follower, uint indexed followed);
    event RaceCreated(uint indexed id);
    event UserCreated(address indexed who, uint indexed ccID);
    event RaceCompleted(address indexed who, uint indexed raceID, uint indexed ccID);
    event RaceStarted(address indexed who, uint indexed raceID, uint indexed ccID);
    event CollabStarted(address indexed user, uint indexed currentCollab);
    
    function getUserProfileWID(mapping(uint=> User) storage allUser, uint id) external view returns(User memory){
        return allUser[id];
    }

    function getUserProfileWA(mapping(address=> User) storage addrToUser, address id) external view returns(User memory){
        return addrToUser[id];
    }

    function getUserFeatsWID(mapping(uint=> UserFeats) storage getUser, uint id) external view returns(UserFeats memory){
        return getUser[id];
    }

    function getCommentWID(mapping(uint=> bytes[]) storage idToComment, uint id) external view returns(bytes[] memory){
        return idToComment[id];
    }

    function getCollabNFTWID(mapping(uint=> uint) storage collabNFTs, uint id) external view returns(uint){
        return collabNFTs[id];
    }

    function getFinalRaceNFTWID(mapping(uint=> uint) storage finalRaceNFTs, uint id) external view returns(uint){
        return finalRaceNFTs[id];
    }

    function getTokTypeWID(mapping(uint=> mapping(uint => uint)) storage tokIdToType, uint tokenId, uint raceId) external view returns(uint){
        return tokIdToType[tokenId][raceId];
    }

    function getProtoMeta(ProtocolMeta[] storage protocolMeta) external view returns(ProtocolMeta memory){
        return protocolMeta[0];
    }

    function getAllRaceNFT(RaceNFT[] storage allRaceNFTs) external pure returns(RaceNFT[] memory){
        return allRaceNFTs;
    }

    function getAllCollabNFTs(CollabNFT[] storage allCollabNFTs) external pure returns(CollabNFT[] memory){
        return allCollabNFTs;
    }

    function getAllUsers(User[] storage allUsers) external pure returns(User[] memory){
        return allUsers;
    }

    function getAllPosts(MiniPost[] storage allPosts) external pure returns(MiniPost[] memory){
        return allPosts;
    }

    function getAllFeats(Feat[] storage allFeats) external pure returns(Feat[] memory){
        return allFeats;
    }

    function getAllUserFeats(UserFeats[] storage allUserFeats) external pure returns(UserFeats[] memory){
        return allUserFeats;
    }

    function awardFeats(
        mapping(address => User) storage addrToUser,
        mapping(uint => UserFeats) storage allUser,
        mapping(address => mapping(bytes32=>uint)) storage protoActions,
        address who
    ) external returns (uint16[] memory tmp){
        User storage user = addrToUser[who];
        uint id = user.ghostsID;

        UserFeats storage feats = allUser[id];

        uint16 raceFeat = raceFeatCheck(user);
        uint16 stbFeat = stbFeatCheck(user);
        uint16 contribFeat = contribFeatCheck(user);
        uint16 followingFeat = followingFeatCheck(protoActions, who);
        uint16 followerFeat = followerFeatCheck(user, allUser[id]);
        uint16 subscriberFeat = subscriberFeatCheck(user);
        uint16 contentCreateFeat = contentFeatCheck(protoActions, who);
        uint16 contentConsumeFeat = gigaBrainCheck(protoActions, who);

        tmp = new uint16[](8);
        tmp[0] = raceFeat;
        tmp[1] = stbFeat;
        tmp[2] = contribFeat;
        tmp[3] = followerFeat;
        tmp[4] = followingFeat;
        tmp[5] = subscriberFeat;
        tmp[6] = contentCreateFeat;
        tmp[7] = contentConsumeFeat;
    }

    function createUser(
        mapping(address => User) storage addrToUser,
        mapping(uint=>UserFeats) storage getUser,
        UserFeats[] storage allUserFeats,
        string memory handle, string[] memory hashes,
        uint32 userCount
        ) external returns (uint) {
        User memory user = addrToUser[msg.sender];
        DataTypes.CreateProfileParams memory params;
        params.to = msg.sender;
        params.handle = handle; 
        params.avatar = hashes[0];
        params.metadata = hashes[1];
        params.operator = address(this);

        ccProfileNFT.createProfile(params, '','');
        uint256 ccID = ccProfileNFT.getProfileIdByHandle(handle);
        delete params;

        if(user.ghostsID == 0){
           { User memory newUser;
                newUser.raceID = 1;
                newUser.ccID = uint32(ccID);
                newUser.ghostsID = userCount;
            createUserFeats(getUser, allUserFeats, uint32(ccID), userCount);
            addrToUser[msg.sender] = newUser;
            emit UserCreated(msg.sender, ccID);
            delete newUser;}
            return ccID;
        }else{
            revert AccountExists(msg.sender, ccID);
        }
    }

     function createUserFeats(
        mapping(uint=>UserFeats) storage getUser,
        UserFeats[] storage allUserFeats,
        uint32 ccID, uint32 ghostsID) public {
        uint16[] memory empty;
        uint16[][4] memory tierArray;
        UserFeats memory user = UserFeats({
            userAddress: address(msg.sender),
            ccID: ccID,
            ghostsID: ghostsID,
            followCount: 0,
            followerCount: 0,
            commentCount: 0,
            consumeCount: 0,
            createCount: 0,
            postCount: 0,
            postIds: empty,
            followers: empty,
            following: empty,
            featsEarned: tierArray

        });
        UserFeats memory fuser;
        allUserFeats.length == 0 ? getUser[0] = fuser : getUser[ghostsID] = user;
        allUserFeats.length == 0 ? allUserFeats.push(fuser) : allUserFeats.push(user);
        
    }

    function startNextRace(
        mapping(address => User) storage addrToUser,
        mapping(uint=>mapping(uint => uint)) storage tokIdToType,
        RaceNFT[] storage allRaceNFTs,
        mapping(uint=>uint) storage finalRaceNFTs,
        uint32 tokenCount
        ) external returns(bool) {
        User storage user = addrToUser[msg.sender];

        if(user.racing){
            revert FinishFirst(user.raceID);
        }
        uint8 raceID = user.curRaceID == 0 ? 1 : user.raceID;

        uint idd = finalRaceNFTs[raceID];

        RaceNFT memory newNft;
        newNft.tokenID = tokenCount;
        newNft.raceID = raceID;
        user.curRaceID = raceID;
        user.racing = true;
        addrToUser[msg.sender] = user;
        tokIdToType[tokenCount][1] = raceID;
        allRaceNFTs.push(newNft);
        return true;
    }

    function submitRace(
        mapping(address => User) storage addrToUser,
        RaceNFT[] storage allRaceNFTs,
        mapping(uint=>uint) storage finalRaceNFTs,
        bytes32 answers,
        uint32 raceCount,
        uint32 collabCount
        ) external returns(bool) {
        User storage user = addrToUser[msg.sender];
        if(!user.racing) {
            revert AlreadySubmitted(user.raceID);
        }

        uint idd = finalRaceNFTs[user.raceID];
        RaceNFT storage nftMetaData = allRaceNFTs[idd];

        if(nftMetaData.answer != answers) {
            revert Incorrect();
        }else{
            user.completedTasks +=1;
            user.curRaceID = user.raceID;
            user.raceID +=1;
            user.racing = false;
            user.performance = (user.performance + 100) / (raceCount + collabCount);

            addrToUser[msg.sender] = user;
            nftMetaData.submittedAnswers = answers;
            nftMetaData.completed = true;
            return true;
        }
    }

    function startNextCollab(
        mapping(address => User) storage addrToUser,
        mapping(uint=>mapping(uint => uint)) storage tokIdToType,
        CollabNFT[] storage allCollabNFTs,
        uint8 collabID,
        uint32 tokenCount
        ) external returns (bool) {
        User storage user = addrToUser[msg.sender];
        CollabNFT memory newNft = allCollabNFTs[collabID];
        if(user.collabing){
            revert FinishFirst(user.collabID);
        }

        newNft.userAddress = msg.sender;
        newNft.tokenID = tokenCount;
        {user.curColID = newNft.collabID;
        user.collabing = true;
        user.collabID = collabID;
        user.spotTheBugs = user.spotTheBugs + 1;
        user.completedTasks = user.completedTasks + 1;
        addrToUser[msg.sender] = user;}
        tokIdToType[tokenCount][2] = collabID;
        // safeMint(msg.sender);
        return true;
    }

    function submitCollab(
        mapping(address => User) storage addrToUser,
        CollabNFT[] storage allCollabNFTs,
        bytes32[] memory guesses,
        uint32 collabCount,
        uint32 raceCount,
        uint32 collabID
        ) external returns (bool) {
        User storage user = addrToUser[msg.sender];
        CollabNFT memory collab = allCollabNFTs[collabID];

        if(!user.collabing){
            revert AlreadySubmitted(user.collabID);
        }

        uint len = guesses.length;
        bytes32[] memory answers = new bytes32[](len);
        unchecked {
            for(uint x = 0; x < len; ++x){
                bytes32 guess = guesses[x];
                answers[x] = keccak256(abi.encodePacked(guess));
            }
        }

        if(keccak256(abi.encodePacked(collab.answers)) == keccak256(abi.encodePacked(answers))){
            revert Incorrect();
        }else {
            user.spotTheBugs = user.spotTheBugs + 1;
            user.completedTasks = user.completedTasks + 1;
            user.collabing = false;
            user.performance = (user.performance + 100) / (raceCount + collabCount);
            addrToUser[msg.sender] = user;

            collab.completed = true;

            return true;
        }
    }
    
    function onlyGhosts(address sender, address owner) external view returns (bool) {
        if(msg.sender == owner){
            return true;
        }else if(msg.sender == sender){
            return true;    
        }else{
            revert NotAuthed();
        }
    }
    
    function raceFeatCheck(User storage user) internal view returns (uint8 tier) {
        uint256 currentRaceID = user.raceID;

        if(currentRaceID >= 22){
            tier = 4; 
        }else if(currentRaceID >= 15){
            tier = 3;
        }else if(currentRaceID >= 8){
            tier = 2;
        }else if(currentRaceID >= 2){
            tier = 1;
        }else{
            tier = 0;
        }
    }

    /**
        * @dev check User.spotTheBugs and returns feat level based on completion
     */
    function stbFeatCheck(User storage user) internal view returns (uint8 tier) {
        uint256 spotTheBugs = user.spotTheBugs;

        if(spotTheBugs >= 100){
            tier = 4; 
        }else if(spotTheBugs >= 50){
            tier = 3;
        }else if(spotTheBugs >= 20){
            tier = 2;
        }else if(spotTheBugs >= 100){
            tier = 1;
        }else{
            tier = 0;
        }
    }

    /**
        * @dev check User.ctfStbContribs and returns feat level based on completion
     */
    function contribFeatCheck(User storage user)
        internal
        view
        returns (uint8 tier)
    {
        uint256 contribCount = user.ctfStbContribs;

        if(contribCount >= 30){
            tier = 4; 
        }else if(contribCount >= 15){
            tier = 3;
        }else if(contribCount >= 5){
            tier = 2;
        }else if(contribCount >= 1){
            tier = 1;
        }else{
            tier = 0;
        }
    }

    /**
        * @dev checks protocolActions[userAddr][activityType] and returns feat level based on count
     */
    function followingFeatCheck(
            mapping(address => mapping(bytes32=>uint)) storage protoActions,
            address userAddr
        ) internal view returns (uint8 tier) {
        uint256 activityCount = protoActions[userAddr][FOLLOWUSER]; // get users social activity count

        if(activityCount >= 30){
            tier = 4; 
        }else if(activityCount >= 15){
            tier = 3;
        }else if(activityCount >= 5){
            tier = 2;
        }else if(activityCount >= 1){
            tier = 1;
        }else{
            tier = 0;
        }
    }

    function followerFeatCheck(User storage user, UserFeats storage u) internal view returns (uint8 tier) {
        uint32 id = user.ccID;
        uint256 activityCount = u.followers.length;

        if(activityCount >= 30){
            tier = 4; 
        }else if(activityCount >= 15){
            tier = 3;
        }else if(activityCount >= 5){
            tier = 2;
        }else if(activityCount >= 1){
            tier = 1;
        }else{
            tier = 0;
        }
    }

    /**
        * @dev checks getUser[userAddr].followCount and returns feat level based on count
     */
    function subscriberFeatCheck(User storage user) internal returns (uint8 tier) {
        
        uint profileID = user.ccID;
        address subNFT = ccProfileNFT.getSubscribeNFT(profileID);

        if(subNFT != address(0)) {

            uint subCount = ICyberNFTBase(subNFT).totalMinted();

            if(subCount >= 30){
                tier = 4; 
            }else if(subCount >= 15){
                tier = 3;
            }else if(subCount >= 5){
                tier = 2;
            }else if(subCount >= 1){
                tier = 1;
            }else{
                tier = 0;
            }
        }
    }

    /**
        * @dev check User.contentPosts and returns feat level based on completion
     */
    function contentFeatCheck(
        mapping(address => mapping(bytes32=>uint)) storage protoActions,
            address userAddr
    ) internal view returns (uint8 tier) {
        uint256 contentCount = protoActions[userAddr][CREATECONTENT]; // get users post count

        if(contentCount >= 30){
            tier = 4; 
        }else if(contentCount >= 15){
            tier = 3;
        }else if(contentCount >= 5){
            tier = 2;
        }else if(contentCount >= 1){
            tier = 1;
        }else{
            tier = 0;
        }
    }

    /**
        * @dev checks getUser[userAddr].consumeContent and returns feat level based on count

     */
    function gigaBrainCheck(
        mapping(address => mapping(bytes32=>uint)) storage protoActions,
            address userAddr
    ) internal view returns (uint8 tier) {
        uint256 consumeCount = protoActions[userAddr][CONSUMECONTENT]; // get users post count

        if(consumeCount >= 30){
            tier = 4; 
        }else if(consumeCount >= 15){
            tier = 3;
        }else if(consumeCount >= 5){
            tier = 2;
        }else if(consumeCount >= 1){
            tier = 1;
        }else{
            tier = 0;
        }
    }
    
}