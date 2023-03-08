// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GhostsFeats} from './GhostsFeats.sol';
import "./library/GhostsLib.sol";

import "@openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/utils/Strings.sol";
import "@openzeppelin/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

contract UUPSProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data)
        ERC1967Proxy(_implementation, _data)
    {}
}

contract Ghosts is 
    GhostsFeats,
    Initializable, 
    ERC721Upgradeable, 
    ERC721EnumerableUpgradeable,
    UUPSUpgradeable
    {
    using Strings for uint256;

    constructor() {
        _disableInitializers();
    }

    /**
        * @dev hashes are imprinted into finalRaceNFTs for comparison for submissions.
        * @param dunno bytes32[] of hashes for the initial round of race content.
     */
    function initialize(bytes32[] memory dunno, string memory uri) initializer public {
        __ERC721_init("TESTTEST", "TST");
        __ERC721Enumerable_init();
        __UUPSUpgradeable_init();

        ghostsAddr = address(this);
        deployer = msg.sender;

        uint8 len = uint8(dunno.length);
        protocolMeta.raceCount = len;
        unchecked {
            for(uint32 x = 0; x < len; x++){
                GhostsLib.RaceNFT memory nft;
                    nft.submittedAnswers = bytes32('0x');
                    nft.answer = dunno[x];
                    nft.userAddress = address(0);
                    nft.tokenID = x;
                    nft.raceID = uint8(x);
                    nft.completed = false;
                finalRaceNFTs[x] = x;
                delete nft;
            }
        }
        protocolMeta.uri = uri;
    }

    function addRace(bytes32 race) external {
        GhostsLib.onlyGhosts(msg.sender, msg.sender);

        uint len = allRaceNFTs.length;

        GhostsLib.RaceNFT memory nft = GhostsLib.RaceNFT({
            submittedAnswers: bytes32('0x'),
            answer: race,
            userAddress: address(0),
            tokenID: 0,
            raceID: protocolMeta.raceCount,
            completed: false
        });

        finalRaceNFTs[len] = len;

        protocolMeta.raceCount++;

        addrToUser[deployer].ctfStbContribs++;
    }

    function addCollab(bytes32[] calldata collab, bytes32 author, bytes32 title, address authAddr) external {
        GhostsLib.onlyGhosts(msg.sender, msg.sender);

        uint8 r = protocolMeta.collabCount == 0 ? 1 : protocolMeta.collabCount++;

        GhostsLib.CollabNFT memory nft = GhostsLib.CollabNFT({
            author: author,
            title: title,
            answers: collab,
            userAddress: address(0),
            tokenID: protocolMeta.tokenCount + 1,
            collabID: r,
            completed: false        
        });

        collabNFTs[r] = r;

        protocolMeta.tokenCount++;
        protocolMeta.collabCount++;
        addrToUser[authAddr].ctfStbContribs++;
        allCollabNFTs.push(nft);

        delete nft;
    }


    function createUser(address who, string memory handle, string[] calldata hashes, uint32 userCount) external returns(bool, uint id) {
        id = _createUser(who, handle, hashes, userCount);
        assert(id != 0);
        return (true, id);
    }

    function createFeats(
        bytes32 name,
        bytes32 symbol,
        bytes32 essenceURI,
        bytes32 description,
        uint64 weight,
        uint64 essID,
        uint64 essTier
    ) external {
        _createFeats(name, symbol, essenceURI, description, weight, essID, essTier);
    }

    function startNextRace() external {
        _startNextRace();

        safeMint(msg.sender);
    }

    function submitRace(bytes32 answers) external {
        _submitRace(answers);
    }

    function startNextCollab(uint8 collabID) external {
        _startNextCollab(collabID);
        safeMint(msg.sender);
    }

    function submitCollab(bytes32[] calldata guesses, uint32 collabID) external {
        _submitCollab(guesses, collabID);
    }

    function followUser(uint32 idToFollow, address addrToFollow) external {
        GhostsLib.User memory user = addrToUser[msg.sender];
        _followUser(idToFollow, user.ccID, addrToFollow);
    }

    function userAwardFeats(
        uint16 featId,
        uint16 tier,
        address userAddr,
        uint32 profileId
    ) external {
        _userAwardFeats(featId, tier, userAddr, profileId);
    }

    function tokenURI(uint id) public view override returns (string memory) {
        if(!_exists(id)){
            revert GhostsLib.NoExists(id);
        }

        bool which = tokIdToType[id][1] != 0 ? true : false;

        if(which){
            uint idd = finalRaceNFTs[id];
            if(idd != 0){
                    return string(abi.encodePacked(_baseURI(), "RaceNFT", idd, ".json"));
                }else{
                    return string(abi.encodePacked(_baseURI(), "WarmUpNFT", idd, ".json"));
                }
        }else{
            uint idd = collabNFTs[id];
            if(idd != 0){
                    return string(abi.encodePacked(_baseURI(), "CollabNFT", idd, ".json"));
                }else{
                    return string(abi.encodePacked(_baseURI(), "v0CollabNFT", idd, ".json"));
                }
            }
        }
    
    function ccSubscribe(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata pre,
        bytes[] calldata post
    ) external {
        GhostsLib.onlyGhosts(msg.sender, msg.sender);
        GhostsLib.ccProfileNFT.subscribe(params, pre, post);
    }

    function setBaseURI(string calldata uri) external {
        GhostsLib.onlyGhosts(msg.sender, msg.sender);
        protocolMeta.uri = uri;
    }

    function _authorizeUpgrade(address /**/)
        internal
        view
        override
    {
        GhostsLib.onlyGhosts(msg.sender, msg.sender);
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }


    /////////////////////////////////
    ///                           ///
    ///     Internal Functions    ///
    ///                           ///
    /////////////////////////////////

   
    function _baseURI() internal override view returns (string memory) {
        return protocolMeta.uri;
    }

    function safeMint(address who) internal returns(uint32 nidx) {
        protocolMeta.tokenCount = protocolMeta.tokenCount + 1;
        nidx = protocolMeta.tokenCount;
        _safeMint(who, nidx);
    }

    /////////////////////////////////
    ///                           ///
    ///         Overrides         ///
    ///                           ///
    /////////////////////////////////

    
    // The following functions are overrides required by Solidity.
    function transferFrom(address,address,uint256) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
        revert GhostsLib.Soulbound();
    }
    function safeTransferFrom(address,address,uint256) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
        revert GhostsLib.Soulbound();
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address /**/,
        address /**/,
        uint256 /**/,
        bytes calldata /**/
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}