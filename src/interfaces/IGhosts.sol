// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGhosts {
   
    struct User {
        address userAddress; // user address
        uint raceId; // the race they are currently on
        uint completedTasks; // completed tasks
        uint performance; // a percentage based on previous task performance
        uint spotTheBugs; // completed spot the bugs tasks
        uint contentPosts; // content posted
        uint ctfStbContribs; // CTF or STB contributions made
        uint ccID; // their CC id
        uint ghostsID; // their Ghosts id
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

        function createUser(string memory handle, string[] memory hashes) external;
        function startNextRace() external;
        function submitCompletedTask(bytes32 answers, uint perf, string calldata metadata) external;
        function getUser(address who) external returns(User memory);

    }