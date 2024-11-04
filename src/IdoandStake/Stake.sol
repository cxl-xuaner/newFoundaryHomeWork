// SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.0;
// 用户随时可以质押项目方代币 RNT(自定义的RC20)，开始赚取项目方Tokex(esRNT);可随时解押提取已质押的 RNT;
// 可随时领取esRNT奖励，每质押1个RNT每天可奖励1esRNT;
// eSRNT 是锁仓性的 RNT，1eSRNT 在30 天后可兑换1RNT，随时间线性释放，支持提前将 eSRNT兑换成 RNT，但锁定部分将被 bum 燃烧掉。
// import "../ERC20Token/MyTokenERC20.sol";
// import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MyTokenMint} from "../ERC20Token/MyTokenMockMint.sol";  //用于tokenRNT
import {MyTokenNoMint} from "../ERC20Token/MyTokenMockNoMint.sol"; //用于tokeneSRNT

contract Stake {
    using SafeERC20 for IERC20;
    address public admin;
    // mapping(address => uint256) public stakeBalances;
    // mapping(address => uint256) public rewardBalances;

    uint256 public constant REWARDRATE = 1;
    uint256 public constant LOCKED_DAY = 30;
    // uint256 private minDuration = 1 days;

    // 定义质押信息类型
    struct stakeInfo {
        // address staker;
        uint256 amount;
        uint256 deadline;
    }

    //记录锁仓时间
    struct locked {
        uint256 amount;
        uint256 deadline;
    }

        // 定义奖励信息类型
    struct rewardInfo {
        locked[] rewardDetail;
        uint256 totalAmount;
    }


    mapping(address => stakeInfo) public stakeDepoistRNT;
    mapping(address => rewardInfo) public rewardEsRNT;


    MyTokenMint public tokenRNT;
    MyTokenNoMint public tokenESRNT;

    constructor(address RNTAddress, address eSRNTAddress) {
        admin = msg.sender;
        tokenRNT = MyTokenMint(RNTAddress); 
        tokenESRNT = MyTokenNoMint(eSRNTAddress); 

    }
    // EOA用户调用
    // 每次质押时，都会先把原来的质押进行结算后，更新质押数据
    function stake(uint256 amount) public {
        require(tokenRNT.balanceOf(msg.sender) >= amount, "insufficent funds");
        // 结算历史质押
        settleAccounts(msg.sender);
        // 重新计算只有量,包含旧质押和新质押的量
        IERC20(address(tokenRNT)).safeTransfer(address(this), amount);
        stakeDepoistRNT[msg.sender].amount += amount;
        stakeDepoistRNT[msg.sender].deadline = block.timestamp;
    }

    // EOA用户调用
    //解质押
    function unstake(uint256 amount) public {
        uint hasdAmounts = stakeDepoistRNT[msg.sender].amount;
        require(hasdAmounts > 0, "not staker");
        require(hasdAmounts >= amount, "insuffcient funds");
        //计算奖励
        settleAccounts(msg.sender);
        // 处理unstake
        IERC20(address(tokenRNT)).safeTransfer(msg.sender, amount);
        stakeDepoistRNT[msg.sender].amount -= amount;
        stakeDepoistRNT[msg.sender].deadline = block.timestamp;
    }


    //结算
    // 两种情况使用，1、新增质押  2、解质押
    function  settleAccounts(address staker) internal {
        stakeInfo memory stake_info = stakeDepoistRNT[staker];
        if(stake_info.amount>0){
            //执行奖励计算
            //只有满足整数天才能获得奖励
            uint256 _durationDay = (block.timestamp - stake_info.deadline) / 86400;
            uint256 _rewardAmount = REWARDRATE * _durationDay * stake_info.amount; 
            if(_rewardAmount>0){
                // 记录当前奖励
                rewardEsRNT[staker].rewardDetail.push(
                    locked({
                        amount : _rewardAmount,
                        deadline : block.timestamp
                    })
                );
                rewardEsRNT[staker].totalAmount += _rewardAmount;
            }

        }
    }

    // 领取奖励
    // 从领取eSRNT开始计算锁仓时间
    function claim() public {
        //eSRNT 怎么计算锁仓时间
        //机制：1个 eSRNT 在30天后可兑换为1个RNT
        //      如果未满30天，支持提前释放eSRNT，但是锁定的部分会被burn燃烧掉
        // 线性释放的公式为 unlocked = amount * （now - lockTime) / 30
        rewardInfo storage userRewardInfo  = rewardEsRNT[msg.sender];
        uint256 totalAmountUnlocked = 0;
        uint256 totalAmountLocked = 0;

        uint256 lockedPeriod = LOCKED_DAY * 86400;

        uint256 totalAmountReward = userRewardInfo.totalAmount;
        uint256 length = userRewardInfo.rewardDetail.length;
        if(totalAmountReward>0){ //如果没有奖励则不用计算
            for(uint256 i=0 ; i<length;){
                locked storage lockedInfo = userRewardInfo.rewardDetail[i];
                uint256 elapsed = block.timestamp - lockedInfo.deadline;
                if(elapsed>=lockedPeriod){
                    totalAmountUnlocked += lockedInfo.amount;
                }else{
                    uint256 AmountUnlocked = lockedInfo.amount * elapsed / lockedPeriod;
                    uint256 AmountLocked = lockedInfo.amount - AmountUnlocked;

                    totalAmountUnlocked += AmountUnlocked; 
                    totalAmountLocked += AmountLocked;
                }
                unchecked { //用户质押次数有限，所以i的数量不会很大
                    i++;
                }
            }

            mint(msg.sender, totalAmountUnlocked);
            burn(msg.sender, totalAmountLocked);
            delete userRewardInfo.rewardDetail;
            userRewardInfo.totalAmount = 0;

        }

    }

    //这里是mint eSRNT token
    function mint(address staker, uint256 amount) internal {
        tokenESRNT.mint(staker, amount);
        
    }    

    //这里是burn eSRNT token
    function burn(address staker, uint256 amount) internal {
        tokenESRNT.burn(staker, amount);

    }


    function eSRNTToRNT(uint256 amount) external {
        require(tokenESRNT.balanceOf(msg.sender)>=amount, "insuffcient funds");
        IERC20(address(tokenRNT)).safeTransfer(msg.sender, amount);
        tokenESRNT.burn(msg.sender, amount);

    }

}
