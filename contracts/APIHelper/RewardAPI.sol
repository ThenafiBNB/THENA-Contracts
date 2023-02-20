// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../libraries/Math.sol";
import "../interfaces/IBribeAPI.sol";
import "../interfaces/IWrappedBribeFactory.sol";
import "../interfaces/IGaugeAPI.sol";
import "../interfaces/IGaugeFactoryV3.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IMinter.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVotingEscrow.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RewardAPI is Initializable {
    /*  ╔══════════════════════════════╗
        ║            Struct            ║
        ╚══════════════════════════════╝ */
    struct Bribes {
        address[] tokens;
        string[] symbols;
        uint256[] decimals;
        uint256[] amounts;
    }

    struct Rewards {
        Bribes[] bribes;
    }

    IPairFactory public pairFactory;
    IVoter public voter;
    address public underlyingToken;
    address public owner;

    mapping(address => bool) public notReward;

    /*  ╔══════════════════════════════╗
        ║          INITIALIZER         ║
        ╚══════════════════════════════╝ */
    function initialize(address _voter) public initializer {
        owner = msg.sender;
        voter = IVoter(_voter);
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();
        address _notrew = address(0xF0308D005717858756ACAa6B3DCd4D0De4A1ca54);
        notReward[_notrew] = true;
    }

    /*  ╔══════════════════════════════╗
        ║       ADMIN UTILITIES        ║
        ╚══════════════════════════════╝ */
    function setOwner(address _owner) external {
        require(msg.sender == owner, "not owner");
        require(_owner != address(0), "zeroAddr");
        owner = _owner;
    }

    function setVoter(address _voter) external {
        require(msg.sender == owner, "not owner");
        require(_voter != address(0), "zeroAddr");
        voter = IVoter(_voter);
        // update variable depending on voter
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();
    }

    function addNotReward(address _token) external {
        require(msg.sender == owner, "not owner");
        notReward[_token] = true;
    }

    function removeNotReward(address _token) external {
        require(msg.sender == owner, "not owner");
        notReward[_token] = false;
    }

    /*  ╔══════════════════════════════╗
        ║     INTERNAL UTILITIES       ║
        ╚══════════════════════════════╝ */

    function _getEpochRewards(uint256 tokenId, address _bribe)
        internal
        view
        returns (Bribes memory _rewards)
    {
        uint256 totTokens = IBribeAPI(_bribe).rewardsListLength();
        uint256[] memory _amounts = new uint256[](totTokens);
        address[] memory _tokens = new address[](totTokens);
        string[] memory _symbol = new string[](totTokens);
        uint256[] memory _decimals = new uint256[](totTokens);
        uint256 ts = IBribeAPI(_bribe).getEpochStart();
        uint256 i = 0;
        uint256 _supply = IBribeAPI(_bribe).totalSupplyAt(ts);
        uint256 _balance = IBribeAPI(_bribe).balanceOfAt(tokenId, ts);
        address _token;
        IBribeAPI.Reward memory _reward;

        for (i; i < totTokens; i++) {
            _token = IBribeAPI(_bribe).rewardTokens(i);
            _tokens[i] = _token;
            if (_balance == 0 || notReward[_token]) {
                _amounts[i] = 0;
                _symbol[i] = "";
                _decimals[i] = 0;
            } else {
                _symbol[i] = IERC20(_token).symbol();
                _decimals[i] = IERC20(_token).decimals();
                _reward = IBribeAPI(_bribe).rewardData(_token, ts);
                _amounts[i] =
                    (((_reward.rewardsPerEpoch * 1e18) / _supply) * _balance) /
                    1e18;
            }
        }

        _rewards.tokens = _tokens;
        _rewards.amounts = _amounts;
        _rewards.symbols = _symbol;
        _rewards.decimals = _decimals;
    }

    function _getNextEpochRewards(address _bribe)
        internal
        view
        returns (Bribes memory _rewards)
    {
        uint256 totTokens = IBribeAPI(_bribe).rewardsListLength();
        uint256[] memory _amounts = new uint256[](totTokens);
        address[] memory _tokens = new address[](totTokens);
        string[] memory _symbol = new string[](totTokens);
        uint256[] memory _decimals = new uint256[](totTokens);
        uint256 ts = IBribeAPI(_bribe).getNextEpochStart();
        uint256 i = 0;
        address _token;
        IBribeAPI.Reward memory _reward;

        for (i; i < totTokens; i++) {
            _token = IBribeAPI(_bribe).rewardTokens(i);
            _tokens[i] = _token;
            if (notReward[_token]) {
                _amounts[i] = 0;
                _tokens[i] = address(0);
                _symbol[i] = "";
                _decimals[i] = 0;
            } else {
                _symbol[i] = IERC20(_token).symbol();
                _decimals[i] = IERC20(_token).decimals();
                _reward = IBribeAPI(_bribe).rewardData(_token, ts);
                _amounts[i] = _reward.rewardsPerEpoch;
            }
        }

        _rewards.tokens = _tokens;
        _rewards.amounts = _amounts;
        _rewards.symbols = _symbol;
        _rewards.decimals = _decimals;
    }

    /*  ╔══════════════════════════════╗
        ║            GETTER            ║
        ╚══════════════════════════════╝ */
    // @Notice Get the rewards available the next epoch.
    function getExpectedClaimForNextEpoch(
        uint256 tokenId,
        address[] memory pairs
    ) external view returns (Rewards[] memory) {
        uint256 i;
        uint256 len = pairs.length;
        address _gauge;
        address _bribe;

        Bribes[] memory _tempReward = new Bribes[](2);
        Rewards[] memory _rewards = new Rewards[](len);

        //external
        for (i = 0; i < len; i++) {
            _gauge = voter.gauges(pairs[i]);

            // get external
            _bribe = voter.external_bribes(_gauge);
            _tempReward[0] = _getEpochRewards(tokenId, _bribe);

            // get internal
            _bribe = voter.internal_bribes(_gauge);
            _tempReward[1] = _getEpochRewards(tokenId, _bribe);
            _rewards[i].bribes = _tempReward;
        }

        return _rewards;
    }

    // read all the bribe available for a pair
    function getPairBribe(address pair)
        external
        view
        returns (Bribes[] memory)
    {
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
}
