// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/automation/interfaces/KeeperCompatibleInterface.sol";

contract Bank is ReentrancyGuard, KeeperCompatibleInterface {
    // Mapping to track user balances
    mapping(address => uint256) public balances;

    // Event to emit when ETH is deposited
    event Deposit(address indexed user, uint256 amount);
    // Event to emit when ETH is withdrawn
    event Withdraw(address indexed user, uint256 amount);

    address public admin;
    uint256 public threshold;

    constructor(uint256 _threshold){
        admin = msg.sender;
        require(admin != address(0), "Invalid admin address");
        threshold = _threshold;
    }

    // Function for users to deposit ETH through a function call
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // receive() function to handle plain ETH transfers
    receive() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // fallback() function (optional, for catching calls with data)
    fallback() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Function for users to withdraw their ETH
    function withdraw(uint256 amount) public nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdraw(msg.sender, amount);
    }

    // function getTotalBalance() public view returns (uint256){
    //     return address(this).balance/ 1 ether;

    // }

    // // automation function
    // function sendHalfToAdmin() external returns (bool){
    //     uint256 halfBalance = address(this).balance / 2;
    //     require(halfBalance > 0, "Insufficient balance to send");
    //     (bool success, ) = admin.call{value: halfBalance}("");
    //     require(success, "Transfer to admin failed");
    //     return success;
    // }



 function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = address(this).balance/2 >= threshold;
        return (upkeepNeeded, "");

    }

    function performUpkeep(bytes calldata /* performData */) external override {
        uint256 halfBalance = address(this).balance / 2;
        require(halfBalance > 0, "Insufficient balance to send");
        (bool success, ) = admin.call{value: halfBalance}("");
        require(success, "Transfer to admin failed");

    }
    function setThreshold(uint256 _newThreshold) external {
        require(msg.sender == admin, "Only owner can set threshold");
        threshold = _newThreshold;
    }
}



    

