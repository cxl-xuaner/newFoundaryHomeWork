// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
// import "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;
    struct SellOrder {
        address seller;
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }
    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    // event OrderIdGenerated(bytes32 orderId);

    function test_Buy() public pure{
        SellOrder memory order = SellOrder({
            seller: address(0x223fda4356e528345B6B830F5014A2aCE0aD7e5F),
            nft: address(0x5e3c67585910b0881fD681CC3A5A4948845C3fd2),
            tokenId: 10,
            payToken: address(0x44a24f1B5DEb1CC4239bb30e94E835c129C69c51),
            price: 10,
            deadline: 1000000000000000
        });

        bytes32 orderId = keccak256(abi.encode(order));
        // emit OrderIdGenerated(orderId);
        // console.log(msg.sender);
        console.log("1111111111111111");
        console.logBytes32(orderId);
    }
}
