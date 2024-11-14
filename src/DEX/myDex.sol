//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface UniswapV2 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
}


contract MyDex {

    UniswapV2 uni;
    address public WETH;
    constructor(address _uni,address _WETH){
        uni = UniswapV2(_uni);
        WETH = _WETH;

    }
    
        /**
     * @dev 卖出ETH，兑换成 buyToken
     *      msg.value 为出售的ETH数量
     * @param buyToken 兑换的目标代币地址
     * @param minBuyAmount 要求最低兑换到的 buyToken 数量
     */
    function sellETH(address buyToken,uint256 minBuyAmount) external payable  {
        address[] memory path;
        path[0] = WETH;
        path[1] = buyToken;
        uni.swapExactETHForTokens(
            minBuyAmount,
            path,
            msg.sender,
            block.timestamp + 1 * 10 
        );
    }

    /**
     * @dev 买入ETH，用 sellToken 兑换
     * @param sellToken 出售的代币地址
     * @param sellAmount 出售的代币数量
     * @param minBuyAmount 要求最低兑换到的ETH数量
     */
    function buyETH(address sellToken,uint256 sellAmount,uint256 minBuyAmount) external {
        address[] memory path;
        path[0] = sellToken;
        path[1] = WETH;
        uni.swapExactTokensForETH(
            sellAmount,
            minBuyAmount, 
            path, 
            msg.sender, 
            block.timestamp + 1 * 10
        );
    }


}