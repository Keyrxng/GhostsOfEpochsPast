// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/utils/Counters.sol";
import "@openzeppelin/utils/Strings.sol";

contract Ghosts is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter public _userCounter;

    struct User {
        address userAddress; // user address
        uint raceId; // the race they are currently on
        uint completedTasks; // completed tasks
        uint performance; // a percentage based on previous task performance
        bytes32 nickname; // user alias
        bytes32 title; // user job title or other
        bytes32 handle; // user social handle
        string bio; // user bio
    }

    struct WarmUpNFT {
        address userAddress; // user address
        uint currentTaskId; // current task ID
        uint tokenId; // token ID
        bytes32 submittedAnswers; // submitted answers by the user      
}

    struct RaceNFT {
        bytes32 submittedAnswers; // submitted answers by the user
        bytes32 answer; // correct answer to the task
        uint performance; // performance of the user out of 100
        uint currentTaskId; // current task id
        uint tokenId; // token ID
        address userAddress; // user address
    }

    mapping(address=>User) public userMap;

    mapping(address=>WarmUpNFT) private warmUpNFTs; // used to assign WarmUp to User easily 
    mapping(address=>RaceNFT) private raceNFTs; // used to assign RaceNFT to User easily

    mapping(uint=>RaceNFT) private finalRaceNfts; // stores what a final race nft should look like

    mapping(uint=>address) public nftMap; // tracks which nft belongs to which user
    mapping(uint=>bool) private graduatedNFTs; // stores if a warmup has graduated used in tokenURI 
    mapping(uint=>uint) private tokenIdToRaceId; // tracks which token belongs to which race used in tokenURI

    User[] public users; // allows the users to be iterated over 

    error IncorrectSubmission();
    event UserCreated(address indexed who, uint indexed id);

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
    }

    /**
        * @dev Adds new races to the current selection of races.
        * @param races is the accumulative hash of all the race questions.
        * @param length is the current amount of races
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

    function _baseURI() internal override pure returns (string memory) {
        return 'ipfs://QmPKJEfJpDmBTYjCWzQeRfrUqTJfW9bCgZWNyo93VCFVEK/';
    }

    /**
        * @dev Returns the URI for a token.
        * @notice Ensures the tokenID belongs to a race and if so checks if they have graduated that race or not
        * @param id is the tokenID of the Ghost-NFT
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
        * @dev Creates a Ghost user profile in order to compete
        * @param name is the user's publicly used alias
        * @param bio is the user's publicly displayed bio
        * @param title is the user's job title or other
        * @param handle is the user's social handle
     */
    function createUser(bytes32 name, string memory bio, bytes32 title, bytes32 handle) public {
        uint id = _userCounter.current();
        _userCounter.increment();

        User memory user = User(
            msg.sender,
            0,
            0,
            0,
            name,
            title,
            handle,
            bio
        );

        users.push(user);
        userMap[msg.sender] = user;

        emit UserCreated(msg.sender, id);
    }

    /**
        * @dev Allows a user to edit their profile details
        * @param name is the user's publicly used alias
        * @param bio is the user's publicly displayed bio
        * @param title is the user's job title or other
        * @param handle is the user's social handle
     */
    function editUser(bytes32 name, string memory bio, bytes32 title, bytes32 handle) external {
        if(userMap[msg.sender].userAddress == address(0)){
            createUser(name, bio, title, handle);
        }

        User storage user = userMap[msg.sender];

        if(name != user.nickname){
            user.nickname = name;
        }
        if(keccak256(abi.encodePacked(bio)) != keccak256(abi.encodePacked(user.bio))) {
            user.bio = bio;
        }
        if(title != user.title) {
            user.title = title;
        }
        if(handle != user.handle) {
            user.handle = handle;
        }
    }

    /**
        * @dev Allows a registered user to begin their next race
        * @notice A User's current raceID prevents them from minting another if balanceOf() != raceID
        * @notice if a user has no NFT balance, we mint their first WarmUpNFT
     */
    function startNextRace() external {
        require(userMap[msg.sender].userAddress != address(0) , "No User Account");
        require(msg.sender == userMap[msg.sender].userAddress, "Not your account");
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
        * @dev Allows a User to submit their answers.
        * @notice The final hashes are compared to the answer and performance is calculated
        * @param answers are the User's answers submitted as a hash
        * @param perf is the percentage of questions the User got correct        
     */
    function submitCompletedTask(bytes32 answers, uint perf) external {
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
        }
    }

    /**
        * @dev Allows owner to mint warmUp NFTs
        * @notice Another mint is not needed as the NFT uri is dynamic
        * @param to is the User
     */
    function safeMint(address to) internal {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        nftMap[tokenId] = to;
        _safeMint(to, tokenId);
    }
    
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