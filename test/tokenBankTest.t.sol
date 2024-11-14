// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import  "../src/Bank/tokenBankWithPermit.sol";
// import "permit2/src/interfaces/IPermit2.sol"; 
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 0x000000000022D473030F116dDEE9F6B43aC78BA3  sepolia permit2 contract

// 遗留问题，对于多层引用的接口类型，在当前合约无法识别

contract TokenBankTest is Test {
    TokenBank public bank;
    address private alice;
    uint256 private pk;
    MockERC20 private kk;
    
   
    
    struct outParams {
        IERC20 token; 
        uint256 amount;
        IPermit2.PermitTransferFrom permit;
        bytes signature;
    }

    address public permit2Sepolia = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
             

    function setUp() public {
        require(block.chainid == 11155111, "Only support sepolia");
        bank = new TokenBank(permit2Sepolia); // 注意，这里是创建了一个新的合约实例，括号内的地址是构造函数的参数，返回的是一个新的合约实例，并不是合约调用，如果没有new就是合约调用
        (alice, pk) = makeAddrAndKey("alice");
        kk = deployMockERC20("kkk", "aa", 18);
        deal(address(kk), alice, 1000 * 1e18);
        vm.prank(alice);
        kk.approve(permit2Sepolia, type(uint256).max);
    }

    function test_deposit()public {

        // 2 alice permit
        vm.prank(alice);
        outParams memory params = signToPermit(pk, address(kk), 100, IPermit2(permit2Sepolia).DOMAIN_SEPARATOR());

 
        // 3 alice deposit
        vm.prank(alice);
        bank.depositWithPermit2(
            params.token,
            params.amount,
            params.permit,
            params.signature
        );
        console.log("b1:",bank.balances(alice,address(kk)));
        assertEq(bank.balances(alice,address(kk)),100);

    }

    function signToPermit(uint256 privateKey, address token, uint256 amount, bytes32 domainSeparator) private view returns (outParams memory){

        IPermit2.PermitTransferFrom memory permit =IPermit2.PermitTransferFrom({
            permitted:IPermit2.TokenPermissions({
                token:token,
                amount:amount
            }),
            nonce:block.timestamp,
            deadline:block.timestamp + 1 hours

        });

        bytes32 _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
            "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
        );
        bytes32 _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

        bytes32 tokenPermissions = keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permit.permitted));
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        _PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissions, address(bank), permit.nonce, permit.deadline
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        bytes memory signature = bytes.concat(r, s, bytes1(v));

        return outParams({
            token:IERC20(token), 
            amount:amount,
            permit:permit,
            signature:signature
        });

    } 

    // 注意每个测试用例都是分开的，所以状态不能继承，切记
    function test_withdraw() public{
        // vm.prank(alice);
        test_deposit();
        
        console.log("b2:",bank.balances(alice,address(kk)));
        console.log("BANK:",kk.balanceOf(address(bank)));
        vm.prank(alice);
        bank.withdraw(IERC20(address(kk)), 100);
        assertEq(bank.balances(alice,address(kk)),0);


    }
}
