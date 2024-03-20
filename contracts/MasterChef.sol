// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MasterChef is Ownable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenIndices;
    }

    struct PoolInfo {
        uint256 accRewardPerShare;
        uint256 lastRewardTime;
    }

    /// @notice Address of reward token contract.
    IERC20 public TOKEN;
    /// @notice Address of the NFT token for each MCV2 pool.
    IERC721 public NFT;

    /// @notice Info of each MCV2 pool.
    PoolInfo public poolInfo;

    /// @notice Mapping from token ID to owner address
    mapping(uint256 => address) public tokenOwner;

    /// @notice Info of each user that stakes nft tokens.
    mapping(address => UserInfo) public userInfo;

    /// @notice Keeper register. Return true if 'address' is a keeper.
    mapping(address => bool) public isKeeper;

    uint256 public rewardPerSecond;
    uint256 private ACC_TOKEN_PRECISION;

    uint256 public distributePeriod;
    uint256 public lastDistributedTime;

    event Deposit(address indexed user, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 amount);
    event LogUpdatePool(
        uint256 lastRewardTime,
        uint256 nftSupply,
        uint256 accRewardPerShare
    );
    event LogRewardPerSecond(uint256 rewardPerSecond);


    modifier onlyKeeper {
        require(msg.sender == owner() || isKeeper[msg.sender],'not keeper'); 
        _;
    }

    constructor(IERC20 _TOKEN, IERC721 _NFT) {
        TOKEN = _TOKEN;
        NFT = _NFT;
        distributePeriod = 1 weeks;
        ACC_TOKEN_PRECISION = 1e12;
        poolInfo = PoolInfo({
            lastRewardTime: block.timestamp,
            accRewardPerShare: 0
        });
    }

    /// @notice add keepers
    function addKeeper(address[] calldata _keepers) external onlyOwner {
        uint256 i = 0;
        uint256 len = _keepers.length;

        for(i; i < len; i++){
            address _keeper = _keepers[i];
            if(!isKeeper[_keeper]){
                isKeeper[_keeper] = true;
            }
        }
    }

    /// @notice remove keepers
    function removeKeeper(address[] calldata _keepers) external onlyOwner {
        uint256 i = 0;
        uint256 len = _keepers.length;

        for(i; i < len; i++){
            address _keeper = _keepers[i];
            if(isKeeper[_keeper]){
                isKeeper[_keeper] = false;
            }
        }
    }  


    /// @notice Sets the reward per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of Reward to be distributed per second.
    function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
        updatePool();
        rewardPerSecond = _rewardPerSecond;
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    function setDistributionRate(uint256 amount) public onlyKeeper {
        updatePool();
        uint256 notDistributed;
        if (lastDistributedTime > 0 && block.timestamp < lastDistributedTime) {
            uint256 timeLeft = lastDistributedTime - block.timestamp;
            notDistributed = rewardPerSecond * timeLeft;
        }

        amount = amount + notDistributed;
        uint256 _rewardPerSecond = amount / distributePeriod;
        rewardPerSecond = _rewardPerSecond;
        lastDistributedTime = block.timestamp + distributePeriod;
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    /// @notice View function to see pending TOKEN on frontend.
    /// @param _user Address of user.
    /// @return pending TOKEN reward for a given user.
    function pendingReward(address _user) external view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 nftSupply = NFT.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && nftSupply != 0) {
            uint256 time = block.timestamp - pool.lastRewardTime;
            uint256 reward = time * rewardPerSecond;
            accRewardPerShare = accRewardPerShare + ( reward * ACC_TOKEN_PRECISION / nftSupply );
        }
        pending = uint256( int256( user.amount * accRewardPerShare / ACC_TOKEN_PRECISION ) - user.rewardDebt );
    }

   

    /// @notice View function to see TOKEN Ids on frontend.
    /// @param _user Address of user.
    /// @return tokenIds Staked Token Ids for a given user.
    function stakedTokenIds(address _user) external view returns (uint256[] memory tokenIds) {
        tokenIds = userInfo[_user].tokenIds;
    }

    /// @notice Update reward variables of the given pool.
    /// @return pool Returns the pool that was updated.
    function updatePool() public returns (PoolInfo memory pool) {
        pool = poolInfo;
        if (block.timestamp > pool.lastRewardTime) {
            uint256 nftSupply = NFT.balanceOf(address(this));
            if (nftSupply > 0) {
                uint256 time = block.timestamp - pool.lastRewardTime;
                uint256 reward = time * rewardPerSecond;
                pool.accRewardPerShare = pool.accRewardPerShare + reward * ACC_TOKEN_PRECISION / nftSupply;
            }
            pool.lastRewardTime = block.timestamp;
            poolInfo = pool;

            emit LogUpdatePool(pool.lastRewardTime,nftSupply,pool.accRewardPerShare);
        }
    }

    /// @notice Deposit nft tokens to MCV2 for token allocation.
    /// @param tokenIds NFT tokenIds to deposit.
    function deposit(uint256[] calldata tokenIds) public {
        PoolInfo memory pool = updatePool();
        UserInfo storage user = userInfo[msg.sender];

        // Effects
        user.amount = user.amount + tokenIds.length;
        user.rewardDebt = user.rewardDebt + int256(tokenIds.length * pool.accRewardPerShare / ACC_TOKEN_PRECISION);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(NFT.ownerOf(tokenIds[i]) == msg.sender, "CHEF: !NFT Owner");

            user.tokenIndices[tokenIds[i]] = user.tokenIds.length;
            user.tokenIds.push(tokenIds[i]);
            tokenOwner[tokenIds[i]] = msg.sender;

            NFT.transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        emit Deposit(msg.sender, tokenIds.length, msg.sender);
    }

    /// @notice Withdraw NFT tokens from MCV2.
    /// @param tokenIds NFT token ids to withdraw.
    function withdraw(uint256[] calldata tokenIds) public {
        PoolInfo memory pool = updatePool();
        UserInfo storage user = userInfo[msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt - int256(tokenIds.length * (pool.accRewardPerShare) / ACC_TOKEN_PRECISION);
        user.amount = user.amount - tokenIds.length;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenOwner[tokenIds[i]] == msg.sender, "CHEF: !NFT Owner");
            NFT.transferFrom(address(this), msg.sender, tokenIds[i]);
            uint256 lastTokenId = user.tokenIds[user.tokenIds.length - 1];
            user.tokenIds[user.tokenIndices[tokenIds[i]]] = lastTokenId;
            user.tokenIndices[lastTokenId] = user.tokenIndices[tokenIds[i]];
            user.tokenIds.pop();
            delete user.tokenIndices[tokenIds[i]];
            delete tokenOwner[tokenIds[i]];
        }

        emit Withdraw(msg.sender, tokenIds.length, msg.sender);
    }

    /// @notice Harvest proceeds for transaction sender.
    function harvest() public {
        PoolInfo memory pool = updatePool();
        UserInfo storage user = userInfo[msg.sender];
        int256 accumulatedReward = int256( user.amount * (pool.accRewardPerShare) / ACC_TOKEN_PRECISION);
        uint256 _pendingReward = uint256(accumulatedReward - user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedReward;

        // Interactions
        if (_pendingReward != 0) {
            TOKEN.safeTransfer(msg.sender, _pendingReward);
        }

        emit Harvest(msg.sender, _pendingReward);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}