// SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../ERC20Token/MyToken.sol";

// 预售价格:0.0001 ETH
// 预售数量:100万 RNT
// 预售门槛:单笔最低买入 0.01 ETH，单个地址最高买入 0.1 ETH募集目标:0.0001*1000000=100ETH，最多 200ETH

contract IDO {

    mapping(address => uint) public balances;
    address payable public admin;
    uint public immutable startTime;
    uint public immutable endTime;
    uint public constant TOTAL_APPLY = 1e7;
    uint public constant MIN_PRESALE = 0.01 ether;  
    uint public constant MAX_PRESALE = 0.1 ether; 
    uint public constant PRESALE_PRICE = 0.0001 ether; 
    uint public constant EXPECT_MIN_ETH = 100 ether; 
    uint public constant EXPECT_MAX_ETH = 200 ether; 
    uint public totalETH;
    MyToken public preToken;

    constructor(
        uint _duration,
        address _preToken
    ){
        admin = payable(msg.sender);
        startTime = block.timestamp;
        endTime = startTime + _duration;
        preToken = MyToken(_preToken);

    }

    modifier onlyAdmin {
        require(msg.sender == admin, "onlyAdmin");
        _;
    }

    modifier onlyActive() {
        require(block.timestamp <= endTime && block.timestamp >= startTime, "Presale ended");
        _;
    }

    modifier hasEnded() {
        require(block.timestamp > endTime, "Presale not ended");
        _;

    }

    modifier mumPresale() {
        require(msg.value >= MIN_PRESALE && msg.value <= MAX_PRESALE, "more than mininum or maxnum presale");
        _;
    }

    /// @notice need presale is not ended and presale is not enough 
    /// @return bool
    function presale() external payable onlyActive mumPresale returns(bool){
        require((totalETH + msg.value) <= EXPECT_MAX_ETH, "exceeds maxlimit");
        balances[msg.sender] += msg.value;
        totalETH += msg.value;
        return true;
    }

    /// @notice this function need sender participated presale and presale success,
    /// @notice The current contract must hold more than presaleAmountToken tokens
    /// @return bool
    function claim() external hasEnded returns(bool){
        require(balances[msg.sender] > 0, "did not participate in the presale");
        require(totalETH >= EXPECT_MIN_ETH, "Presale failed");
        uint amountOut = TOTAL_APPLY * balances[msg.sender] / totalETH;
        balances[msg.sender] = 0;
        preToken.transfer(msg.sender, amountOut);  
        return true;
    }

    /// @notice presale is success
    /// @return bool
    function withdraw() external onlyAdmin hasEnded returns(bool) {
        require(totalETH >= EXPECT_MIN_ETH, "Presale failed");
        uint toTeamETH = totalETH * 1 / 10;
        (bool success,) = admin.call{value:toTeamETH}("");
        return success;
    }

    /// @notice presale was failed
    function refund() external hasEnded returns(bool){
        require(totalETH < EXPECT_MIN_ETH, "Presale success,do not permit refund");
        (bool success,) = msg.sender.call{value:balances[msg.sender]}("");
        require(success, "refund failed");
        return success;
    }

    /// @notice check in and out preAmount
    /// @param eths is ether
    /// @return preAmount
    function estAmount(uint eths) external pure returns (uint) {
        return eths / PRESALE_PRICE;
    }


}