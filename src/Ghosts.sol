// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes, IProfileNFT} from "./interfaces/IProfileNFT.sol";
import {IGhosts, IGhostsData} from './interfaces/IGhosts.sol';
import {GhostsFeats} from './GhostsFeats.sol';

import "@openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "forge-std/Test.sol";

import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
contract UUPSProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data)
        ERC1967Proxy(_implementation, _data)
    {}
}

contract Ghosts is 
    Initializable, 
    ERC721Upgradeable, 
    ERC721EnumerableUpgradeable, 
    AccessControlUpgradeable, 
    GhostsFeats, 
    IERC721ReceiverUpgradeable
    {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;
    CountersUpgradeable.Counter private _tokenIdCounter;
    CountersUpgradeable.Counter public _userCounter;
    
    IProfileNFT internal constant ProfileNFT =
        IProfileNFT(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271);

    string public tokenBaseURI;
    uint internal raceCount;
    uint internal collabCount;

    mapping(address=>IGhostsData.User) public userMap; // used for address(0) and ownership checks
    mapping(uint=>IGhostsData.User) public idToUser; 
    mapping(address=>IGhostsData.WarmUpNFT) private warmUpNFT; // used to store the User's current Warmup NFT (if any)
    mapping(address=>IGhostsData.RaceNFT) private raceNFT; // used to store the User's current Race NFT (if any)
    mapping(address=>IGhostsData.CollabNFT) private collabNFT; // used to store the User's current Collab NFT (if any)

    mapping(uint=>IGhostsData.CollabNFT) public collabNFTs; // stores the final collab NFTs for each collab to compare against
    mapping(uint=>IGhostsData.RaceNFT) public finalRaceNfts; // stores the final race NFT for each race to compare against

    mapping(uint=>bool) private graduatedNFTs; // "pops" a warmUp NFT and upgrades it to a RaceNFT. URI relies on this.
    mapping(uint=>bool) private graduatedCollabNFTs; // "pops" a warmUp NFT and upgrades it to a CollabNFT. URI relies on this.
    mapping(uint=>uint) private tokenIdToRaceId; // gates access to uncompleted races. URI relies on this.
    mapping(uint=>uint) private tokenIdToCollabId; // tracks id > id for uri purposes
    error IncorrectSubmission();
    error AccountExists(address who, uint ccID);
    error AlreadySubmitted(uint raceID);
    error FinishFirst(uint taskId);
    error Soulbound();

    event RaceCreated(uint indexed id);
    event UserCreated(address indexed who, uint indexed ccID);
    event RaceCompleted(address indexed who, uint indexed raceID, uint indexed ccID);
    event RaceStarted(address indexed who, uint indexed raceID, uint indexed ccID);
    event CollabStarted(address indexed user, uint indexed currentCollab);

    constructor() {
        _disableInitializers();
    }

    /**
        * @dev hashes are imprinted into finalRaceNFTs for comparison for submissions.
        * @param dunno bytes32[] of hashes for the initial round of race content.
     */
    function initialize(bytes32[] memory dunno) initializer public {
        __ERC721_init("TESTTEST", "TST");
        __ERC721Enumerable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __GhostsFeats_init(msg.sender);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

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

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /////////////////////////////////
    ///                           ///
    ///     External Functions    ///
    ///                           ///
    /////////////////////////////////


    function ccGhostMaker(string memory ghosts, string[] memory hashes, address proxy) external onlyRole(UPGRADER_ROLE){
        ghostsAddr = proxy;
        uint id = createGhostsCC(ghosts, hashes, proxy);
        userIdToFollowed[proxy].push(0); // tests UserId
        userIdToFollowers[proxy].push(0); // tests UserId
    }

    function ccAchievementMaker(
        string calldata name,
        string calldata symbol,
        string[] calldata essenceURI,
        string calldata description,
        uint16 weight,
        uint16 tier
    ) external onlyRole(UPGRADER_ROLE) {
        bytes memory payload = abi.encodeWithSignature(
            "ccRegEssence(uint256, string, string, string, bytes32)",
             ghostsCCID, name, symbol, essenceURI, address(0));
        for(uint x = 0; x < essenceURI.length; ++x){
        createAchievements(name, symbol, essenceURI[x], description, weight , tier, payload);
        }
    }

    /**
        * @param races of race content hashes
     */
    function addRaces(bytes32[] memory races) external onlyRole(UPGRADER_ROLE) {
        uint r = raceCount;
        uint s = races.length;

        for(uint x = r; x< r+s; ++x){
            console.log("step1", x);
            for(uint y = 0; y< s; ++y){
            console.log("step2", y, (r+y));
                finalRaceNfts[r+y] = IGhostsData.RaceNFT({
                submittedAnswers: bytes32('0x'),
                answer: races[y],
                performance: 0,
                currentTaskId: (r+y),
                tokenId: (r+y),
                userAddress: address(0)
            });
            }
        }
    }

    function addCollab(bytes32[] calldata collab, bytes calldata author, bytes calldata title) external onlyRole(UPGRADER_ROLE) {

        uint r = collabCount == 0 ? 1 : collabCount;
        collabCount = r;
        collabNFTs[r] = IGhostsData.CollabNFT({
            author: author,
            title: title,
            answers: collab,
            collabID: r,
            tokenID: uint(0),
            currentId: 0,
            completed: false,
            userAddress: address(0)
        });
        collabCount ++;
        userMap[msg.sender].ctfStbContribs++;
    }
       

    /**
        * @param uri of new IPFS URI "ipfs://hash..../"
     */
    function setBaseURI(string calldata uri) external onlyRole(UPGRADER_ROLE) {
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
        uint tokenCollabId = tokenIdToCollabId[id];


        if(graduatedNFTs[id]){
            return string(abi.encodePacked(_baseURI(), "RaceNFT", tokenRaceId.toString(), ".json"));
        }
        
        if(graduatedCollabNFTs[id]){
            return string(abi.encodePacked(_baseURI(), "CollabNFT", tokenCollabId.toString(), ".json"));
        }
        
        if(tokenCollabId != 0 && !graduatedCollabNFTs[id]){
            return string(abi.encodePacked(_baseURI(), "v0CollabNFT", tokenCollabId.toString(), ".json"));
        }else{
            return string(abi.encodePacked(_baseURI(), "WarmUpNFT", tokenRaceId.toString(), ".json"));
        }        
    }

    /**
        * @dev creates a profile with Ghosts as well as minting a CC NFT to the msg.sender.
        * @param handle of the user 
        * @param hashes of profiles hash[0]: avatar, hash[1]: metadata
     */
    function createUser(string memory handle, string[] memory hashes) external returns (uint){
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
            0, // collabId
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
        userAwardFeats(1, 1, msg.sender, ccID);
        emit UserCreated(msg.sender, ccID);
        delete user;
        return ccID;
    }

    function submitCollab(bytes32[] memory guesses) external {
        require(userMap[msg.sender].userAddress != address(0) , "No User Account");
        IGhostsData.User storage user = userMap[msg.sender];
        IGhostsData.CollabNFT storage collab = collabNFT[msg.sender];
        console2.log("collabID", collab.collabID);
        console2.log("user.collabId", user.collabId);
        require(collab.collabID > user.collabId, "Not Started Yet!");

        uint len = guesses.length;
        bytes32[] memory answers = new bytes32[](len);
        for(uint x = 0; x < len; ++x){
            bytes32 guess = guesses[x];
            answers[x] = keccak256(abi.encodePacked(guess));
        }
        
        if(keccak256(abi.encodePacked(collab.answers)) == keccak256(abi.encodePacked(answers))){
            user.spotTheBugs += 1;

            console2.log("stbs", user.spotTheBugs);


            uint currentPerformance = user.performance;
            uint newPerformance = (currentPerformance + 100) / (raceCount + collabCount);
            user.performance = newPerformance;

            graduatedCollabNFTs[collab.tokenID] = true;
            collab.completed = true;
        }else{
            revert IncorrectSubmission();
        }
    }

    function startNextCollab() external {
        require(userMap[msg.sender].userAddress != address(0) , "No User Account");
        IGhostsData.User memory user = userMap[msg.sender];
        uint currentCollab = user.collabId == 0 ? 1 : user.collabId;
        IGhostsData.CollabNFT memory fCollab = collabNFTs[currentCollab];

        console2.log("currentCollab", currentCollab);
        console2.log("collabNFTs[currentCollab].collabID", collabNFTs[currentCollab].collabID);


        if(user.collabId == fCollab.collabID){
            if(!fCollab.completed){
                revert FinishFirst(fCollab.collabID);
            }
        }

        uint nextId = (_tokenIdCounter.current() + 1);

        fCollab.tokenID = nextId;
        fCollab.userAddress = msg.sender;
        fCollab.currentId = currentCollab;
        collabNFT[msg.sender] = fCollab;
        user.collabId = fCollab.collabID;

        safeMint(msg.sender);
        emit CollabStarted(msg.sender, fCollab.collabID);
    }

    /**
        * @dev Ghosts profile required. Mints WarmUpNFT for current race in progress.
        * @notice User profiles are created with zero values by choice for frontend purposes whereas tokenId starts from 1.
        * @notice User.raceId is only incremented after submitting which means 1st warmUp raceId = 0 balance = 1, after submit raceId = 1 && balance = 1.
     */
    function startNextRace() external {
        require(userMap[msg.sender].userAddress != address(0) , "No User Account");
        IGhostsData.User storage user = userMap[msg.sender];
        uint currentRace = user.raceId == 0 ? 1 : user.raceId;

        console2.log("raceID:", currentRace);
        uint nextId = (_tokenIdCounter.current() + 1);
        IGhostsData.WarmUpNFT memory warmUp = IGhostsData.WarmUpNFT({
            userAddress: msg.sender,
            currentTaskId: currentRace,
            submittedAnswers: bytes32('0x'),
            tokenId: nextId
        });
        warmUpNFT[msg.sender] = warmUp;
        if(balanceOf(msg.sender) == 0){
            userMap[msg.sender].raceId += 1;
            safeMint(msg.sender);
            emit RaceStarted(msg.sender, 1, user.ccID);
        }else{
            require(graduatedNFTs[user.raceId], "Finish your active race first.");
            userMap[msg.sender].raceId +=1;            
            safeMint(msg.sender);
            emit RaceStarted(msg.sender, userMap[msg.sender].raceId, user.ccID);
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

        IGhostsData.WarmUpNFT memory warmUp = warmUpNFT[msg.sender];
        IGhostsData.RaceNFT memory raceNFT_ = finalRaceNfts[user.raceId];

        if(raceNFT_.submittedAnswers == answers) revert AlreadySubmitted(user.raceId);
        warmUp.submittedAnswers = answers;
        
        if(answers != raceNFT_.answer) {
            revert IncorrectSubmission();
        }else{
            require(warmUp.userAddress == msg.sender, "already graduated warmup NFT");
            delete warmUpNFT[msg.sender];
            graduatedNFTs[warmUp.tokenId] = true;
            user.completedTasks +=1;
            
            uint currentPerformance = user.performance;
            uint newPerformance = (currentPerformance + perf) / (raceCount + collabCount);
            user.performance = newPerformance;

            IGhostsData.RaceNFT memory completedNFT = IGhostsData.RaceNFT({
                submittedAnswers: answers,
                answer: answers,
                performance: perf,
                currentTaskId: user.raceId,
                tokenId: warmUp.tokenId,
                userAddress: msg.sender
            });
            emit RaceCompleted(msg.sender, user.raceId, user.ccID);

            raceNFT[msg.sender] = completedNFT;
            delete completedNFT;
            delete raceNFT_;
            delete warmUp;
        }
    }

    

    /////////////////////////////////
    ///                           ///
    ///     Internal Functions    ///
    ///                           ///
    /////////////////////////////////

    /**
        * @dev E Z P Z minting, doesn't care about warmUps or raceNFT. Only called by this address.
        * @param to, the address of the user
     */
    function safeMint(address to) internal {
        _tokenIdCounter.increment();
        uint nextId = _tokenIdCounter.current();
        tokenIdToRaceId[nextId] = userMap[msg.sender].raceId ;
        _safeMint(to, nextId);
    }


    function _baseURI() internal override view returns (string memory) {
        return tokenBaseURI;
    }

    function ccSubscribe(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata pre,
        bytes[] calldata post
    ) external onlyRole(UPGRADER_ROLE) {
        ccProfileNFT.subscribe(params, pre, post);
    }




    /////////////////////////////////
    ///                           ///
    ///         Overrides         ///
    ///                           ///
    /////////////////////////////////

    
    // The following functions are overrides required by Solidity.
    function transferFrom(address,address,uint256) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
        revert Soulbound();
    }
    function safeTransferFrom(address,address,uint256) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
        revert Soulbound();
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
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}