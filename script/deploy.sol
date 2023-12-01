// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ghosts.sol";
import "../src/Byter.sol";

contract Deploy is Script {
    Ghosts ghosts;
    Byter byter;

    function run() external {
        bytes32[] memory stuff = new bytes32[](14);
        vm.startBroadcast();
        stuff[
            0
        ] = 0xbfa17807147311c915e5edfc6f73dc05a30eeda3aa16ce069a8b823a5ce31276;
        stuff[
            1
        ] = 0x47d6c2e892d5fcccee0f0f709099f4bede9338e572cd32b514241874300f777e;
        stuff[
            2
        ] = 0x048ad91aa2911660d1c9d2f885090ec56e3334cdb30970a7fc9fa7195f440cc4;
        stuff[
            3
        ] = 0x88ed3ec42dab95394f28600182a62493e05b714842e7f5cc236296486adb2a31;
        stuff[
            4
        ] = 0xda6d4713cd0f9761c5b424bd121fa20ccd8996de39f8ef0277b45c6a9606dc3f;
        stuff[
            5
        ] = 0xec553c39b395ed4e9f6c6b782d68087d16410c651001f38b158de7b9703b52f6;
        stuff[
            6
        ] = 0xeea717db0da955d7e34cd749936f277e99ba17d3e79fc6a9145e2a95738325bf;
        stuff[
            7
        ] = 0x8cfb4272968a634c7cdf9ca77c4f4f0425cb4c3de823d271200257430e124d05;
        stuff[
            8
        ] = 0x6ec95eec604583f8cbe3a3658b5d7f805eced24d6bdf11157c8d66e42433f887;
        stuff[
            9
        ] = 0xeb393972a363e77aef472ee138a6a386e8908120c859c8003dbd5314fbeeec42;
        stuff[
            10
        ] = 0xd80c49526cf27dace9f14b6311eb89ab04439c7662a51bbe228fcbbc4d29033c;
        stuff[
            11
        ] = 0x09b45c4e57f0b9735389c94aeaf4828f687cd4af00c08a4919b8f122d6c71da2;
        stuff[
            12
        ] = 0x514273d0ece6a1d98305d7116effbe9e390576da8e8c4b77c955aa482233fb75;
        stuff[
            13
        ] = 0x2ebc6a37eb6f508e09720ac97b8bd07b0e614153ad7d22ed23657143ebe86e51;

        ghosts = new Ghosts(stuff);

        vm.stopBroadcast();
    }
}
