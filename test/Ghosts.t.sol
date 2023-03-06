// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./mocks/Ghosts.sol";

contract GhostsTest is Test {
    Ghosts public ghosts;

    address public user1;
    address public user2;
    address public user3;
    address public immutable user4 = 0x45484441b8f59a0245a71aa5437C994f982056C0;

    function setUp() public {
        user1 = vm.addr(0x11);
        user2 = vm.addr(0x12);
        user3 = vm.addr(0x13);
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);
        
        bytes32[] memory answers = new bytes32[](4);
        answers[0] = 0xbfa17807147311c915e5edfc6f73dc05a30eeda3aa16ce069a8b823a5ce31276;
        answers[1] = 0x47d6c2e892d5fcccee0f0f709099f4bede9338e572cd32b514241874300f777e;
        answers[2] = 0x048ad91aa2911660d1c9d2f885090ec56e3334cdb30970a7fc9fa7195f440cc4;
        answers[3] = 0x88ed3ec42dab95394f28600182a62493e05b714842e7f5cc236296486adb2a31;
        vm.startPrank(user4);
        ghosts = new Ghosts(answers);
        string[] memory hashes = new string[](8);
        hashes[0] = 'lol';
        hashes[1] = 'sdasd';
        ghosts.ccGhostMaker("GHOSTS", hashes);


        string[] memory hashess = new string[](8);
        hashes[0] = 'lol';
        hashes[1] = 'sdasd';
        hashes[2] = 'sdd';
        hashes[3] = 'dsa';
        hashes[4] = 'lol';
        hashes[5] = 'sdasd';
        hashes[6] = 'sdd';
        hashes[7] = 'dsa';
        ghosts.ccAchievementMaker("test", "test", hashess, "desc", 10, 1);

    }

    function test_CreateUser() external {
        string[] memory hashes = new string[](8);
        hashes[0] = 'lol';
        hashes[1] = 'sdasd';
        ghosts.createUser("TEST1", hashes);
        ghosts.startNextRace();

        (address addr, uint raceId, uint comTask, uint perf, uint stbs, uint posts, uint contribs, uint ccID, uint ghostsID) = ghosts.userMap(user4);

        assertEq(addr, user4);
        assertTrue(ccID != 0);
        console.log("ccId", ccID);
    }

    function test_StartNextRace() external {
                string[] memory hashes = new string[](8);
        hashes[0] = 'lol';
        hashes[1] = 'sdasd';
        ghosts.createUser("TEST1", hashes);
        ghosts.startNextRace();
        (address addr, uint raceId, uint comTask, uint perf, uint stbs, uint posts, uint contribs, uint ccID, uint ghostsID) = ghosts.userMap(user4);

        assertEq(raceId, 0);

        assertEq(ghosts.balanceOf(user4), 1);
    }

    function test_SubmitRace() external {
        string[] memory hashes = new string[](8);
        hashes[0] = 'lol';
        hashes[1] = 'sdasd';
        ghosts.createUser("TEST1", hashes);
        ghosts.startNextRace();
        string memory tokenURI = ghosts.tokenURI(1);

        ghosts.submitCompletedTask(0xbfa17807147311c915e5edfc6f73dc05a30eeda3aa16ce069a8b823a5ce31276, 100);
        vm.warp(1);
        vm.roll(1);
        string memory tokenURINew = ghosts.tokenURI(1);

        assertEq(tokenURI, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/WarmUpNFT1.json");
        assertEq(tokenURINew, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/RaceNFT1.json");

        ghosts.startNextRace();

        string memory uriToken = ghosts.tokenURI(2);

        (address addr, uint raceId, uint comTask, uint perf, uint stbs, uint posts, uint contribs, uint ccID, uint ghostsID) = ghosts.userMap(user4);

        assertEq(uriToken, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/WarmUpNFT2.json");
        assertEq( ghosts.balanceOf(user4), 2);
        assertEq(raceId, 1);
        assertEq(comTask, 1);
        assertEq(perf, 25);

        ghosts.submitCompletedTask(0x47d6c2e892d5fcccee0f0f709099f4bede9338e572cd32b514241874300f777e, 100);
        string memory uriTokenNew = ghosts.tokenURI(2);
        assertEq(uriTokenNew, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/RaceNFT2.json");

        vm.expectRevert();
        ghosts.submitCompletedTask(0x47d6c2e892d5fcccee0f0f709099f4bede9338e572cd32b514241874300f777e, 100);
        
        ghosts.startNextRace();
        
        }

    function test_AddRaces() external {
        string[] memory hashes = new string[](8);
        hashes[0] = 'lol';
        hashes[1] = 'sdasd';
        ghosts.createUser("TEST1", hashes); 
        bytes32[] memory ass = new bytes32[](2);
        ass[0] = 0xda6d4713cd0f9761c5b424bd121fa20ccd8996de39f8ef0277b45c6a9606dc3f;
        ass[1] = 0xec553c39b395ed4e9f6c6b782d68087d16410c651001f38b158de7b9703b52f6;
        ghosts.addRaces(ass);

        ( bytes32 submittedAnswers,
        bytes32 answer,
        uint performance,
        uint currentTaskId,
        uint tokenId,
        address userAddress
        ) = ghosts.finalRaceNfts(0);
        ghosts.startNextRace();

        string memory tokenURI = ghosts.tokenURI(1);


        ghosts.submitCompletedTask(0xbfa17807147311c915e5edfc6f73dc05a30eeda3aa16ce069a8b823a5ce31276, 100);
        vm.warp(1);
        vm.roll(1);
        string memory tokenURINew = ghosts.tokenURI(1);

        assertEq(tokenURI, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/WarmUpNFT1.json");
        assertEq(tokenURINew, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/RaceNFT1.json");

        ghosts.transferFrom(msg.sender, address(this), 1);
        ghosts.safeTransferFrom(msg.sender, user2, 1);
        assertEq(ghosts.balanceOf(address(this)), 0);
        assertEq(ghosts.balanceOf(user2), 0);

        ghosts.startNextRace();
        ghosts.submitCompletedTask(0x47d6c2e892d5fcccee0f0f709099f4bede9338e572cd32b514241874300f777e, 100);
        
        ghosts.startNextRace();
        ghosts.submitCompletedTask(0x048ad91aa2911660d1c9d2f885090ec56e3334cdb30970a7fc9fa7195f440cc4, 100);
        
        ghosts.startNextRace();
        ghosts.submitCompletedTask(0x88ed3ec42dab95394f28600182a62493e05b714842e7f5cc236296486adb2a31, 100);
        (,bytes32 nftAnswwer,,,,) = ghosts.finalRaceNfts(5);

                ghosts.startNextRace();
        vm.expectRevert();
        ghosts.submitCompletedTask(0x0000000000000000000000000000000000000000000000000000000000000000, 100);

        assertEq(ghosts.balanceOf(user4),5);
    }

    function test_SetURI() external {
        string[] memory hashes = new string[](8);
        hashes[0] = 'lol';
        hashes[1] = 'sdasd';
        ghosts.createUser("TEST1", hashes);
        ghosts.startNextRace();
        (address addr, uint raceId, uint comTask, uint perf, uint stbs, uint posts, uint contribs, uint ccID, uint ghostsID) = ghosts.userMap(user4);

        string memory oldUri = ghosts.tokenURI(1);
        ghosts.setBaseURI("www.ipfs.com/");
        string memory newUri = ghosts.tokenURI(1);
        assertEq(oldUri, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/WarmUpNFT1.json");
        assertEq(newUri, "www.ipfs.com/WarmUpNFT1.json");
    }

    // function test_AchievementCreated() external {
    //     string[] memory hashes = new string[](2);
    //     hashes[0] = 'lol';
    //     hashes[1] = 'sdasd';
    //     ghosts.createUser('lollkdasajd', hashes);
    //     ghosts.startNextRace();

    //     (,uint ccID,,,,,) = ghosts.getUser(user4);

    //     address essenceAddr = ghosts.ccGetEssNFTAddr(ccID, 1);

    //     (bytes memory name, bytes memory desc, bytes memory imageUrl, uint256 weight, uint256 essId, uint16 essTier, uint earnedAt) = ghosts.feats(0);
        
    //     console.log("name", string(name));
    //     console.log("desc", string(desc));
    //     console.log("imageUrl", string(imageUrl));
    //     console.log("weight", weight);
    //     console.log("essenceId", essId);
    //     console.log("essenceTier", essTier);
    //     console.log("earnedAt", earnedAt);
    //     console.log("essenceAddr", essenceAddr);

    //     assertTrue(essenceAddr != address(0));

    //     ghosts.awardAchievements(user4, ccID);

    // }

    function test_followUser() external {
        uint id = createUser("TEST1");
        vm.roll(1);
        vm.warp(1);

        uint idd = createUser('asdawsadsadacdsvfdsd');
        vm.roll(1);
        vm.warp(1);

        assertTrue(id<idd);

        bool followed = ghosts.followUser(id,idd, makeAddr('asdargdvfvs'));

        assertTrue(followed);

        (address addr, uint256 ccid, uint followC, uint followerC, uint commentC, uint consumeC, uint createC) = ghosts.getUser(makeAddr('asdargdvfvs'));

        assertEq(followerC, 1);

        vm.expectRevert();
        bool reFollow = ghosts.followUser(id, idd, makeAddr('asdargdvfvs'));
        assertTrue(!reFollow);
    }

    function test_CreateContent() external {
        createUser("cscsb");
        address cscsb = makeAddr("cscsb");
        
        (,,,,,,uint createC) = ghosts.getUser(cscsb);
        assertEq(createC, 0);
        
        ghosts.createContent(1, "title", "disc", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);
        (,,,,,,uint newCreateC) = ghosts.getUser(cscsb);
        assertEq(newCreateC, 1);
    }

    function test_Likes() external {
        createUser("cscsb");
        address cscsb = makeAddr("cscsb");
                

        (address addr ,,,,uint createC,,) = ghosts.getUser(cscsb);
        assertEq(createC, 0);
        
        ghosts.createContent(1, "title", "disc", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);

        (,,,,,,uint newCreateC) = ghosts.getUser(cscsb);
        assertEq(newCreateC, 1);

        ghosts.likePost(1);
        ghosts.dislikePost(1);

        IGhostsData.MiniPost memory post = ghosts.getPost(1);
        assertEq(post.likes, 1);
        assertEq(post.dislikes, 1);

        assertEq(ghosts.getPostLikeCount(1),1);
        assertEq(ghosts.getPostDislikeCount(1),1);
    }

    function test_Comments() external {
        createUser("cscsb");
        address cscsb = makeAddr("cscsb");
                

        (,,,,,,uint createC) = ghosts.getUser(cscsb);
        assertEq(createC, 0);
        
        ghosts.createContent(1, "title", "disc", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);

        createUser("TEST2");
        address test2 = makeAddr("TEST2");

        ghosts.commentContent(bytes("This is such an awesome post bro!"), 1);
        ghosts.commentContent(bytes("Seriously tho, this is such an awesome post bro!"), 1);
        bytes[] memory comments2 = ghosts.getPostComments(1);

        (,,,,uint commC,,uint createC2) = ghosts.getUser(test2);

        assertEq(comments2.length, 3);
        assertEq(commC, 2);
        console.log(string(comments2[1]));
        console.log(string(comments2[2]));
    }

    function test_LotsOfInteractions() external {
        makeLotsOfAccs(3);
        address test1 = makeAddr(string(abi.encodePacked("TEST",uint(0))));
        address test2 = makeAddr(string(abi.encodePacked("TEST",uint(1))));
        address test3 = makeAddr(string(abi.encodePacked("TEST",uint(2))));

        vm.stopPrank();
        vm.startPrank(test1);
        vm.roll(1);
        ghosts.createContent(1, "title", "disc", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);
        ghosts.createContent(1, "title1", "disc1", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);
        vm.roll(1);
        vm.roll(2);
        

        console.log("test 1 created 2 nfts");
        
        vm.stopPrank();
        vm.startPrank(test3);
        ghosts.commentContent(bytes("this is a comment on post 1"), 1);
        ghosts.followUser(2, 3, test2);
        ghosts.followUser(1, 3, test1);
        

        console.log("test 3 commented and followed test 2 and 1");
        vm.roll(1);
        vm.warp(1);
        vm.stopPrank();
        vm.startPrank(test2);
        ghosts.commentContent(bytes("this is a comment on post 1 of user 2"), 1);
        ghosts.followUser(1, 2, test1);
        ghosts.followUser(3, 2, test3);


        console.log("test 2 commented and followed test 1 and 3");
        
        (,,uint folCount1,uint flrCount1,uint comCount,, uint createC) = ghosts.getUser(test1);
        (,,uint folCount2,uint flrCount2,uint comCount2,,) = ghosts.getUser(test2);
        (,,uint folCount3,uint flrCount3,uint comCount3,,) = ghosts.getUser(test3);
        
        assertEq(createC, 2);

        assertEq(comCount, 0);
        assertEq(comCount2, 1);
        assertEq(comCount3, 1);

        console.log("Post Comment Checks");
        
        assertEq(folCount1, 0);
        assertEq(folCount2, 2);
        assertEq(folCount3, 2);

        console.log("Following Checks");

        assertEq(flrCount1, 2);
        assertEq(flrCount2, 1);
        assertEq(flrCount3, 1);

        console.log("Follower Checks");

        console.log("after test 2 interactions:");
        bytes[] memory comments1 = ghosts.getPostComments(1);
        bytes[] memory comments2 = ghosts.getPostComments(2);
        console.log(string(comments1[1]));
        assertEq(comments1.length, 3);
    }

    function test_RunItUpTurbo() external {
        makeLotsOfAccs(6);
        address test1 = makeAddr(string(abi.encodePacked("TEST",uint(0))));
        address test2 = makeAddr(string(abi.encodePacked("TEST",uint(1))));
        address test3 = makeAddr(string(abi.encodePacked("TEST",uint(2))));

        ghosts.createContent(3, "title1", "disc1", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);
        ghosts.createContent(3, "title1", "disc1", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);
        
        ghosts.commentContent(bytes("this is a comment on post 1"), 1);
        ghosts.followUser(2, 3, test2);
        ghosts.followUser(1, 3, test1);
        
        vm.stopPrank();
        vm.startPrank(test2);
        ghosts.commentContent(bytes("this is a comment on post 1 of user 2"), 1);
        ghosts.followUser(1, 2, test1);
        ghosts.followUser(3, 2, test3);

        address test4 = makeAddr(string(abi.encodePacked("TEST",uint(3))));
        address test5 = makeAddr(string(abi.encodePacked("TEST",uint(4))));
        address test6 = makeAddr(string(abi.encodePacked("TEST",uint(5))));

        vm.stopPrank();
        vm.startPrank(test4);
        ghosts.followUser(1, 4, test1);
        ghosts.followUser(2, 4, test2);
        ghosts.followUser(3, 4, test3);
        ghosts.followUser(5, 4, test5);
        ghosts.followUser(6, 4, test6);
        ghosts.createContent(4, "title1", "disc1", "QmZauYYd6b9X7Vvud6RCusW7ntN3rRDkU6zvU6pScW8xxE", address(0), true, true, true);
        ghosts.likePost(1);
        ghosts.likePost(2);
        ghosts.commentContent("Nice Work!", 2);
        ghosts.dislikePost(1);
        ghosts.commentContent("Not my cup of Tea!", 1);

        (,,uint folCount3,uint flrCount3,uint comCount3,,) = ghosts.getUser(test4);
        assertEq(folCount3, 5);
        assertEq(flrCount3, 0);
        assertEq(comCount3, 2);
        bytes[] memory comments2 = ghosts.getPostComments(2);
        bytes[] memory comments1 = ghosts.getPostComments(1);

        IGhostsData.MiniPost memory post  = ghosts.getPost(1);
        assertEq(post.likes, 1);
        assertEq(post.dislikes, 1);
        console.log(string(comments1[1]));
        console.log(string(comments1[2]));
        console.log(string(comments1[3]));
        // ghosts.awardAchievements(test4, 4);
    }

    function makeLotsOfAccs(uint n) internal {
        for(uint i=0; i<n; i++) {
            createUser(string(abi.encodePacked("TEST",uint(i))));
        }
    }


    function createUser(string memory name) internal returns (uint) {
        vm.warp(1);
        vm.roll(1);
        string[] memory hashes = new string[](2);
        hashes[0] = "QmVySRNQ2vagMzF22YCc9ymCmm32aPQvTPxWNWTW8enpft";
        hashes[1] = "QmaEJ4R7D9UXz47JMndnj4jsMzoz3GhzZ3xqQEwiJYGaWp";
        vm.stopPrank();
        vm.startPrank(makeAddr(name));
        uint id = ghosts.createUser(name, hashes);
        ghosts.startNextRace();
        return id;
    }

}
