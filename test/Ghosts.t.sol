// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./mocks/Ghosts.sol";

contract GhostsTest is Test {
    Ghosts public ghosts;

    address public user1;
    address public user2;
    address public user3;
    address public user4;

    function setUp() public {
        user1 = vm.addr(0x11);
        user2 = vm.addr(0x12);
        user3 = vm.addr(0x13);
        user4 = vm.addr(0x14);
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);
        vm.startPrank(user1);
        
        bytes32[] memory answers = new bytes32[](10);
        answers[0] = 0xbfa17807147311c915e5edfc6f73dc05a30eeda3aa16ce069a8b823a5ce31276;
        answers[1] = 0x47d6c2e892d5fcccee0f0f709099f4bede9338e572cd32b514241874300f777e;
        answers[2] = 0x048ad91aa2911660d1c9d2f885090ec56e3334cdb30970a7fc9fa7195f440cc4;
        answers[3] = 0x88ed3ec42dab95394f28600182a62493e05b714842e7f5cc236296486adb2a31;

        ghosts = new Ghosts(answers);
        ghosts.setBaseURI("ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/");
    }

    function test_CreateUser() external {
        string[] memory hashes = new string[](2);
        hashes[0] = "QmVySRNQ2vagMzF22YCc9ymCmm32aPQvTPxWNWTW8enpft";
        hashes[1] = "QmaEJ4R7D9UXz47JMndnj4jsMzoz3GhzZ3xqQEwiJYGaWp";


        ghosts.createUser("Keyrxng", "awesome bio", "Web3 Pro", "@Keyrxng", hashes);

        (address addr, uint raceId, uint comTask, uint perf, uint stbs, uint posts, uint contribs, uint ccID) = ghosts.userMap(user1);

        assertEq(user1, addr);
        assertTrue(ccID != 0);
        console.log("ccId", ccID);
    }

    function test_StartNextRace() external {
        string[] memory hashes = new string[](2);
        hashes[0] = "QmVySRNQ2vagMzF22YCc9ymCmm32aPQvTPxWNWTW8enpft";
        hashes[1] = "QmaEJ4R7D9UXz47JMndnj4jsMzoz3GhzZ3xqQEwiJYGaWp";

        ghosts.createUser("Keyrxng", "awesome bio", "Web3 Pro", "@Keyrxng", hashes);
        ghosts.startNextRace();

        (address addr, uint raceId, uint comTask, uint perf, uint stbs, uint posts, uint contribs, uint ccID) = ghosts.userMap(user1);

        assertEq(raceId, 0);

        assertEq(ghosts.balanceOf(user1), 1);
    }

    function test_SubmitRace() external {
        string[] memory hashes = new string[](2);
        hashes[0] = "QmVySRNQ2vagMzF22YCc9ymCmm32aPQvTPxWNWTW8enpft";
        hashes[1] = "QmaEJ4R7D9UXz47JMndnj4jsMzoz3GhzZ3xqQEwiJYGaWp";

        ghosts.createUser("Keyrxng", "awesome bio", "Web3 Pro", "@Keyrxng", hashes);
        ghosts.startNextRace();
        string memory tokenURI = ghosts.tokenURI(1);

        ghosts.submitCompletedTask(0xbfa17807147311c915e5edfc6f73dc05a30eeda3aa16ce069a8b823a5ce31276, 100, 'lol');
        vm.warp(1);
        vm.roll(1);
        string memory tokenURINew = ghosts.tokenURI(1);

        assertEq(tokenURI, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/WarmUpNFT1.json");
        assertEq(tokenURINew, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/RaceNFT1.json");

        ghosts.startNextRace();

        string memory uriToken = ghosts.tokenURI(2);

        (address addr, uint raceId, uint comTask, uint perf, uint stbs, uint posts, uint contribs, uint ccID) = ghosts.userMap(user1);

        assertEq(uriToken, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/WarmUpNFT2.json");
        assertEq( ghosts.balanceOf(user1), 2);
        assertEq(raceId, 1);
        assertEq(comTask, 1);
        assertEq(perf, 100);

        ghosts.submitCompletedTask(0x47d6c2e892d5fcccee0f0f709099f4bede9338e572cd32b514241874300f777e, 100, 'lol');
        string memory uriTokenNew = ghosts.tokenURI(2);
        assertEq(uriTokenNew, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/RaceNFT2.json");

        vm.expectRevert();
        ghosts.submitCompletedTask(0x47d6c2e892d5fcccee0f0f709099f4bede9338e572cd32b514241874300f777e, 100, 'lol');

        ghosts.startNextRace();
        vm.expectRevert();
        ghosts.startNextRace();
    }

    function test_AddRaces() external {
        bytes32 a = keccak256(abi.encodePacked(
            bytes32(0x8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b),
            bytes32(0x392791df626408017a264f53fde61065d5a93a32b60171df9d8a46afdf82992d),
            bytes32(0x6e0c627900b24bd432fe7b1f713f1b0744091a646a9fe4a65a18dfed21f2949c),
            bytes32(0xa15bc60c955c405d20d9149c709e2460f1c2d9a497496a7f46004d1772c3054c),
            bytes32(0x6e0c627900b24bd432fe7b1f713f1b0744091a646a9fe4a65a18dfed21f2949c),
            bytes32(0x8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b),
            bytes32(0xc3a24b0501bd2c13a7e57f2db4369ec4c223447539fc0724a9d55ac4a06ebd4d),
            bytes32(0x405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace)
        ));
        bytes32 aa = keccak256(abi.encodePacked(
            bytes32(0xa15bc60c955c405d20d9149c709e2460f1c2d9a497496a7f46004d1772c3054c),
            bytes32(0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0),
            bytes32(0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6),
            bytes32(0xc3a24b0501bd2c13a7e57f2db4369ec4c223447539fc0724a9d55ac4a06ebd4d),
            bytes32(0xc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b),
            bytes32(0xc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b),
            bytes32(0xc3a24b0501bd2c13a7e57f2db4369ec4c223447539fc0724a9d55ac4a06ebd4d),
            bytes32(0x6e0c627900b24bd432fe7b1f713f1b0744091a646a9fe4a65a18dfed21f2949c)
        ));

        bytes32[] memory ass = new bytes32[](2);
        ass[0] = a;
        ass[1] = aa;

        ghosts.addRaces(ass, 0);

        ( bytes32 submittedAnswers,
        bytes32 answer,
        uint performance,
        uint currentTaskId,
        uint tokenId,
        address userAddress
        ) = ghosts.finalRaceNfts(0);

        string[] memory hashes = new string[](2);
        hashes[0] = "QmVySRNQ2vagMzF22YCc9ymCmm32aPQvTPxWNWTW8enpft";
        hashes[1] = "QmaEJ4R7D9UXz47JMndnj4jsMzoz3GhzZ3xqQEwiJYGaWp";

        ghosts.createUser("Keyrxng", "awesome bio", "Web3 Pro", "@Keyrxng", hashes);
        ghosts.startNextRace();
        string memory tokenURI = ghosts.tokenURI(1);

        bytes32 ans = keccak256(abi.encodePacked(
            bytes32(0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0),
            bytes32(0xa15bc60c955c405d20d9149c709e2460f1c2d9a497496a7f46004d1772c3054c),
            bytes32(0x6e0c627900b24bd432fe7b1f713f1b0744091a646a9fe4a65a18dfed21f2949c),
            bytes32(0x2e174c10e159ea99b867ce3205125c24a42d128804e4070ed6fcc8cc98166aa0),
            bytes32(0x8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b),
            bytes32(0xa15bc60c955c405d20d9149c709e2460f1c2d9a497496a7f46004d1772c3054c),
            bytes32(0x405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace),
            bytes32(0xc3a24b0501bd2c13a7e57f2db4369ec4c223447539fc0724a9d55ac4a06ebd4d)
        ));

        ghosts.submitCompletedTask(ans, 100, 'lol');
        vm.warp(1);
        vm.roll(1);
        string memory tokenURINew = ghosts.tokenURI(1);

        assertEq(tokenURI, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/WarmUpNFT1.json");
        assertEq(tokenURINew, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/RaceNFT1.json");

        ghosts.transferFrom(msg.sender, address(this), 1);
        ghosts.safeTransferFrom(msg.sender, user2, 1);
        assertEq(ghosts.balanceOf(address(this)), 0);
        assertEq(ghosts.balanceOf(user2), 0);
    }

    function test_SetURI() external {
        string[] memory hashes = new string[](2);
        hashes[0] = "QmVySRNQ2vagMzF22YCc9ymCmm32aPQvTPxWNWTW8enpft";
        hashes[1] = "QmaEJ4R7D9UXz47JMndnj4jsMzoz3GhzZ3xqQEwiJYGaWp";


        ghosts.createUser("Keyrxng", "awesome bio", "Web3 Pro", "@Keyrxng", hashes);
        ghosts.startNextRace();

        (address addr, uint raceId, uint comTask, uint perf, uint stbs, uint posts, uint contribs, uint ccID) = ghosts.userMap(user1);

        string memory oldUri = ghosts.tokenURI(1);
        ghosts.setBaseURI("www.ipfs.com/");
        string memory newUri = ghosts.tokenURI(1);
        assertEq(oldUri, "ipfs://QmU3hHax9mtBJcWD3JvS2uDSdpvjATCWkdR3kwxEfg54bw/WarmUpNFT1.json");
        assertEq(newUri, "www.ipfs.com/WarmUpNFT1.json");
    }



}
