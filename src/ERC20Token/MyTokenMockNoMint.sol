//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {MockERC20} from "./mock.sol";

interface IERC777Recipient {
    function tokensReceived( // 允许 接收者 在接收代币时执行自定义逻辑 这个函数在 ERC777 代币合约调用 send 或 transfer 后自动触发，确保代币接收者可以处理接收到的代币
        address from,
        address to,
        uint256 amount
    ) external;
}

contract MyTokenNoMint is MockERC20 { 
    constructor(
        string memory name_, 
        string memory symbol_,
        uint8 decimals_
    )  {
       initialize(name_, symbol_, decimals_);
    
    }
    // isContract函数，判断地址是否为合约地址
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly { // 使用内联汇编检查地址的代码大小
            size := extcodesize(account) // 获取地址关联的代码大小，extcodesize可区分 合约地址>0 和 EOA=0
        }
        return  size > 0; // 如果代码大小大于0，则为合约地址
    }
    // deposit token to bank
    function transferWithCallback(address recipient, uint amount) external returns (bool)  {
        transferFrom(msg.sender, recipient, amount);
        // 检查接收者是否为合约
        if(isContract(recipient)) {
            IERC777Recipient(recipient).tokensReceived( msg.sender, recipient, amount);
        }
        return true;
    }


    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    

}
