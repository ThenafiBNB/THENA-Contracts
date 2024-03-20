// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '../interfaces/IBribeAPI.sol';
import '../interfaces/IGaugeFactory.sol';
import '../interfaces/IERC20Full.sol';
import '../interfaces/IMinter.sol';
import '../interfaces/IPair.sol';
import '../interfaces/IPairFactory.sol';
import '../interfaces/IVoter.sol';
import '../interfaces/IVotingEscrow.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RewardAPI is Initializable {

 

    IPairFactory public pairFactory;
    IVoter public voter;
    address public underlyingToken;
    address public owner;


    
    constructor() {}

    function initialize(address _voter) initializer public {
  
        owner = msg.sender;
        voter = IVoter(_voter);
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();
    }


    struct Bribes {
        address[] tokens;
        uint[] decimals;
        uint[] amounts;
    }

    struct Rewards {
        Bribes[] bribes;
    }

    /// @notice Get the rewards available the next epoch given a tokenID
    function getExpectedClaimForNextEpochId(uint tokenId, address[] memory pairs) external view returns(Rewards[] memory){
        uint i;
        uint len = pairs.length;
        address _gauge;
        address _bribe;
        bool exists;

        Bribes[] memory _tempReward = new Bribes[](2);
        Rewards[] memory _rewards = new Rewards[](len);

        //external
        for(i=0; i < len; i++){
            _gauge = voter.gauges(pairs[i]);

            // get external
            _bribe = voter.external_bribes(_gauge);
            (_tempReward[0], exists) = _getEpochRewards(address(0), tokenId, _bribe);
            
            // get internal
            _bribe = voter.internal_bribes(_gauge);
            (_tempReward[0], exists) = _getEpochRewards(address(0), tokenId, _bribe);
            _rewards[i].bribes = _tempReward;
        }      
        if(!exists) return new Rewards[](0);
        return _rewards;  
    }

        /// @notice Get the rewards available the next epoch given a address
    function getExpectedClaimForNextEpochAddress(address user, address[] memory pairs) external view returns(Rewards[] memory){
        uint i;
        uint len = pairs.length;
        address _gauge;
        address _bribe;
        bool exists = false;

        Bribes[] memory _tempReward = new Bribes[](2);
        Rewards[] memory _rewards = new Rewards[](len);

        //external
        for(i=0; i < len; i++){
            _gauge = voter.gauges(pairs[i]);

            // get external
            _bribe = voter.external_bribes(_gauge);
            (_tempReward[0], exists) = _getEpochRewards(user, 0, _bribe);
            
            // get internal
            _bribe = voter.internal_bribes(_gauge);
            (_tempReward[1], exists) = _getEpochRewards(user, 0, _bribe);
            _rewards[i].bribes = _tempReward;
        }      
        if(!exists) return new Rewards[](0);
        return _rewards;  
    }
   
    function _getEpochRewards(address user, uint tokenId, address _bribe) internal view returns(Bribes memory _rewards, bool exists){
        uint totTokens = IBribeAPI(_bribe).rewardsListLength();
        uint[] memory _amounts = new uint[](totTokens);
        address[] memory _tokens = new address[](totTokens);
        uint[] memory _decimals = new uint[](totTokens);
        uint ts = IBribeAPI(_bribe).getEpochStart();
        uint i = 0;
        uint _supply = IBribeAPI(_bribe).totalSupplyAt(ts);
        uint _balance = tokenId == 0 ? IBribeAPI(_bribe).balanceOfOwnerAt(user, ts) : IBribeAPI(_bribe).balanceOfAt(tokenId, ts);
        address _token;
        exists = false;
        IBribeAPI.Reward memory _reward;

        for(i; i < totTokens; i++){
            _token = IBribeAPI(_bribe).rewardTokens(i);
            _tokens[i] = _token;
            if(_balance == 0){
                _amounts[i] = 0;
                _decimals[i] = 0;
            } else {
                _decimals[i] = IERC20(_token).decimals();
                _reward = IBribeAPI(_bribe).rewardData(_token, ts);
                _amounts[i] = (_reward.rewardsPerEpoch * 1e18 / _supply) * _balance / 1e18;
                if(!exists) exists = true;
            }
        }

        _rewards.tokens = _tokens;
        _rewards.amounts = _amounts;
        _rewards.decimals = _decimals;
    }


    
    // read all the bribe available for a pair
    function getPairBribe(address pair) external view returns(Bribes[] memory){

        address _gauge;
        address _bribe;

        Bribes[] memory _tempReward = new Bribes[](2);

        // get external
        _gauge = voter.gauges(pair);
        _bribe = voter.external_bribes(_gauge);
        _tempReward[0] = _getNextEpochRewards(_bribe);
        
        // get internal
        _bribe = voter.internal_bribes(_gauge);
        _tempReward[1] = _getNextEpochRewards(_bribe);
        return _tempReward;
            
    }

    function _getNextEpochRewards(address _bribe) internal view returns(Bribes memory _rewards){
        uint totTokens = IBribeAPI(_bribe).rewardsListLength();
        uint[] memory _amounts = new uint[](totTokens);
        address[] memory _tokens = new address[](totTokens);
        uint[] memory _decimals = new uint[](totTokens);
        uint ts = IBribeAPI(_bribe).getNextEpochStart();
        uint i = 0;
        address _token;
        IBribeAPI.Reward memory _reward;

        for(i; i < totTokens; i++){
            _token = IBribeAPI(_bribe).rewardTokens(i);
            _tokens[i] = _token;
            _decimals[i] = IERC20(_token).decimals();
            _reward = IBribeAPI(_bribe).rewardData(_token, ts);
            _amounts[i] = _reward.rewardsPerEpoch;
            
        }

        _rewards.tokens = _tokens;
        _rewards.amounts = _amounts;
        _rewards.decimals = _decimals;
    }

 
    function setOwner(address _owner) external {
        require(msg.sender == owner, 'not owner');
        require(_owner != address(0), 'zeroAddr');
        owner = _owner;
    }

    function setVoter(address _voter) external {
        require(msg.sender == owner, 'not owner');
        require(_voter != address(0), 'zeroAddr');
        voter = IVoter(_voter);
        // update variable depending on voter
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();
    }

}