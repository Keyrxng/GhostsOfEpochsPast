// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {DataTypes, IProfileNFT} from "./interfaces/IProfileNFT.sol";
import {IGhosts} from "./interfaces/IGhosts.sol";
import {Ownable} from  "@openzeppelin/access/Ownable.sol";
import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";

contract GhostsFeats  {
    bytes32 internal constant FOLLOWUSER = keccak256("FollowUser");
    bytes32 internal constant CONSUMECONTENT = keccak256("ConsumeContent");
    bytes32 internal constant CREATECONTENT = keccak256("CreateContent");
    address internal ghostsAddr;
    IProfileNFT internal constant ccProfileNFT =
        IProfileNFT(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271);
    
    struct Feat {
        bytes name; // feat name
        bytes desc; // description of feat
        bytes imageUrl; // imgUrl of image of feat
        uint256 weight; // low = 10, med = 50, high = 100
        uint256 essId; // Essence NFT ID
        uint16 essTier; // Essence Index of Tier
        uint earnedAt; // earned at timestamp
    }

    struct ProtocolFeats {
        uint256 featID; // feat ID - mapped to featsMasterList
    }

    struct UserFeats {
        uint256 ccID; // CyberConnect ID
        uint256 ghostsID; // Ghosts User ID
        uint followCount; // number of users following this user
        uint consumeCount; // number of pieces of content consumed
        uint createCount; // number of pieces of content created
        Feat[] feats; // list of owned feats
    }

    Feat[] public featsMasterList; // list of feats
    mapping(bytes => ProtocolFeats) public featsMasterListMap; // feat name => featID reference
    mapping(uint256 => Feat) public feats; // feat ID => feat data
    mapping(address => UserFeats) public getUser; // stores the list of feats for each user
    mapping(address => mapping(uint=>uint)) public addrToFeatToTiers; // user > featId > tier
    mapping(address => mapping(bytes32=>uint)) internal protocolActions; // allow protocol data to be stored in mapping
    mapping(uint => uint) internal featsIdToEssID; // mapping featID => essID
    event NewFollow(address indexed follower, address indexed followed);

    /**
        * @dev Creates the Essence NFT representing each achievement
        * @param ccID - ccID (I'm best guessing we use the Ghosts CC Profile here)
        * @param name - essence name (the feat name?)
        * @param symbol - essence symbol
        * @param essenceURI - essence URI
     */
    function createAchievements(
        uint256 ccID,
        string calldata name,
        string calldata symbol,
        string calldata essenceURI,
        address /*essenceMw*/,
        string calldata description,
        uint weight,
        uint16 essTier
        ) public {
        uint essID = ccRegEssence(ccID, name, symbol, essenceURI, address(0), true, true);

        uint256 featID = featsMasterList.length + 1;

        Feat memory feat = Feat({
            name: bytes(name),
            desc: bytes(description),
            imageUrl: bytes(essenceURI),
            weight: weight,
            essId: essID,
            essTier: essTier,
            earnedAt: 0
        });

        feats[featID] = feat;
        featsMasterList.push(feat);
        featsIdToEssID[featID] = essID;     
    }

    function awardAchievements(address userAddr) public {
        _userFeatCheck(userAddr);
    }

    function _userFeatCheck(address userAddr) internal {
        uint raceFeat = raceFeatCheck(userAddr);
        uint stbFeat = stbFeatCheck(userAddr);
        uint contribFeat = contribFeatCheck(userAddr);
        uint followingFeat = followingFeatCheck(userAddr);
        uint fololwedFeat = followerFeatCheck(userAddr);
        uint contentCreateFeat = contentFeatCheck(userAddr);
        uint contentConsumeFeat = gigaBrainCheck(userAddr);

        uint[] memory tmp = new uint[](7);
        tmp[0] = raceFeat;
        tmp[1] = stbFeat;
        tmp[2] = contribFeat;
        tmp[3] = followingFeat;
        tmp[4] = fololwedFeat;
        tmp[5] = contentCreateFeat;
        tmp[6] = contentConsumeFeat;

        for(uint256 i = 0; i < 7; i++) {
            if(tmp[i] > 0) {
                userAwardFeats(i, tmp[i], userAddr);
            }
        }
    }

    /**
        * @dev adds a feat to User.feats unless the feat is already owned by the user
        * @param featId the feat ID
        * @param tier Tier of feat the User has earned; ex "low = 1, medium = 2, high = 3, T4 = 4"
        * @param userAddr the user's address
     */
    function userAwardFeats(uint featId, uint tier, address userAddr) internal {
        require(featId < featsMasterList.length, "featId out of range");
        Feat memory feat = feats[featId];
        UserFeats storage u = getUser[userAddr];

        if(addrToFeatToTiers[userAddr][featId] >= tier) {
            return;
        }

        uint256 profileId = IGhosts(ghostsAddr).getGhostsProfile(userAddr).ccID; // get users raceID

        Feat memory tmp = featsMasterList[featId];
        tmp.earnedAt = block.timestamp;
        tmp.essTier = uint16(tier);

        addrToFeatToTiers[userAddr][featId] = tier;

        u.feats.push(tmp);

        ccCollectEss(userAddr, profileId, feat.essId);
    }
     /**
        * @dev Stores the action to the user addr then subscribes to the CC profile
        * @param userAddr the address of the user
        * @param _followed the address of the user being followed
     */
    function followUser(
        address userAddr,
        address _followed
    ) public returns (bool) {
        getUser[_followed].followCount += 1;
        protocolActions[userAddr][FOLLOWUSER] += 1;
        uint256 ccID = IGhosts(ghostsAddr).getGhostsProfile(_followed).ccID; // get users raceID
        uint256[] memory profileIDs = new uint[](1);
        profileIDs[0] = ccID;
        ccSubscribe(profileIDs);
        emit NewFollow(userAddr, _followed);
        return true;
    }

    function consumeContent(address userAddr, uint256 profileId, uint256 essID) public {
        protocolActions[userAddr][CONSUMECONTENT] += 1;
        getUser[userAddr].consumeCount += 1;
        ccCollectEss(userAddr, profileId, essID);
    }

    /**
        * @dev Create Content for protocol uses this function to perform the following:
        * 1. update protocolAction[] stores the amount of calls to this function
        * 2. update User.createCount, increment by 1
        * 3. call function ccRegEssence() to register the essence with the profile
     */
    function createContent(
        address userAddr,
        uint256 profileId,
        string calldata name,
        string calldata symbol,
        string calldata essenceURI,
        address essenceMw,
        bool transferable,
        bool deployAtReg
         ) public {
        protocolActions[userAddr][CREATECONTENT] += 1;
        getUser[userAddr].createCount += 1;
        ccRegEssence(profileId, name, symbol, essenceURI, essenceMw, transferable, deployAtReg);
    }

    /**
        * @dev check User.raceID and returns feat level based on completion
     */
    function raceFeatCheck(address userAddr) internal returns (uint256) {
        uint256 currentRaceID = IGhosts(ghostsAddr).getGhostsProfile(userAddr).raceId; // get users raceID
        if (currentRaceID >= 2) {
            if (currentRaceID < 8) {
                return 1;
            }
        } else if (currentRaceID >= 8) {
            if (currentRaceID < 15) {
                return 2;
            }
        } else if (currentRaceID >= 15) {
            if (currentRaceID < 22) {
                return 3;
            }
        } else if (currentRaceID >= 22) {
            return 4;
        } else {
            return 0;
        }
         return 0;
    }

    /**
        * @dev check User.spotTheBugs and returns feat level based on completion
     */
    function stbFeatCheck(address userAddr) internal returns (uint256) {
        uint256 spotTheBugs = IGhosts(ghostsAddr).getGhostsProfile(userAddr).spotTheBugs; // get users spotTheBugs count
        if (spotTheBugs >= 5) {
            if (spotTheBugs < 20) {
                return 1;
            }
        } else if (spotTheBugs >= 20) {
            if (spotTheBugs < 50) {
                return 2;
            }
        } else if (spotTheBugs >= 50) {
            if (spotTheBugs < 100) {
                return 3;
            }
        } else if (spotTheBugs >= 100) {
            return 4;
        } else {
            return 0;
        }
        return 0;
    }

    /**
        * @dev check User.ctfStbContribs and returns feat level based on completion
     */
    function contribFeatCheck(address userAddr)
        internal
        returns (uint256)
    {
        uint256 contribCount = IGhosts(ghostsAddr).getGhostsProfile(userAddr).ctfStbContribs; // get users contribCount
        if (contribCount >= 1) {
            if (contribCount < 5) {
                return 1;
            }
        } else if (contribCount >= 5) {
            if (contribCount < 15) {
                return 2;
            }
        } else if (contribCount >= 15) {
            if (contribCount < 30) {
                return 3;
            }
        } else if (contribCount >= 30) {
            return 4;
        } else {
            return 0;
        }
        return 0;
    }

    /**
        * @dev checks protocolActions[userAddr][activityType] and returns feat level based on count
     */
    function followingFeatCheck(address userAddr) internal view returns (uint256) {
        uint256 activityCount = protocolActions[userAddr][FOLLOWUSER]; // get users social activity count
        if (activityCount >= 1) {
            if (activityCount < 5) {
                return 1;
            }
        } else if (activityCount >= 5) {
            if (activityCount < 15) {
                return 2;
            }
        } else if (activityCount >= 15) {
            if (activityCount < 30) {
                return 3;
            }
        } else if (activityCount >= 30) {
            return 4;
        } else {
            return 0;
        }
        return 0;
    }

    /**
        * @dev checks getUser[userAddr].followCount and returns feat level based on count
     */
    function followerFeatCheck(address userAddr) internal view returns (uint256) {
        uint followCount = getUser[userAddr].followCount; // get users social activity count
        if (followCount >= 1) {
            if (followCount < 5) {
                return 1;
            }
        } else if (followCount >= 5) {
            if (followCount < 15) {
                return 2;
            }
        } else if (followCount >= 15) {
            if (followCount < 30) {
                return 3;
            }
        } else if (followCount >= 30) {
            return 4;
        } else {
            return 0;
        }
        return 0;
    }

    /**
        * @dev check User.contentPosts and returns feat level based on completion
     */
    function contentFeatCheck(address userAddr) internal returns (uint256) {
        uint256 contentCount = IGhosts(ghostsAddr).getGhostsProfile(userAddr).contentPosts; // get users post count
        if (contentCount >= 1) {
            if (contentCount < 5) {
                return 1;
            }
        } else if (contentCount >= 5) {
            if (contentCount < 15) {
                return 2;
            }
        } else if (contentCount >= 15) {
            if (contentCount < 30) {
                return 3;
            }
        } else if (contentCount >= 30) {
            return 4;
        } else {
            return 0;
        }
        return 0;
    }

    /**
        * @dev checks getUser[userAddr].consumeContent and returns feat level based on count

     */
    function gigaBrainCheck(address userAddr) internal view returns (uint256) {
        uint256 consumeCount = protocolActions[userAddr][CONSUMECONTENT]; // get users post count
        if (consumeCount >= 1) {
            if (consumeCount < 5) {
                return 1;
            }
        } else if (consumeCount >= 5) {
            if (consumeCount < 15) {
                return 2;
            }
        } else if (consumeCount >= 15) {
            if (consumeCount < 30) {
                return 3;
            }
        } else if (consumeCount >= 30) {
            return 4;
        } else {
            return 0;
        }
        return 0;
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

    function ccSubscribe(uint256[] memory profileIDs) public {
        _ccSubscribe(profileIDs, msg.sender);
    }

    /**
     * @dev sets the namespace owner of the ccProfileNFT to the provided address.
     * @param addr of new namespace owner
     */
    function ccSetNSOwner(address addr) public {
        ccProfileNFT.setNamespaceOwner(addr);
    }

    function ccRegEssence(
        uint256 profileId,
        string calldata name,
        string calldata symbol,
        string calldata essenceURI,
        address essenceMw,
        bool transferable,
        bool deployAtReg
    ) public returns (uint256) {
        DataTypes.RegisterEssenceParams memory params;

        params.profileId = profileId;
        params.name = name;
        params.symbol = symbol;
        params.essenceTokenURI = essenceURI;
        params.essenceMw = essenceMw;
        params.transferable = transferable;
        params.deployAtRegister = deployAtReg;

        return _ccRegEssence(params);
    }

    function ccCollectEss(
        address who,
        uint256 profileId,
        uint256 essenceId
    ) public {
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

    function _ccSubscribe(uint256[] memory profileIDs, address who) internal {
        DataTypes.SubscribeParams memory params;
        params.subscriber = who;
        params.profileIds = profileIDs;
        bytes[] memory initData;

        ccProfileNFT.subscribe(params, initData, initData);
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

        return IERC721(essNFTAddr).balanceOf(me) > 0;
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
        return IERC721(subNFTAddr).balanceOf(me) > 0;
    }

}
