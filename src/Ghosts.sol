// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {ERC721Enumerable} from "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Burnable} from "@openzeppelin/token/ERC721/extensions/ERC721Burnable.sol";
import {Counters} from "@openzeppelin/utils/Counters.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import "@openzeppelin/token/ERC721/IERC721Receiver.sol";

import {DataTypes, IProfileNFT} from "./interfaces/IProfileNFT.sol";
import {IGhosts, IGhostsData} from './interfaces/IGhosts.sol';
import {GhostsFeats} from './GhostsFeats.sol';


contract Ghosts is GhostsFeats, IERC721Receiver, ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter public _userCounter;
    
    IProfileNFT internal constant ProfileNFT =
        IProfileNFT(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271);

    string public tokenBaseURI;
    uint internal raceCount;

    mapping(address=>IGhostsData.User) public userMap; // used for address(0) and ownership checks
    mapping(uint=>IGhostsData.User) public idToUser; 
    mapping(address=>IGhostsData.WarmUpNFT) private warmUpNFTs; // used to store the User's current Warmup NFT (if any)
    mapping(address=>IGhostsData.RaceNFT) private raceNFTs; // used to store the User's current Race NFT (if any)

    mapping(uint=>IGhostsData.RaceNFT) public finalRaceNfts; // stores the final race NFT for each race to compare against

    mapping(uint=>bool) private graduatedNFTs; // "pops" a warmUp NFT and upgrades it to a RaceNFT. URI relies on this.
    mapping(uint=>uint) private tokenIdToRaceId; // gates access to uncompleted races. URI relies on this.

    error IncorrectSubmission();
    error AccountExists(address who, uint ccID);
    error AlreadySubmitted(uint raceID);

    event RaceCreated(uint indexed id);
    event UserCreated(address indexed who, uint indexed ccID);
    event RaceCompleted(address indexed who, uint indexed raceID, uint indexed ccID);
    event RaceStarted(address indexed who, uint indexed raceID, uint indexed ccID);


    /**
        * @dev hashes are imprinted into finalRaceNFTs for comparison for submissions.
        * @param dunno bytes32[] of hashes for the initial round of race content.
     */
    constructor(bytes32[] memory dunno) ERC721("TEST", "TST") payable {
        uint len = dunno.length;
        raceCount = len;
        for(uint x = 0; x < len; x++){
            finalRaceNfts[x] = IGhostsData.RaceNFT({
                submittedAnswers: bytes32('0x'),
                answer: dunno[x],
                performance: 0,
                currentTaskId: x,
                tokenId: x,
                userAddress: address(0)
            });
        }
        tokenBaseURI = "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/";
        ghostsAddr = address(this);
    }

    /////////////////////////////////
    ///                           ///
    ///     External Functions    ///
    ///                           ///
    /////////////////////////////////


    function ccGhostMaker(string memory ghosts, string[] memory hashes) external onlyOwner {
        uint id = createGhostsCC(ghosts, hashes, address(this));
        ghostsCCID = id;
    }

    function ccAchievementMaker(
        string calldata name,
        string calldata symbol,
        string[] calldata essenceURI,
        string calldata description,
        uint16 weight,
        uint16 tier
    ) external onlyOwner {
        for(uint x = 0; x < essenceURI.length; ++x){
        createAchievements(name, symbol, essenceURI[x], description, weight , tier);
        }
    }

    /**
        * @param races of race content hashes
     */
    function addRaces(bytes32[] memory races) external onlyOwner {
        uint r = raceCount;
        uint s = races.length;
        for(uint x = r; x < r; ++x){
            finalRaceNfts[x] = IGhostsData.RaceNFT({
                    submittedAnswers: bytes32('0x'),
                    answer: races[x],
                    performance: 0,
                    currentTaskId: x,
                    tokenId: x,
                    userAddress: address(0)
                });

        }
        raceCount += s;
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
    function tokenURI(uint id) public view override returns (string memory) {
        require(_exists(id), "ERC721Metadata: URI query for nonexistent token");
        uint tokenRaceId = tokenIdToRaceId[id];

        tokenRaceId++;

        if(!graduatedNFTs[id]){
            return string(abi.encodePacked(_baseURI(), "WarmUpNFT", tokenRaceId.toString(), ".json"));
        }else{
            return string(abi.encodePacked(_baseURI(), "RaceNFT", tokenRaceId.toString(), ".json"));
        }
    }

    /**
        * @dev creates a profile with Ghosts as well as minting a CC NFT to the msg.sender.
        * @param handle of the user 
        * @param hashes of profiles hash[0]: avatar, hash[1]: metadata
     */
    function createUser(string memory handle, string[] memory hashes) external {
        uint ccID = userMap[msg.sender].ccID;

        if(ccID != 0){
            revert AccountExists(msg.sender, ccID);
        }

        _userCounter.increment();
        
        DataTypes.CreateProfileParams memory params;
        params.to = msg.sender;
        params.handle = handle; 
        params.avatar = hashes[0];
        params.metadata = hashes[1];
        params.operator = address(this);

        ProfileNFT.createProfile(params, '','');
        ccID = ProfileNFT.getProfileIdByHandle(handle);
        uint id = _userCounter.current();

        IGhostsData.User memory user = IGhostsData.User(
            msg.sender,
            0, // raceId
            0, // completedTasks
            0, // performance
            0, // spotTheBugs
            0, // contentPosts
            0, // ctfStbContribs
            ccID, // CyberConnect Profile ID
            id // Ghosts User ID
        );
        userMap[msg.sender] = user;
        idToUser[id] = user;
        // userAwardFeats(1, 1, msg.sender, ccID);
        emit UserCreated(msg.sender, ccID);
    }

    /**
        * @dev Ghosts profile required. Mints WarmUpNFT for current race in progress.
        * @notice User profiles are created with zero values by choice for frontend purposes whereas tokenId starts from 1.
        * @notice User.raceId is only incremented after submitting which means 1st warmUp raceId = 0 balance = 1, after submit raceId = 1 && balance = 1.
     */
    function startNextRace() external {
        require(userMap[msg.sender].userAddress != address(0) , "No User Account");
        IGhostsData.User memory user = userMap[msg.sender];
        uint currentRace = user.raceId;
        uint nextId = (_tokenIdCounter.current() + 1);
        IGhostsData.WarmUpNFT memory warmUp = IGhostsData.WarmUpNFT({
            userAddress: msg.sender,
            currentTaskId: currentRace,
            submittedAnswers: bytes32('0x'),
            tokenId: nextId
        });
        warmUpNFTs[msg.sender] = warmUp;
        tokenIdToRaceId[nextId] = currentRace;

        if(balanceOf(msg.sender) == 0){
            safeMint(msg.sender);
            emit RaceStarted(msg.sender, currentRace, user.ccID);
        }else{
            require(balanceOf(msg.sender) == user.raceId, "Finish your active race first.");
            safeMint(msg.sender);
            emit RaceStarted(msg.sender, currentRace, user.ccID);
        }
    }

    /**
        * @dev WarmUpNFT required. Pops current warmUpNFT from mapping + pushes tokenId to graduatedNFTs. Metadata will return RaceNFT JSON.
        * @notice User.raceId is incremented after a task has been submitted successfully.
        * @param answers of user total user submissions. The hash of the hashes of individual answers.
        * @param perf of user current submissions
     */
    function submitCompletedTask(bytes32 answers, uint perf) external {
        IGhostsData.User storage user = userMap[msg.sender];
        require(user.userAddress != address(0) , "No User Account");
        require(balanceOf(msg.sender) != 0 , "cannot submit a task without the warmUp NFT");

        IGhostsData.WarmUpNFT memory warmUp = warmUpNFTs[msg.sender];

        IGhostsData.RaceNFT memory raceNFT = finalRaceNfts[warmUp.currentTaskId];

        if(raceNFT.submittedAnswers == answers) revert AlreadySubmitted(warmUp.currentTaskId);
        warmUp.submittedAnswers = answers;

        if(answers != raceNFT.answer) {
            revert IncorrectSubmission();
        }else{
            emit RaceCompleted(msg.sender, user.raceId, user.ccID);

            delete warmUpNFTs[msg.sender];
            graduatedNFTs[warmUp.tokenId] = true;
            user.raceId += 1;
            user.completedTasks++;

            uint currentPerformance = user.performance;
            uint newPerformance = (currentPerformance + perf) / raceCount;
            user.performance = newPerformance;

            IGhostsData.RaceNFT memory completedNFT = IGhostsData.RaceNFT({
                submittedAnswers: answers,
                answer: answers,
                performance: perf,
                currentTaskId: user.raceId,
                tokenId: warmUp.tokenId,
                userAddress: msg.sender
            });

            raceNFTs[msg.sender] = completedNFT;
            delete completedNFT;
            delete raceNFT;
            delete warmUp;
        }
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


    function _baseURI() internal override view returns (string memory) {
        return tokenBaseURI;
    }

    function ccSubscribe(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata pre,
        bytes[] calldata post
    ) external onlyOwner {
        ccProfileNFT.subscribe(params, pre, post);
    }




    /////////////////////////////////
    ///                           ///
    ///         Overrides         ///
    ///                           ///
    /////////////////////////////////


    
    // The following functions are overrides required by Solidity.
    // soulbound
    function transferFrom(address,address,uint256) public pure override(ERC721, IERC721) {
        return;
    }
    function safeTransferFrom(address,address,uint256) public pure override(ERC721, IERC721) {
        return;
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
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

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}