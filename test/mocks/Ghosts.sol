// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.9;

// import "@openzeppelin/token/ERC721/ERC721.sol";
// import "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/token/ERC721/extensions/ERC721Burnable.sol";
// import "@openzeppelin/access/Ownable.sol";
// import "@openzeppelin/utils/Counters.sol";
// import "@openzeppelin/utils/Strings.sol";

// contract GhostsTest is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
//     using Counters for Counters.Counter;
//     using Strings for uint256;
//     Counters.Counter private _tokenIdCounter;
//     Counters.Counter public _userCounter;

//     struct User {
//         address userAddress; // user address
//         uint raceId; // the race they are currently on
//         uint completedTasks; // completed tasks
//         uint performance; // a percentage based on previous task performance
//         bytes32 nickname;
//         bytes32 title;
//         bytes32 handle;
//         string bio;
//     }

//     struct WarmUpNFT {
//         address userAddress;
//         uint currentTaskId;
//         uint tokenId;
//         bytes32 submittedAnswers; // submitted answers by the user
//     }

//     struct RaceNFT {
//         bytes32 submittedAnswers; // submitted answers by the user
//         bytes32 answer;
//         uint performance; // performance of the user out of 100
//         uint currentTaskId;
//         uint tokenId;
//         address userAddress;
//     }

//     mapping(address => User) public userMap;

//     mapping(address => WarmUpNFT) private warmUpNFTs;
//     mapping(address => RaceNFT) private raceNFTs;

//     mapping(address => RaceNFT[]) private userRaceNFTs;

//     mapping(uint => RaceNFT) public finalRaceNfts;

//     mapping(uint => address) private nftMap;
//     mapping(uint => bool) private graduatedNFTs;
//     mapping(uint => uint) private tokenIdToRaceId;

//     User[] public users;

//     error IncorrectSubmission();
//     event UserCreated(address indexed who, uint indexed id);

//     constructor(
//         bytes32[] memory dunno
//     ) payable ERC721("GhostsOfEpochsPast", "Ghosts") {
//         uint len = dunno.length;
//         for (uint x = 0; x < len; x++) {
//             finalRaceNfts[x] = RaceNFT({
//                 submittedAnswers: bytes32("0x"),
//                 answer: dunno[x],
//                 performance: 0,
//                 currentTaskId: x,
//                 tokenId: x,
//                 userAddress: address(0)
//             });
//         }
//     }

//     function addRaces(bytes32[] memory races, uint length) external onlyOwner {
//         uint len = races.length - 1;
//         uint newlen = length + len;
//         for (uint x = length; newlen > len; --x) {
//             finalRaceNfts[x] = RaceNFT({
//                 submittedAnswers: bytes32("0x"),
//                 answer: races[x],
//                 performance: 0,
//                 currentTaskId: x,
//                 tokenId: x,
//                 userAddress: address(0)
//             });
//         }
//     }

//     function _baseURI() internal pure override returns (string memory) {
//         return "ipfs://QmPKJEfJpDmBTYjCWzQeRfrUqTJfW9bCgZWNyo93VCFVEK/";
//     }

//     function tokenURI(uint id) public view override returns (string memory) {
//         require(_exists(id), "ERC721Metadata: URI query for nonexistent token");
//         uint tokenRaceId = tokenIdToRaceId[id];

//         tokenRaceId++;

//         if (!graduatedNFTs[id]) {
//             return
//                 string(
//                     abi.encodePacked(
//                         _baseURI(),
//                         "WarmUpNFT",
//                         tokenRaceId.toString(),
//                         ".json"
//                     )
//                 );
//         } else {
//             return
//                 string(
//                     abi.encodePacked(
//                         _baseURI(),
//                         "RaceNFT",
//                         tokenRaceId.toString(),
//                         ".json"
//                     )
//                 );
//         }
//     }

//     function createUser(
//         bytes32 name,
//         string memory bio,
//         bytes32 title,
//         bytes32 handle
//     ) public {
//         uint id = _userCounter.current();
//         _userCounter.increment();

//         User memory user = User(msg.sender, 0, 0, 0, name, title, handle, bio);

//         users.push(user);
//         userMap[msg.sender] = user;

//         emit UserCreated(msg.sender, id);
//     }

//     function editUser(
//         bytes32 name,
//         string memory bio,
//         bytes32 title,
//         bytes32 handle
//     ) external {
//         if (userMap[msg.sender].userAddress == address(0)) {
//             createUser(name, bio, title, handle);
//         }

//         User storage user = userMap[msg.sender];

//         if (name != user.nickname) {
//             user.nickname = name;
//         }
//         if (
//             keccak256(abi.encodePacked(bio)) !=
//             keccak256(abi.encodePacked(user.bio))
//         ) {
//             user.bio = bio;
//         }
//         if (title != user.title) {
//             user.title = title;
//         }
//         if (handle != user.handle) {
//             user.handle = handle;
//         }
//     }

//     function startNextRace() external {
//         require(
//             userMap[msg.sender].userAddress != address(0),
//             "No User Account"
//         );
//         require(
//             msg.sender == userMap[msg.sender].userAddress,
//             "Not your account"
//         );
//         User memory user = userMap[msg.sender];
//         uint currentRace = user.raceId;
//         uint nextId = (_tokenIdCounter.current() + 1);
//         WarmUpNFT memory warmUp = WarmUpNFT({
//             userAddress: msg.sender,
//             currentTaskId: currentRace,
//             submittedAnswers: bytes32("0x"),
//             tokenId: nextId
//         });
//         warmUpNFTs[msg.sender] = warmUp;
//         tokenIdToRaceId[nextId] = currentRace;

//         if (balanceOf(msg.sender) == 0) {
//             safeMint(msg.sender);
//         } else {
//             require(
//                 balanceOf(msg.sender) == user.raceId,
//                 "Finish your active race first."
//             );
//             safeMint(msg.sender);
//         }
//     }

//     function submitCompletedTask(bytes32 answers, uint perf) external {
//         User storage user = userMap[msg.sender];
//         require(user.userAddress != address(0), "No User Account");
//         require(
//             balanceOf(msg.sender) != 0,
//             "cannot submit a task without the warmUp NFT"
//         );

//         WarmUpNFT memory warmUp = warmUpNFTs[msg.sender];

//         RaceNFT memory raceNFT = finalRaceNfts[warmUp.currentTaskId];

//         warmUp.submittedAnswers = answers;

//         if (answers != raceNFT.answer) {
//             revert IncorrectSubmission();
//         } else {
//             delete warmUpNFTs[msg.sender];
//             graduatedNFTs[warmUp.tokenId] = true;
//             user.raceId += 1;
//             user.completedTasks++;

//             uint currentPerformance = user.performance;
//             uint newPerformance = (currentPerformance + perf) /
//                 user.completedTasks;
//             user.performance = newPerformance;

//             RaceNFT memory completedNFT = RaceNFT({
//                 submittedAnswers: answers,
//                 answer: answers,
//                 performance: perf,
//                 currentTaskId: user.raceId,
//                 tokenId: warmUp.tokenId,
//                 userAddress: msg.sender
//             });

//             raceNFTs[msg.sender] = completedNFT;
//             userRaceNFTs[msg.sender].push(completedNFT);
//         }
//     }

//     function safeMint(address to) internal {
//         _tokenIdCounter.increment();
//         uint256 tokenId = _tokenIdCounter.current();
//         nftMap[tokenId] = to;
//         _safeMint(to, tokenId);
//     }

//     // The following functions are overrides required by Solidity.
//     // soulbound
//     function transferFrom(
//         address,
//         address,
//         uint256
//     ) public pure override(ERC721, IERC721) {
//         return;
//     }

//     function safeTransferFrom(
//         address,
//         address,
//         uint256
//     ) public pure override(ERC721, IERC721) {
//         return;
//     }

//     function _beforeTokenTransfer(
//         address from,
//         address to,
//         uint256 tokenId,
//         uint256 batchSize
//     ) internal override(ERC721, ERC721Enumerable) {
//         super._beforeTokenTransfer(from, to, tokenId, batchSize);
//     }

//     function supportsInterface(
//         bytes4 interfaceId
//     ) public view override(ERC721, ERC721Enumerable) returns (bool) {
//         return super.supportsInterface(interfaceId);
//     }
// }
