// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/utils/Counters.sol";
import "@openzeppelin/utils/Strings.sol";
import {GhostsHub} from "./GhostsHub.sol";
import {DataTypes} from "./IProfileNFT.sol";
import {IGhosts} from "./IGhosts.sol";

contract GhostsFeats is
    GhostsHub,
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;

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

    constructor(address ghostsAddr) payable ERC721("GhostsFeats", "GFEATS") {
        GhostsAddr = ghostsAddr;
        tokenBaseURI = "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/";
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
        } else if (spotTheBugs == 100) {
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
        protocolActions[msg.sender][FOLLOWUSER] += 1;
        uint256 ccID = IGhosts(GhostsAddr).getUser(userAddr).ccID; // get users raceID
        uint256[] memory profileIDs = new uint[](1);
        profileIDs[0] = ccID;
        _ccSubscribe(profileIDs, userAddr);
        emit NewFollow(userAddr, _followed);
        return true;
    }



    /**
     * @param uri of new IPFS URI "ipfs://hash..../"
     */
    function setBaseURI(string calldata uri) external onlyOwner {
        tokenBaseURI = uri;
    }

    /**
     * @dev Metadata is reliant on graduatedNFTs[id] checks
     * @dev TokenId is uncapped but raceIDs are aren't so tokenIdToRaceId ensures the metadata for the correct race is returned
     * @param id of the token
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), "Feat", ".json"));
    }

    /////////////////////////////////
    ///                           ///
    ///     Internal Functions    ///
    ///                           ///
    /////////////////////////////////

    /**
     * @dev E Z P Z minting, doesn't care about warmUps or raceNFTs. Only called by this address.
     * @param to, the address of the user
     */
    function safeMint(address to) internal {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    /////////////////////////////////
    ///                           ///
    ///         Overrides         ///
    ///                           ///
    /////////////////////////////////

    // The following functions are overrides required by Solidity.
    // soulbound
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override(ERC721, IERC721) {
        return;
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public pure override(ERC721, IERC721) {
        return;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
