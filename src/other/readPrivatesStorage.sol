//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.0;

contract esRNT {
    struct LockInfo{
        address user;  //占一个slot
        uint64 startTime;  //占一个slot
        uint256 amount; //占一个slot
    }
    LockInfo[] private _locks; // slot=0, 数组

    constructor() { 
        for (uint256 i = 0; i < 11; i++) {
            _locks.push(LockInfo(address(uint160(i+1)), uint64(block.timestamp*2-i), 1e18*(i+1)));
        }
    }

    function read_slot(uint k) public view returns (bytes32 res) {
        assembly { res := sload(k) }
    }

    function cal_addr(uint k, uint p) public pure returns(bytes32 res) {
        res = keccak256(abi.encodePacked(k, p));
    }

    function cal_addr(uint p) public pure returns(bytes32 res) {
        res = keccak256(abi.encodePacked(p));
    }
}


