// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {GhostsHub} from "./GhostsHub.sol";
import {DataTypes} from "./IProfileNFT.sol";
import {IGhosts} from "./IGhosts.sol";
import {Ownable} from  "@openzeppelin/access/Ownable.sol";

contract GhostsFeats is GhostsHub, Ownable {
    string internal tokenBaseURI;
    bytes32 internal constant FOLLOWUSER = keccak256("FollowUser");

    address internal GhostsAddr;

    struct Feat {
        bytes name; // feat name
        bytes desc; // description of feat
        bytes imageUrl; // imgUrl of image of feat
        uint256 weight; // low = 10, med = 50, high = 100
    }

    struct ProtocolFeats {
        uint256 featID; // feat ID - mapped to featsMasterList
    }

    struct UserFeat {
        bytes name; // feat name
        bytes description; // feat desc
        uint256 earnedTime; // when did they earn it?
        uint256 weight; // low = 10, med = 50, high = 100
        uint256 tokenID; // nft tokenID
    }

    struct User {
        uint256 ccID; // CyberConnect ID
        uint256 ghostsID; // Ghosts User ID
        uint followCount; // number of users following this user
        UserFeat[] feats; // list of feats
    }

    Feat[] public featsMasterList; // list of feats
    mapping(bytes => ProtocolFeats) public featsMasterListMap; // feat name => featID reference
    mapping(uint256 => Feat) public feats; // feat ID => feat data
    mapping(address => User) public getUser; // stores the list of feats for each user
    mapping(uint256 => uint256) public tokenIdToFeatId; // maps from tokenId to featID
    mapping(address => mapping(bytes32=>uint)) internal protocolActions; // allow protocol data to be stored in mapping

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
        * @param essenceMw - essence middleware contract (OnlySubscribedMiddleWare) 
     */
    function createAchievements(
        uint256 ccID,
        string calldata name,
        string calldata symbol,
        string calldata essenceURI,
        address essenceMw
        ) external onlyOwner {
        ccRegEssence(ccID, name, symbol, essenceURI, essenceMw, false, true);
    }

    /**
        * @dev check Ghosts.User.raceID and returns feat level based on completion
     */
    function raceFeatCheck(address userAddr) external returns (uint256) {
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
    function stbFeatCheck(address userAddr) external returns (uint256) {
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
        external
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
    function followingFeatCheck(address userAddr) external view returns (uint256) {
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
    function followerFeatCheck(address userAddr) external view returns (uint256) {
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
    function contentFeatCheck(address userAddr) external returns (uint256) {
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
        * @dev Returns the user's CC Essence count, in total.

     */
    // @todo Check CC Essence Collected!!
    function gigaBrainCheck(address userAddr) external view returns (uint256) {

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

    /////////////////////////////////
    ///                           ///
    ///     Internal Functions    ///
    ///                           ///
    /////////////////////////////////


    /**
        * @dev Creates the CC Essence NFT that represents our Achievement Badges
        * @param ccID of the Ghosts Profile as we want these Badges to be minted from 
     */



}
