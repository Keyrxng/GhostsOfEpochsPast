// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {GhostsHub} from "./GhostsHub.sol";
import {DataTypes} from "./interfaces/IProfileNFT.sol";
import {IGhosts} from "./interfaces/IGhosts.sol";
import {Ownable} from  "@openzeppelin/access/Ownable.sol";

contract GhostsFeats is GhostsHub, Ownable {
    string internal tokenBaseURI;
    bytes32 internal constant FOLLOWUSER = keccak256("FollowUser");
    bytes32 internal constant CONSUMECONTENT = keccak256("ConsumeContent");

    address internal GhostsAddr;

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

    struct User {
        uint256 ccID; // CyberConnect ID
        uint256 ghostsID; // Ghosts User ID
        uint followCount; // number of users following this user
        uint consumeCount; // number of pieces of content consumed
        Feat[] feats; // list of owned feats
    }

    Feat[] public featsMasterList; // list of feats
    mapping(bytes => ProtocolFeats) public featsMasterListMap; // feat name => featID reference
    mapping(uint256 => Feat) public feats; // feat ID => feat data
    mapping(address => User) public getUser; // stores the list of feats for each user
    mapping(address => mapping(uint=>uint)) public addrToFeatToTiers; // user > featId > tier
    mapping(address => mapping(bytes32=>uint)) internal protocolActions; // allow protocol data to be stored in mapping
    mapping(uint => uint) internal featsIdToEssID; // mapping featID => essID
    event NewFollow(address indexed follower, address indexed followed);

    constructor(address ghostsAddr) {
        GhostsAddr = ghostsAddr;
    }

    /**
        * @dev Creates the Essence NFT representing each achievement
        * @param ccID - ccID (I'm best guessing we use the Ghosts CC Profile here)
        * @param name - essence name (the feat name?)
        * @param symbol - essence symbol
        * @param essenceURI - essence URI
        * @param essenceMw - essence middleware contract (Permissioned?) 
     */
    function createAchievements(
        uint256 ccID,
        string calldata name,
        string calldata symbol,
        string calldata essenceURI,
        address essenceMw,
        string calldata description,
        uint weight,
        uint16 essTier

        ) external onlyOwner {
        uint essID = ccRegEssence(ccID, name, symbol, essenceURI, essenceMw, false, true);


        uint256 featID = featsMasterList.length;
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

    function awardAchievements(address userAddr) external {
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
        User memory u = getUser[userAddr];

        if(addrToFeatToTiers[userAddr][featId] >= tier) {
            return;
        }

        uint256 profileId = IGhosts(GhostsAddr).getUser(userAddr).ccID; // get users raceID

        Feat memory tmp = featsMasterList[featId];
        tmp.earnedAt = block.timestamp;
        tmp.essTier = uint16(tier);

        addrToFeatToTiers[userAddr][featId] = tier;

        getUser[userAddr].feats.push(tmp);

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
    ) external returns (bool) {
        getUser[_followed].followCount += 1;
        protocolActions[userAddr][FOLLOWUSER] += 1;
        uint256 ccID = IGhosts(GhostsAddr).getUser(_followed).ccID; // get users raceID
        uint256[] memory profileIDs = new uint[](1);
        profileIDs[0] = ccID;
        _ccSubscribe(profileIDs, userAddr);
        emit NewFollow(userAddr, _followed);
        return true;
    }

    function consumeContent(address userAddr, uint256 profileId, uint256 essID) external {
        protocolActions[userAddr][CONSUMECONTENT] += 1;
        getUser[userAddr].consumeCount += 1;
        ccCollectEss(userAddr, profileId, essID);
    }

    /**
        * @dev check Ghosts.User.raceID and returns feat level based on completion
     */
    function raceFeatCheck(address userAddr) internal returns (uint256) {
        uint256 currentRaceID = IGhosts(GhostsAddr).getUser(userAddr).raceId; // get users raceID
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
    }

    /**
        * @dev check Ghosts.User.spotTheBugs and returns feat level based on completion
     */
    function stbFeatCheck(address userAddr) internal returns (uint256) {
        uint256 spotTheBugs = IGhosts(GhostsAddr).getUser(userAddr).spotTheBugs; // get users spotTheBugs count
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
    }

    /**
        * @dev check Ghosts.User.ctfStbContribs and returns feat level based on completion
     */
    function contribFeatCheck(address userAddr)
        internal
        returns (uint256)
    {
        uint256 contribCount = IGhosts(GhostsAddr).getUser(userAddr).ctfStbContribs; // get users contribCount
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
    }

    /**
        * @dev check Ghosts.User.contentPosts and returns feat level based on completion
     */
    function contentFeatCheck(address userAddr) internal returns (uint256) {
        uint256 contentCount = IGhosts(GhostsAddr).getUser(userAddr).contentPosts; // get users post count
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
    }


    /////////////////////////////////
    ///                           ///
    ///     Internal Functions    ///
    ///                           ///
    /////////////////////////////////



}
