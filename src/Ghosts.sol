// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/utils/Counters.sol";
import "@openzeppelin/utils/Strings.sol";
import {DataTypes, IProfileNFT} from "./IProfileNFT.sol";

contract Ghosts is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter public _userCounter;

    IProfileNFT constant ProfileNFT = IProfileNFT(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271);

    string public tokenBaseURI;

    struct User {
        address userAddress; // user address
        uint raceId; // the race they are currently on
        uint completedTasks; // completed tasks
        uint performance; // a percentage based on previous task performance
        uint spotTheBugs; // completed spot the bugs tasks
        uint contentPosts; // content posted
        uint ctfStbContribs; // CTF or STB contributions made
        uint ccID; // their CC id
    }

    struct WarmUpNFT {
        address userAddress;
        uint currentTaskId;
        uint tokenId;
        bytes32 submittedAnswers; // submitted answers by the user      
}

    struct RaceNFT {
        bytes32 submittedAnswers; // submitted answers by the user
        bytes32 answer;
        uint performance; // performance of the user out of 100
        uint currentTaskId; 
        uint tokenId;
        address userAddress;
    }

    mapping(address=>User) public userMap; // used for address(0) and ownership checks

    mapping(address=>WarmUpNFT) private warmUpNFTs; // used to store the User's current Warmup NFT (if any)
    mapping(address=>RaceNFT) private raceNFTs; // used to store the User's current Race NFT (if any)

    mapping(uint=>RaceNFT) public finalRaceNfts; // stores the final race NFT for each race to compare against

    mapping(uint=>bool) private graduatedNFTs; // "pops" a warmUp NFT and upgrades it to a RaceNFT. URI relies on this.
    mapping(uint=>uint) private tokenIdToRaceId; // gates access to uncompleted races. URI relies on this.


    User[] public users; // stores all users

    error IncorrectSubmission();
    event UserCreated(address indexed who, uint indexed id);


    /**
        * @dev hashes are imprinted into finalRaceNFTs for comparison for submissions.
        * @param dunno bytes32[] of hashes for the initial round of race content.
     */
    constructor(bytes32[] memory dunno) ERC721("GhostsOfEpochsPast", "Ghosts") payable {
        uint len = dunno.length;
        for(uint x = 0; x < len; x++){
            finalRaceNfts[x] = RaceNFT({
                submittedAnswers: bytes32('0x'),
                answer: dunno[x],
                performance: 0,
                currentTaskId: x,
                tokenId: x,
                userAddress: address(0)
            });
        }
        tokenBaseURI = "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/";
    }

    /////////////////////////////////
    ///                           ///
    ///          GETTERS          ///
    ///                           ///
    /////////////////////////////////

    function ccGetMetadata(uint profileId) public view returns (string memory) {
        return ProfileNFT.getMetadata(profileId);
    }

    function ccGetAvatar(uint profileId) public view returns (string memory) {
        return ProfileNFT.getAvatar(profileId);
    }

    function ccGetSubNFTAddr(uint profileId) public view returns (address) {
        return ProfileNFT.getSubscribeNFT(profileId);
    }

    function ccGetSubURI(uint profileId) public view returns (string memory) {
        return ProfileNFT.getSubscribeNFTTokenURI(profileId);
    }

    function ccGetEssNFTAddr(uint profileId, uint essId) public view returns (address) {
        return ProfileNFT.getEssenceNFT(profileId, essId);
    }

    function ccGetEssURI(uint profileId, uint essId) public view returns (string memory) {
        return ProfileNFT.getEssenceNFTTokenURI(profileId, essId);
    }


    /////////////////////////////////
    ///                           ///
    ///     External Functions    ///
    ///                           ///
    /////////////////////////////////

    /**
        * @dev relies on the owner supplying the correct length of the current supply of race content (mapping len)
        * @param races of race content hashes
        * @param length of the current raceNFTs mapping (amount of active races)
     */
    function addRaces(bytes32[] memory races, uint length) external onlyOwner {
        uint len = races.length - 1;
        uint newlen = length + len;
        for(uint x = length;newlen > len; --x){
            finalRaceNfts[x] = RaceNFT({
                submittedAnswers: bytes32('0x'),
                answer: races[x],
                performance: 0,
                currentTaskId: x,
                tokenId: x,
                userAddress: address(0)
            });
        }
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
        uint id = _userCounter.current();
        _userCounter.increment();
        
        DataTypes.CreateProfileParams memory params;
        params.to = msg.sender;
        params.handle = handle; 
        params.avatar = hashes[0];
        params.metadata = hashes[1];
        params.operator = address(this);

        ProfileNFT.createProfile(params, '','');
        uint ccID = ProfileNFT.getProfileIdByHandle(handle);

        User memory user = User(
            msg.sender,
            0, // raceId
            0, // completedTasks
            0, // performance
            0, // spotTheBugs
            0, // contentPosts
            0, // ctfStbContribs
            ccID // CyberConnect Profile ID
        );

        users.push(user);
        userMap[msg.sender] = user;

        emit UserCreated(msg.sender, id);
    }

    /**
        * @dev Ghosts profile required. Mints WarmUpNFT for current race in progress.
        * @notice User profiles are created with zero values by choice for frontend purposes whereas tokenId starts from 1.
        * @notice User.raceId is only incremented after submitting which means 1st warmUp raceId = 0 balance = 1, after submit raceId = 1 && balance = 1.
     */
     
    function startNextRace() external {
        require(userMap[msg.sender].userAddress != address(0) , "No User Account");
        User memory user = userMap[msg.sender];
        uint currentRace = user.raceId;
        uint nextId = (_tokenIdCounter.current() + 1);
        WarmUpNFT memory warmUp = WarmUpNFT({
            userAddress: msg.sender,
            currentTaskId: currentRace,
            submittedAnswers: bytes32('0x'),
            tokenId: nextId
        });
        warmUpNFTs[msg.sender] = warmUp;
        tokenIdToRaceId[nextId] = currentRace;

        if(balanceOf(msg.sender) == 0){
            safeMint(msg.sender);    
        }else{
            require(balanceOf(msg.sender) == user.raceId, "Finish your active race first.");
            safeMint(msg.sender);
        }
    }

    /**
        * @dev WarmUpNFT required. Pops current warmUpNFT from mapping + pushes tokenId to graduatedNFTs. Metadata will return RaceNFT JSON.
        * @notice User.raceId is incremented after a task has been submitted successfully.
        * @param answers of user total user submissions. The hash of the hashes of individual answers.
        * @param metadata with additional info regarding user performances etc for CC.
     */
    function submitCompletedTask(bytes32 answers, uint perf, string memory metadata) external {
        User storage user = userMap[msg.sender];
        require(user.userAddress != address(0) , "No User Account");
        require(balanceOf(msg.sender) != 0 , "cannot submit a task without the warmUp NFT");


        WarmUpNFT memory warmUp = warmUpNFTs[msg.sender];

        RaceNFT memory raceNFT = finalRaceNfts[warmUp.currentTaskId];

        warmUp.submittedAnswers = answers;

        if(answers != raceNFT.answer) {
            revert IncorrectSubmission();
        }else{
            delete warmUpNFTs[msg.sender];
            graduatedNFTs[warmUp.tokenId] = true;
            user.raceId += 1;
            user.completedTasks++;

            uint currentPerformance = user.performance;
            uint newPerformance = (currentPerformance + perf) / user.completedTasks;
            user.performance = newPerformance;

            RaceNFT memory completedNFT = RaceNFT({
                submittedAnswers: answers,
                answer: answers,
                performance: perf,
                currentTaskId: user.raceId,
                tokenId: warmUp.tokenId,
                userAddress: msg.sender
            });

            raceNFTs[msg.sender] = completedNFT;
            ProfileNFT.setMetadata(user.ccID, metadata);
        }
    }

    function ccSubscribe(uint256[] calldata profileIDs) external {
        _ccSubscribe(profileIDs, msg.sender);
    }

        /**
        * @dev sets the namespace owner of the ProfileNFT to the provided address.
        * @param addr of new namespace owner
     */
    function ccSetNSOwner(address addr) external {
        ProfileNFT.setNamespaceOwner(addr);
    }

    function ccRegEssence(
        uint profileId,
        string calldata name,
        string calldata symbol,
        string calldata essenceURI,
        address essenceMw, 
        bool transferable,
        bool deployAtReg,
        address essBeacon
    ) external {
        DataTypes.RegisterEssenceParams memory params;

        params.profileId = profileId;
        params.name = name;
        params.symbol = symbol;
        params.essenceTokenURI = essenceURI;
        params.essenceMw = essenceMw;
        params.transferable = transferable;
        params.deployAtRegister = deployAtReg;

        _ccRegEssence(params);
    }

    function ccCollectEss(
        address who, uint profileId, uint essenceId
    ) external {
        DataTypes.CollectParams memory params;
        params.collector = who;
        params.profileId = profileId;
        params.essenceId = essenceId;

        _ccCollectEss(params);
    }

    function ccSetMetadata(uint profileId, string calldata metadata) external {
        _ccSetMetadata(profileId, metadata);
    }

    function ccSetSubData(uint profileId, string calldata uri, address mw, bytes calldata mwData) external {
        _ccSetSubData(profileId, uri, mw, mwData);
    }

    function ccSetEssData(uint profileId, uint essId, string calldata uri, address mw, bytes calldata mwData) external {
        _ccSetEssData(profileId, essId, uri, mw, mwData);
    }

    function ccSetPrimary(uint profileId) external {
        _ccSetPrimary(profileId);
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

    function _ccSubscribe(uint256[] calldata profileIDs, address who) internal {
        DataTypes.SubscribeParams memory params;
        params.subscriber = who;
        params.profileIds = profileIDs;
        bytes[] memory initData;
        
        ProfileNFT.subscribe(params, initData, initData); 
    }

    function _ccRegEssence(
        DataTypes.RegisterEssenceParams memory params
        ) internal {
        ProfileNFT.registerEssence(params, '');
    }

    function _ccCollectEss(DataTypes.CollectParams memory params) internal {
        ProfileNFT.collect(params, '', '');
    }

    function _ccSetMetadata(uint profileId, string calldata metadata) internal {
        ProfileNFT.setMetadata(profileId, metadata); 
    }

    function _ccSetSubData(uint profileId, string calldata uri, address mw, bytes calldata mwData) internal {
        ProfileNFT.setSubscribeData(profileId, uri, mw, mwData);
    }

    function _ccSetEssData(uint profileId, uint essId, string calldata uri, address mw, bytes calldata mwData) internal {
        ProfileNFT.setEssenceData(profileId, essId, uri, mw, mwData);
    }

    function _ccSetPrimary(uint profileId) internal {
        ProfileNFT.setPrimaryProfile(profileId);
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
}