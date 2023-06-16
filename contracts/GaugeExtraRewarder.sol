// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IRewarder {
    function onReward(uint256 pid, address user, address recipient, uint256 lqdrAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 lqdrAmount) external view returns (IERC20[] memory, uint256[] memory);
}

interface IGauge {
    function TOKEN() external view returns(address);
}


contract GaugeExtraRewarder is Ownable {

    using SafeERC20 for IERC20;


    IERC20 public immutable rewardToken;

    /// @notice Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /// @notice Struct of pool info
    struct PoolInfo {
        uint256 accRewardPerShare;
        uint256 lastRewardTime;
    }

    /// @notice pool info
    PoolInfo public poolInfo;

    /// @notice Info of each user that stakes tokens.
    mapping(address => UserInfo) public userInfo;

    uint256 public lastDistributedTime;
    uint256 public rewardPerSecond;
    uint256 public immutable distributePeriod;
    uint256 public immutable ACC_TOKEN_PRECISION = 1e12;


    address private GAUGE;

    event OnReward(address indexed user, uint256 LPBalance, uint256 rewardAmount, address indexed to);

    constructor (IERC20 _rewardToken, address gauge) {
        rewardToken = _rewardToken;
        poolInfo = PoolInfo({
            lastRewardTime: block.timestamp,
            accRewardPerShare: 0
        });
        GAUGE = gauge;
        distributePeriod = 7 days;
    }

    /// @notice Call onReward from gauge, it saves the new user balance and get any available reward
    /// @param _user    user address
    /// @param to       where to send rewards
    /// @param userBalance  the balance of LP in gauge
    function onReward(address _user, address to, uint256 userBalance) onlyGauge external {
        PoolInfo memory pool = updatePool();
        UserInfo storage user = userInfo[_user];
        uint256 pending;
        if (user.amount > 0) {

            pending = _pendingReward(_user);

            rewardToken.safeTransfer(to, pending);
        }
        user.amount = userBalance;
        user.rewardDebt = (userBalance * (pool.accRewardPerShare) / ACC_TOKEN_PRECISION);

        emit OnReward(_user, userBalance, pending, to);

    }


    /// @notice View function to see pending Rewards on frontend.
    /// @param _user Address of user.
    /// @return pending rewardToken reward for a given user.
    function pendingReward(address _user) public view returns (uint256 pending){
        pending = _pendingReward(_user);
    }
    function _pendingReward(address _user) internal view returns(uint256 pending){
        PoolInfo memory pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = IERC20(IGauge(GAUGE).TOKEN()).balanceOf(GAUGE);

        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            // if we reach the end, look for the missing seconds up to LastDistributedTime ; else use block.timestamp
            uint _tempTimestamp;
            if( block.timestamp >= lastDistributedTime){
                // if lastRewardTime is > than LastDistributedTime then set tempTimestamp to 0 to avoid underflow
                _tempTimestamp = pool.lastRewardTime > lastDistributedTime ?  0 : lastDistributedTime - pool.lastRewardTime;
            } else {
                _tempTimestamp = block.timestamp - pool.lastRewardTime;
            } 
            uint256 time = _tempTimestamp;
            uint256 reward = time * (rewardPerSecond);
            accRewardPerShare = accRewardPerShare + ( reward * (ACC_TOKEN_PRECISION) / lpSupply );
        }
        
        pending =  (user.amount * (accRewardPerShare) / ACC_TOKEN_PRECISION)  - (user.rewardDebt);
    }


    modifier onlyGauge {
        require(msg.sender == GAUGE,"!GAUGE");
        _;
    }




    /// @notice Set the distribution rate for a given distributePeriod. Rewards needs to be sent before calling setDistributionRate
    function setDistributionRate(uint256 amount) public onlyOwner {
        updatePool();
        require(IERC20(rewardToken).balanceOf(address(this)) >= amount, "not enough");
        uint256 notDistributed;
        if (block.timestamp < lastDistributedTime) {
            uint256 timeLeft = lastDistributedTime - (block.timestamp);
            notDistributed = rewardPerSecond * (timeLeft);

        }

        amount = amount + (notDistributed);
        uint256 _rewardPerSecond = amount / (distributePeriod);
        require(IERC20(rewardToken).balanceOf(address(this)) >= amount);

        rewardPerSecond = _rewardPerSecond;
        lastDistributedTime = block.timestamp + (distributePeriod);
    }



    /// @notice Update reward variables of the given pool.
    /// @return pool Returns the pool that was updated.
    function updatePool() public returns (PoolInfo memory pool) {
        pool = poolInfo;
        if (block.timestamp > pool.lastRewardTime) {
            uint256 lpSupply = IERC20(IGauge(GAUGE).TOKEN()).balanceOf(GAUGE);
            if (lpSupply > 0) {
                // if we reach the end, look for the missing seconds up to LastDistributedTime ; else use block.timestamp
                uint _tempTimestamp;
                if( block.timestamp >= lastDistributedTime){
                    // if lastRewardTime is > than LastDistributedTime then set tempTimestamp to 0 to avoid underflow
                    _tempTimestamp = pool.lastRewardTime > lastDistributedTime ?  0 : lastDistributedTime - (pool.lastRewardTime);
                } else {
                    _tempTimestamp = block.timestamp - (pool.lastRewardTime);
                } 

                uint256 time = _tempTimestamp;
                uint256 reward = time * (rewardPerSecond);
                pool.accRewardPerShare = pool.accRewardPerShare + ( reward * (ACC_TOKEN_PRECISION) / (lpSupply) );

            }
            pool.lastRewardTime = block.timestamp;
            poolInfo = pool;
        }
    }


    /// @notice Recover any ERC20 available
    function recoverERC20(uint amount, address token) external onlyOwner {
        require(amount > 0, "amount > 0");
        require(token != address(0), "addr0");
        uint balance = IERC20(token).balanceOf(address(this));
        require(balance >= amount, "not enough tokens");

        // if token is = reward and there are some (rps > 0), allow withdraw only for remaining rewards and then set new rewPerSec
        if(token == address(rewardToken) && rewardPerSecond != 0){
            updatePool();
            uint timeleft = lastDistributedTime - block.timestamp;
            uint notDistributed = rewardPerSecond * timeleft;
            require(amount <= notDistributed, 'too many rewardToken');
            rewardPerSecond = (notDistributed - amount) / timeleft;
        }
        IERC20(token).safeTransfer(msg.sender, amount);

    }



    function _gauge() external view returns(address){
        return GAUGE;
    }



}