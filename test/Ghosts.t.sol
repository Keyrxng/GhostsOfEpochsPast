// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Ghosts.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {GhostsLib} from "../src/library/GhostsLib.sol";

contract GhostsTest is Test {
    Ghosts implV1;
    Ghosts wrappedProxyV1;
    Ghosts public ghosts;
    using Strings for uint;
    ERC1967Proxy internal proxy;
    using GhostsLib for GhostsLib.User;
    using GhostsLib for GhostsLib.UserFeats;
    using GhostsLib for GhostsLib.ProtocolMeta;
    using GhostsLib for GhostsLib.RaceNFT;
    using GhostsLib for GhostsLib.CollabNFT;
    using GhostsLib for GhostsLib.Feat;
    using GhostsLib for GhostsLib.MiniPost;

    address public user1;
    address public user2;
    address public user3;
    address public immutable user4 = 0x45484441b8f59a0245a71aa5437C994f982056C0;

    function setUp() public {
        bytes32[] memory answers = new bytes32[](5);
        answers[0] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        answers[1] = 0xbfa17807147311c915e5edfc6f73dc05a30eeda3aa16ce069a8b823a5ce31276;
        answers[2] = 0x47d6c2e892d5fcccee0f0f709099f4bede9338e572cd32b514241874300f777e;
        answers[3] = 0x048ad91aa2911660d1c9d2f885090ec56e3334cdb30970a7fc9fa7195f440cc4;
        answers[4] = 0x88ed3ec42dab95394f28600182a62493e05b714842e7f5cc236296486adb2a31;
        
        console2.log("msg.sender", msg.sender);
        console2.log("address(this)", address(this));
        console2.log("tx.origin", tx.origin);
        vm.startPrank(user4);

        console2.log("msg.sender", msg.sender);
        console2.log("address(this)", address(this));
        console2.log("tx.origin", tx.origin);
        bytes memory payload = abi.encodeWithSignature("initialize(bytes32[],string)", answers, "TESTETEST");


        implV1 = new Ghosts();
        proxy = new UUPSProxy(address(implV1), payload);
        wrappedProxyV1 = Ghosts(address(proxy));
        user1 = vm.addr(0x11);
        user2 = vm.addr(0x12);
        user3 = vm.addr(0x13);
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);

        string[] memory hashes = new string[](2);
        hashes[0] = 'avatarrr';
        hashes[1] = 'metadata';
        
        // wrappedProxyV1.ccGhostMaker("ghostssssssss", hashes, msg.sender);

        string[] memory hashess = new string[](8);
        hashess[0] = 'lol';
        hashess[1] = 'sdasd';
        hashess[2] = 'sdd';
        hashess[3] = 'dsa';
        hashess[4] = 'lol';
        hashess[5] = 'sdasd';
        hashess[6] = 'sdd';
        hashess[7] = 'dsa';
        // wrappedProxyV1.createFeats(bytes32("test"),bytes32("lol"), bytes32("test"),10, 1, 1);
    }

    // function test_CreateUser() external {
    //     string[] memory hashes = new string[](2
    // }

    function test_CreateUser() external {
        string[] memory hashes = new string[](2);
        hashes[0] = 'lol';
        hashes[1] = 'sdasd';
        console2.log("msg.sender", msg.sender);
        console2.log("tx.origin", tx.origin);
        console2.log("address(this)", address(this));
        wrappedProxyV1.createUser(msg.sender,"testinggggg", hashes, 0);
        wrappedProxyV1.startNextRace();

        // (address addr, uint raceId, uint collabId, uint comTask, uint perf, uint stbs, uint posts, uint contribs, uint ccID, uint ghostsID) = wrappedProxyV1.addrToUser(user4);
        // GhostsLib.User memory user = wrappedProxyV1.addrToUser(user4);

    }

    // function test_StartNextRace() external {
    //     string[] memory hashes = new string[](2);
    //     hashes[0] = 'lol';
    //     hashes[1] = 'sdasd';
    //     wrappedProxyV1.createUser("testinggggg", hashes);
    //     wrappedProxyV1.startNextRace();

    //     assertEq(raceId, 1);

    //     assertEq(wrappedProxyV1.balanceOf(user4), 1);
    // }

    // function test_SubmitRace() external {
    //     string[] memory hashes = new string[](2);
    //     hashes[0] = 'lol';
    //     hashes[1] = 'sdasd';
    //     wrappedProxyV1.createUser("testinggggg", hashes);
    //     wrappedProxyV1.startNextRace();
    //     string memory tokenURI = wrappedProxyV1.tokenURI(1);
    //     (,bytes32 a,,,,) = wrappedProxyV1.finalRaceNfts(1);
    //     (,bytes32 b,,,,) = wrappedProxyV1.finalRaceNfts(2);
    //     (, uint collabIdd, uint raceIdd,,,,,,,) = wrappedProxyV1.addrToUser(user4);

    //     wrappedProxyV1.submitCompletedTask(0xbfa17807147311c915e5edfc6f73dc05a30eeda3aa16ce069a8b823a5ce31276, 100);
    //     vm.warp(1);
    //     vm.roll(1);
    //     string memory tokenURINew = wrappedProxyV1.tokenURI(1);

    //     assertEq(tokenURI, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/WarmUpNFT1.json");
    //     assertEq(tokenURINew, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/RaceNFT1.json");

    //     wrappedProxyV1.startNextRace();

    //     string memory uriToken = wrappedProxyV1.tokenURI(2);

    //     (address addr,  uint raceId ,uint collabId, uint comTask, uint perf, uint stbs, uint posts, uint contribs, uint ccID, uint ghostsID) = wrappedProxyV1.addrToUser(user4);

    //     assertEq(uriToken, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/WarmUpNFT2.json");
    //     assertEq(wrappedProxyV1.balanceOf(user4), 2);
    //     assertEq(raceId, 2);
    //     assertEq(comTask, 1);
    //     assertEq(perf, 20);

    //     wrappedProxyV1.submitCompletedTask(0x47d6c2e892d5fcccee0f0f709099f4bede9338e572cd32b514241874300f777e, 100);
    //     string memory uriTokenNew = wrappedProxyV1.tokenURI(2);
    //     assertEq(uriTokenNew, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/RaceNFT2.json");
    //     (,,uint raceId1, ,,,, ,,) = wrappedProxyV1.addrToUser(user4);
    //     assertEq(raceId, 2);

    //     vm.expectRevert();
    //     wrappedProxyV1.submitCompletedTask(0x47d6c2e892d5fcccee0f0f709099f4bede9338e572cd32b514241874300f777e, 100);
        
    //     wrappedProxyV1.startNextRace();
        
    //     }

    // function test_AddRaces() external {
    //     string[] memory hashes = new string[](2);
    //     hashes[0] = 'lol';
    //     hashes[1] = 'sdasd';
    //     wrappedProxyV1.createUser("testinggggg", hashes); 
    //     bytes32[] memory ass = new bytes32[](2);
    //     ass[0] = 0xda6d4713cd0f9761c5b424bd121fa20ccd8996de39f8ef0277b45c6a9606dc3f;
    //     ass[1] = 0xec553c39b395ed4e9f6c6b782d68087d16410c651001f38b158de7b9703b52f6;
    //     wrappedProxyV1.addRaces(ass);

    //     ( bytes32 submittedAnswers,
    //     bytes32 answer,
    //     uint performance,
    //     uint currentTaskId,
    //     uint tokenId,
    //     address userAddress
    //     ) = wrappedProxyV1.finalRaceNfts(0);
    //     wrappedProxyV1.startNextRace();

    //     string memory tokenURI = wrappedProxyV1.tokenURI(1);


    //     wrappedProxyV1.submitCompletedTask(0xbfa17807147311c915e5edfc6f73dc05a30eeda3aa16ce069a8b823a5ce31276, 100);
    //     vm.warp(1);
    //     vm.roll(1);
    //     string memory tokenURINew = wrappedProxyV1.tokenURI(1);

    //     assertEq(tokenURI, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/WarmUpNFT1.json");
    //     assertEq(tokenURINew, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/RaceNFT1.json");

    //     vm.expectRevert();
    //     wrappedProxyV1.transferFrom(msg.sender, address(this), 1);
    //     vm.expectRevert();
    //     wrappedProxyV1.safeTransferFrom(msg.sender, user2, 1);
    //     assertEq(wrappedProxyV1.balanceOf(address(this)), 0);
    //     assertEq(wrappedProxyV1.balanceOf(user2), 0);

    //     wrappedProxyV1.startNextRace();
    //     wrappedProxyV1.submitCompletedTask(0x47d6c2e892d5fcccee0f0f709099f4bede9338e572cd32b514241874300f777e, 100);
        
    //     wrappedProxyV1.startNextRace();
    //     wrappedProxyV1.submitCompletedTask(0x048ad91aa2911660d1c9d2f885090ec56e3334cdb30970a7fc9fa7195f440cc4, 100);
        
    //     wrappedProxyV1.startNextRace();
    //     wrappedProxyV1.submitCompletedTask(0x88ed3ec42dab95394f28600182a62493e05b714842e7f5cc236296486adb2a31, 100);
    //     (,bytes32 nftAnswwer,,,,) = wrappedProxyV1.finalRaceNfts(5);

    //     wrappedProxyV1.startNextRace();
    //     vm.expectRevert();
    //     wrappedProxyV1.submitCompletedTask(0x0000000000000000000000000000000000000000000000000000000000000000, 100);

    //     assertEq(wrappedProxyV1.balanceOf(user4),5);
    //     wrappedProxyV1.submitCompletedTask(0xda6d4713cd0f9761c5b424bd121fa20ccd8996de39f8ef0277b45c6a9606dc3f, 100);

    //     assertEq(wrappedProxyV1.balanceOf(user4),5);

    //     wrappedProxyV1.startNextRace();
    //     wrappedProxyV1.submitCompletedTask(0xec553c39b395ed4e9f6c6b782d68087d16410c651001f38b158de7b9703b52f6, 100);

    //     assertEq(wrappedProxyV1.balanceOf(user4),6);
    // }

    // function test_SetURI() external {
    //     string[] memory hashes = new string[](2);
    //     hashes[0] = 'lol';
    //     hashes[1] = 'sdasd';
    //     wrappedProxyV1.createUser("testinggggg", hashes);
    //     wrappedProxyV1.startNextRace();
    //     (address addr, uint raceId, uint collabId, uint comTask, uint perf, uint stbs, uint posts, uint contribs, uint ccID, uint ghostsID) = wrappedProxyV1.addrToUser(user4);

    //     string memory oldUri = wrappedProxyV1.tokenURI(1);
    //     wrappedProxyV1.setBaseURI("www.ipfs.com/");
    //     string memory newUri = wrappedProxyV1.tokenURI(1);
    //     assertEq(oldUri, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/WarmUpNFT1.json");
    //     assertEq(newUri, "www.ipfs.com/WarmUpNFT1.json");
    // }

    // function test_AchievementCreated() external {
    //     string[] memory hashes = new string[](2);
    //     hashes[0] = 'lol';
    //     hashes[1] = 'sdasd';
    //     wrappedProxyV1.createUser('lollkdasajd', hashes);
    //     wrappedProxyV1.startNextRace();

    //     (,uint ccID,,,,,) = wrappedProxyV1.getUser(user4);

    //     (bytes memory name, bytes memory desc, bytes memory imageUrl, uint256 weight, uint256 essId, uint16 essTier, uint earnedAt) = wrappedProxyV1.feats(0);
        
    //     console2.log("name", string(name));
    //     console2.log("desc", string(desc));
    //     console2.log("imageUrl", string(imageUrl));
    //     console2.log("weight", weight);
    //     console2.log("essenceId", essId);
    //     console2.log("essenceTier", essTier);
    //     console2.log("earnedAt", earnedAt);

    //     // wrappedProxyV1.awardAchievements(user4, ccID);

    // }

    // function test_followUser() external {
    //     uint id = createUser("testinggggg");
    //     vm.roll(1);
    //     vm.warp(1);

    //     uint idd = createUser('asdawsadsadacdsvfdsd');
    //     vm.roll(1);
    //     vm.warp(1);

    //     assertTrue(id<idd);

    //     bool followed = wrappedProxyV1.followUser(id,idd, makeAddr('asdargdvfvs'));

    //     assertTrue(followed);

    //     (address addr, uint256 ccid, uint followC, uint followerC, uint commentC, uint consumeC, uint createC) = wrappedProxyV1.getUser(makeAddr('asdargdvfvs'));

    //     assertEq(followerC, 1);
    // }

    // function testRevert_followUser() external {
    //     uint id = createUser("testinggggg");
    //     vm.roll(1);
    //     vm.warp(1);

    //     uint idd = createUser('asdawsadsadacdsvfdsd');
    //     vm.roll(1);
    //     vm.warp(1);

    //     assertTrue(id<idd);

    //     bool followed = wrappedProxyV1.followUser(id,idd, makeAddr('asdargdvfvs'));

    //     assertTrue(followed);

    //     (address addr, uint256 ccid, uint followC, uint followerC, uint commentC, uint consumeC, uint createC) = wrappedProxyV1.getUser(makeAddr('asdargdvfvs'));

    //     assertEq(followerC, 1);

    //     vm.expectRevert();
    //     bool reFollow = wrappedProxyV1.followUser(id, idd, makeAddr('asdargdvfvs'));
    //     assertTrue(!reFollow);
    // }

    // function test_CreateContent() external {
    //     createUser("cscsb");
    //     address cscsb = makeAddr("cscsb");
        
    //     (,,,,,,uint createC) = wrappedProxyV1.getUser(cscsb);
    //     assertEq(createC, 0);
        
    //     wrappedProxyV1.createContent(1, "title", "disc", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);
    //     (,,,,,,uint newCreateC) = wrappedProxyV1.getUser(cscsb);
    //     assertEq(newCreateC, 1);
    // }

    // function test_Likes() external {
    //     createUser("cscsb");
    //     address cscsb = makeAddr("cscsb");
                

    //     (address addr ,,,,uint createC,,) = wrappedProxyV1.getUser(cscsb);
    //     assertEq(createC, 0);
        
    //     wrappedProxyV1.createContent(1, "title", "disc", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);

       
    //     wrappedProxyV1.likePost(1);
    //     wrappedProxyV1.dislikePost(1);

    //     IGhostsData.MiniPost memory post = wrappedProxyV1.getPost(1);
    //     assertEq(post.likes, 1);
    //     assertEq(post.dislikes, 1);

    //     console2.log("Verify post like/dislike count via getPost()");


    //     assertEq(wrappedProxyV1.getPostLikeCount(1),1);
    //     assertEq(wrappedProxyV1.getPostDislikeCount(1),1);

    //     console2.log("Verify post like/dislike count via getPostLike/dislikeCount()");
    // }

    // function test_Comments() external {
    //     createUser("cscsb");
    //     address cscsb = makeAddr("cscsb");
                

    //     (,,,,,,uint createC) = wrappedProxyV1.getUser(cscsb);
    //     assertEq(createC, 0);
        
    //     wrappedProxyV1.createContent(1, "title", "disc", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);

    //     createUser("test2eth");
    //     address test2 = makeAddr("test2eth");

    //     wrappedProxyV1.commentContent(bytes("This is such an awesome post bro!"), 1);
    //     wrappedProxyV1.commentContent(bytes("Seriously tho, this is such an awesome post bro!"), 1);
    //     bytes[] memory comments2 = wrappedProxyV1.getPostComments(1);

    //     (,,,,uint commC,,uint createC2) = wrappedProxyV1.getUser(test2);

    //     assertEq(comments2.length, 3);
    //     assertEq(commC, 2);
    //     console2.log(string(comments2[1]));
    //     console2.log(string(comments2[2]));
    // }

    // function test_LotsOfInteractions() external {
    //     makeLotsOfAccs(3);
    //     address test1 = makeAddr(string(abi.encodePacked("test",uint(0).toString(), "eth")));
    //     address test2 = makeAddr(string(abi.encodePacked("test",uint(1).toString(), "eth")));
    //     address test3 = makeAddr(string(abi.encodePacked("test",uint(2).toString(), "eth")));

    //     vm.stopPrank();
    //     vm.startPrank(test1);
    //     vm.roll(1);
    //     wrappedProxyV1.createContent(1, "title", "disc", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);
    //     wrappedProxyV1.createContent(1, "title1", "disc1", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);
    //     vm.roll(1);
    //     vm.roll(2);
        

    //     console2.log("test 1 created 2 nfts");
        
    //     vm.stopPrank();
    //     vm.startPrank(test3);
    //     wrappedProxyV1.commentContent(bytes("this is a comment on post 1"), 1);
    //     wrappedProxyV1.followUser(2, 3, test2);
    //     wrappedProxyV1.followUser(1, 3, test1);
        

    //     console2.log("test 3 commented and followed test 2 and 1");
    //     vm.roll(1);
    //     vm.warp(1);
    //     vm.stopPrank();
    //     vm.startPrank(test2);
    //     wrappedProxyV1.commentContent(bytes("this is a comment on post 1 of user 2"), 1);
    //     wrappedProxyV1.followUser(1, 2, test1);
    //     wrappedProxyV1.followUser(3, 2, test3);


    //     console2.log("test 2 commented and followed test 1 and 3");
        
    //     (,,uint folCount1,uint flrCount1,uint comCount,, uint createC) = wrappedProxyV1.getUser(test1);
    //     (,,uint folCount2,uint flrCount2,uint comCount2,,) = wrappedProxyV1.getUser(test2);
    //     (,,uint folCount3,uint flrCount3,uint comCount3,,) = wrappedProxyV1.getUser(test3);
        
    //     assertEq(createC, 2);

    //     assertEq(comCount, 0);
    //     assertEq(comCount2, 1);
    //     assertEq(comCount3, 1);

    //     console2.log("Post Comment Checks");
        
    //     assertEq(folCount1, 0);
    //     assertEq(folCount2, 2);
    //     assertEq(folCount3, 2);

    //     console2.log("Following Checks");

    //     assertEq(flrCount1, 2);
    //     assertEq(flrCount2, 1);
    //     assertEq(flrCount3, 1);

    //     console2.log("Follower Checks");

    //     console2.log("after test 2 interactions:");
    //     bytes[] memory comments1 = wrappedProxyV1.getPostComments(1);
    //     bytes[] memory comments2 = wrappedProxyV1.getPostComments(2);
    //     console2.log(string(comments1[1]));
    //     assertEq(comments1.length, 3);
    // }

    // function test_RunItUpTurbo() external {
    //     makeLotsOfAccs(6);
    //     address test1 = makeAddr(string(abi.encodePacked("test",uint(0).toString(), "eth")));
    //     address test2 = makeAddr(string(abi.encodePacked("test",uint(1).toString(), "eth")));
    //     address test3 = makeAddr(string(abi.encodePacked("test",uint(2).toString(), "eth")));

    //     wrappedProxyV1.createContent(3, "title1", "disc1", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);
    //     wrappedProxyV1.createContent(3, "title1", "disc1", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);
        
    //     wrappedProxyV1.commentContent(bytes("this is a comment on post 1"), 1);
    //     wrappedProxyV1.followUser(2, 3, test2);
    //     wrappedProxyV1.followUser(1, 3, test1);
        
    //     vm.stopPrank();
    //     vm.startPrank(test2);
    //     wrappedProxyV1.commentContent(bytes("this is a comment on post 1 of user 2"), 1);
    //     wrappedProxyV1.followUser(1, 2, test1);
    //     wrappedProxyV1.followUser(3, 2, test3);

    //     address test4 = makeAddr(string(abi.encodePacked("test",uint(3).toString(), "eth")));
    //     address test5 = makeAddr(string(abi.encodePacked("test",uint(4).toString(), "eth")));
    //     address test6 = makeAddr(string(abi.encodePacked("test",uint(5).toString(), "eth")));

    //     vm.stopPrank();
    //     vm.startPrank(test4);
    //     wrappedProxyV1.followUser(1, 4, test1);
    //     wrappedProxyV1.followUser(2, 4, test2);
    //     wrappedProxyV1.followUser(3, 4, test3);
    //     wrappedProxyV1.followUser(5, 4, test5);
    //     wrappedProxyV1.followUser(6, 4, test6);
    //     wrappedProxyV1.createContent(4, "title1", "disc1", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);
    //     wrappedProxyV1.likePost(1);
    //     wrappedProxyV1.likePost(2);
    //     wrappedProxyV1.commentContent("Nice Work!", 2);
    //     wrappedProxyV1.dislikePost(1);
    //     wrappedProxyV1.commentContent("Not my cup of Tea!", 1);

    //     (,,uint folCount3,uint flrCount3,uint comCount3,,) = wrappedProxyV1.getUser(test4);
    //     assertEq(folCount3, 5);
    //     assertEq(flrCount3, 0);
    //     assertEq(comCount3, 2);
    //     bytes[] memory comments2 = wrappedProxyV1.getPostComments(2);
    //     bytes[] memory comments1 = wrappedProxyV1.getPostComments(1);

    //     IGhostsData.MiniPost memory post  = wrappedProxyV1.getPost(1);
    //     assertEq(post.likes, 1);
    //     assertEq(post.dislikes, 1);
    //     console2.log(string(comments1[1]));
    //     console2.log(string(comments1[2]));
    //     console2.log(string(comments1[3]));
    //     // wrappedProxyV1.awardAchievements(test4, 4);
    // }

    // function test_AddCollab() external {
    //   string[] memory hashs = new string[](2);
    //     hashs[0] = 'lol';
    //     hashs[1] = 'sdasd';
    //     wrappedProxyV1.createUser('lollkdasajd', hashs);
    //     bytes32[] memory hashes = new bytes32[](4);
    //     hashes[0] = keccak256("test1");
    //     hashes[1] = keccak256("test2");
    //     hashes[2] = keccak256("test3");
    //     hashes[3] = keccak256("test4");

    //     bytes32[] memory hashes2 = new bytes32[](4);
    //     hashes2[0] = keccak256(abi.encodePacked(hashes[0]));
    //     hashes2[1] = keccak256(abi.encodePacked(hashes[1]));
    //     hashes2[2] = keccak256(abi.encodePacked(hashes[2]));
    //     hashes2[3] = keccak256(abi.encodePacked(hashes[3]));

        
    //     wrappedProxyV1.addCollab(hashes2, bytes("AUTHOR"), bytes("TITLE"));

    //     (bytes memory author, bytes memory title,,,,,) = wrappedProxyV1.collabNFTs(1);

    //     assertEq(string(title),"TITLE");
    //     assertEq(string(author),"AUTHOR");

    //     wrappedProxyV1.startNextCollab();

    //     wrappedProxyV1.submitCollab(hashes);

    //     (,,,,,uint stb,,uint contribs,,) = wrappedProxyV1.addrToUser(user4);

    //     assertEq(contribs, 1);

    //     assertEq(stb, 1);

    //     console2.log("it should succeed", stb == 1);

    // }

    // function makeLotsOfAccs(uint n) internal {
    //     for(uint i=0; i<n; i++) {
    //         createUser(string(abi.encodePacked("test",uint(i).toString(), "eth")));
    //     }
    // }


    // function createUser(string memory name) internal returns (uint) {
    //     vm.warp(1);
    //     vm.roll(1);
    //     string[] memory hashes = new string[](2);
    //     hashes[0] = "QmVySRNQ2vagMzF22YCc9ymCmm32aPQvTPxWNWTW8enpft";
    //     hashes[1] = "QmaEJ4R7D9UXz47JMndnj4jsMzoz3GhzZ3xqQEwiJYGaWp";
    //     vm.stopPrank();
    //     vm.startPrank(makeAddr(name));
    //     uint id = wrappedProxyV1.createUser(name, hashes);
    //     wrappedProxyV1.startNextRace();
    //     return id;
    // }

}
