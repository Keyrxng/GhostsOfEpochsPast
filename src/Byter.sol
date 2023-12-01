pragma solidity ^0.8.0;

contract Byter {
    function getBytes1(uint num) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(uint(num)));
    }

    function getBytes2(uint num, uint numm) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(uint(num), uint(numm)));
    }

    function getBytes3(
        uint num,
        uint numm,
        uint nummm
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(uint(num), uint(numm), uint(nummm)));
    }

    function getBytes4(
        uint num,
        uint numm,
        uint nummm,
        uint nnum
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(uint(num), uint(numm), uint(nummm), uint(nnum))
            );
    }

    function getBytesFinal(
        bytes32 num,
        bytes32 numm,
        bytes32 nummm,
        bytes32 nnum,
        bytes32 num1,
        bytes32 numm1,
        bytes32 nummm1,
        bytes32 nnum1
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes32(num),
                    bytes32(numm),
                    bytes32(nummm),
                    bytes32(nnum),
                    bytes32(num1),
                    bytes32(numm1),
                    bytes32(nummm1),
                    bytes32(nnum1)
                )
            );
    }
}
