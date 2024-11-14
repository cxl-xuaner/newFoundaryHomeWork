// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/DEX/myDex.sol";

contract MD is Test {
    address wethaddr;
    address univ2addr;
    MyDex myDex;


    // WETH:0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // UNISWAP ROUTER:0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    function setUp() public {
        univ2addr = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        wethaddr = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        myDex = new MyDex(univ2addr, wethaddr);

    }

    function test_sellETH() public {
        // address alice = makeAddr("alice");
        IERC20 token = IERC20(0x3b991130eaE3CcA364406D718DA22FA1C3E7C256);
        address alice = address(0x70DE3c3AB1A396cd6EA86D999506a2762a011e93);
        // console.log('balance:',address(0x70DE3c3AB1A396cd6EA86D999506a2762a011e93).balance);
        vm.startPrank(alice);
        
        // token.approve(univ2addr,type(uint256).max);
        myDex.sellETH{value:10000000000000001}(
            address(token),
            100
        );
        console.log("alice:",token.balanceOf(alice));

        token.approve(address(myDex),type(uint256).max);

        myDex.buyETH(
                address(token),
                token.balanceOf(alice)/2,
                0
        );

        console.log(token.balanceOf(alice));

        vm.stopPrank();
        
        // console.log(token.balanceOf(address(0x70DE3c3AB1A396cd6EA86D999506a2762a011e93)));

        

    }
   
}
