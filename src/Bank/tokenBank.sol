// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "permit2/src/interfaces/IPermit2.sol";

interface IPermit2 {
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    } 

    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

   struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    function DOMAIN_SEPARATOR() external returns (bytes32);
}

contract TokenBank {
    using SafeERC20 for IERC20;
    // contructor 
    IPermit2 public immutable permit2; // 因为会固化，所以定义一个常量类型
    mapping(address => mapping(address =>uint256)) public balances;

 
    constructor (address _permit2){
        require(address(0) != _permit2);
        permit2 = IPermit2(_permit2);

    }

    function depositWithPermit2(
        IERC20 token, 
        uint256 amount,
        IPermit2.PermitTransferFrom calldata permit,  //可以直接用合约名称来调用其定义的数据类型
        bytes calldata signature
    ) public {
        uint256 balanceBefore = token.balanceOf(address(this)); // 用于检查结果
        {
            IPermit2.SignatureTransferDetails memory transferDetail = IPermit2.SignatureTransferDetails({
                to : address(this),
                requestedAmount : amount
            });
        
            permit2.permitTransferFrom(
                permit, 
                transferDetail, 
                msg.sender, //问题2：这里是owner是位置，怎么能是msg.sender? 明白了，这里是用户自己进行离线签名来存钱
                signature
            );

        }

        uint256 balanceAfter = token.balanceOf(address(this)); // 用于检查结果
        require(balanceAfter - balanceBefore == amount, "Invaild token transfer");
        balances[msg.sender][address(token)] += amount;

    }

    function withdraw(IERC20 token, uint256 amount) public {
        uint256 b = balances[msg.sender][address(token)];
        require(b >= amount, "insufficient balance");
        balances[msg.sender][address(token)] = b - amount;
        token.safeTransfer(msg.sender, amount);  // 问题1：这里不需要实例化一个SafeERC20 实例才可以调用方法吗，需要重新核实,已核查，库合约可以直接使用合约名称.方法的方式调用，其他不行
    } 



}