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
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PairAPI is OwnableUpgradeable {
    /*  ╔══════════════════════════════╗
        ║            Struct            ║
        ╚══════════════════════════════╝ */
    struct pairInfo {
        // pair info
        address pair_address; // pair contract address
        string symbol; // pair symbol
        string name; // pair name
        uint256 decimals; // pair decimals
        bool stable; // pair pool type (stable = false, means it's a variable type of pool)
        uint256 total_supply; // pair tokens supply
        // token pair info
        address token0; // pair 1st token address
        string token0_symbol; // pair 1st token symbol
        uint256 token0_decimals; // pair 1st token decimals
        uint256 reserve0; // pair 1st token reserves (nr. of tokens in the contract)
        uint256 claimable0; // claimable 1st token from fees (for unstaked positions)
        address token1; // pair 2nd token address
        string token1_symbol; // pair 2nd token symbol
        uint256 token1_decimals; // pair 2nd token decimals
        uint256 reserve1; // pair 2nd token reserves (nr. of tokens in the contract)
        uint256 claimable1; // claimable 2nd token from fees (for unstaked positions)
        // pairs gauge
        address gauge; // pair gauge address
        uint256 gauge_total_supply; // pair staked tokens (less/eq than/to pair total supply)
        address fee; // pair fees contract address
        address bribe; // pair bribes contract address
        uint256 emissions; // pair emissions (per second)
        address emissions_token; // pair emissions token address
        uint256 emissions_token_decimals; // pair emissions token decimals
        // User deposit
        uint256 account_lp_balance; // account LP tokens balance
        uint256 account_token0_balance; // account 1st token balance
        uint256 account_token1_balance; // account 2nd token balance
        uint256 account_gauge_balance; // account pair staked in gauge balance
        uint256 account_gauge_earned; // account earned emissions for this pair
    }

    struct tokenBribe {
        address token;
        uint8 decimals;
        uint256 amount;
        string symbol;
    }

    struct pairBribeEpoch {
        uint256 epochTimestamp;
        uint256 totalVotes;
        address pair;
        tokenBribe[] bribes;
    }

    uint256 public constant MAX_PAIRS = 1000;
    uint256 public constant MAX_EPOCHS = 200;
    uint256 public constant MAX_REWARDS = 16;
    uint256 public constant WEEK = 7 * 24 * 60 * 60;

    IPairFactory public pairFactory;
    IVoter public voter;
    IWrappedBribeFactory public wBribeFactory;

    address public underlyingToken;

    event Voter(address oldVoter, address newVoter);
    event WBF(address oldWBF, address newWBF);

    /*  ╔══════════════════════════════╗
        ║          INITIALIZER         ║
        ╚══════════════════════════════╝ */
    function initialize(address _voter) public initializer {
        __Ownable_init();
        voter = IVoter(_voter);

        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();
    }

    /*  ╔══════════════════════════════╗
        ║       ADMIN UTILITIES        ║
        ╚══════════════════════════════╝ */

    function setVoter(address _voter) external onlyOwner {
        require(_voter != address(0), "zeroAddr");
        address _oldVoter = address(voter);
        voter = IVoter(_voter);

        // update variable depending on voter
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();

        emit Voter(_oldVoter, _voter);
    }

    /*  ╔══════════════════════════════╗
        ║     INTERNAL UTILITIES       ║
        ╚══════════════════════════════╝ */

    function _pairAddressToInfo(address _pair, address _account)
        internal
        view
        returns (pairInfo memory _pairInfo)
    {
        IPair ipair = IPair(_pair);

        address token_0;
        address token_1;
        uint256 r0;
        uint256 r1;

        (token_0, token_1) = ipair.tokens();
        (r0, r1, ) = ipair.getReserves();

        IGaugeAPI _gauge = IGaugeAPI(voter.gauges(_pair));
        uint256 accountGaugeLPAmount = 0;
        uint256 earned = 0;
        uint256 gaugeTotalSupply = 0;
        uint256 emissions = 0;

        if (address(_gauge) != address(0)) {
            if (_account != address(0)) {
                accountGaugeLPAmount = _gauge.balanceOf(_account);
                earned = _gauge.earned(_account);
            } else {
                accountGaugeLPAmount = 0;
                earned = 0;
            }
            gaugeTotalSupply = _gauge.totalSupply();
            emissions = _gauge.rewardRate();
        }

        // Pair General Info
        _pairInfo.pair_address = _pair;
        _pairInfo.symbol = ipair.symbol();
        _pairInfo.name = ipair.name();
        _pairInfo.decimals = ipair.decimals();
        _pairInfo.stable = ipair.isStable();
        _pairInfo.total_supply = ipair.totalSupply();

        // Token0 Info
        _pairInfo.token0 = token_0;
        _pairInfo.token0_decimals = IERC20(token_0).decimals();
        _pairInfo.token0_symbol = IERC20(token_0).symbol();
        _pairInfo.reserve0 = r0;
        _pairInfo.claimable0 = ipair.claimable0(_account);

        // Token1 Info
        _pairInfo.token1 = token_1;
        _pairInfo.token1_decimals = IERC20(token_1).decimals();
        _pairInfo.token1_symbol = IERC20(token_1).symbol();
        _pairInfo.reserve1 = r1;
        _pairInfo.claimable1 = ipair.claimable1(_account);

        // Pair's gauge Info
        _pairInfo.gauge = address(_gauge);
        _pairInfo.gauge_total_supply = gaugeTotalSupply;
        _pairInfo.emissions = emissions;
        _pairInfo.emissions_token = underlyingToken;
        _pairInfo.emissions_token_decimals = IERC20(underlyingToken).decimals();

        // external address
        _pairInfo.fee = voter.internal_bribes(address(_gauge));
        _pairInfo.bribe = voter.external_bribes(address(_gauge));

        // Account Info
        _pairInfo.account_lp_balance = IERC20(_pair).balanceOf(_account);
        _pairInfo.account_token0_balance = IERC20(token_0).balanceOf(_account);
        _pairInfo.account_token1_balance = IERC20(token_1).balanceOf(_account);
        _pairInfo.account_gauge_balance = accountGaugeLPAmount;
        _pairInfo.account_gauge_earned = earned;
    }

    function _bribe(uint256 _ts, address _br)
        internal
        view
        returns (tokenBribe[] memory _tb)
    {
        IBribeAPI _wb = IBribeAPI(_br);
        uint256 tokenLen = _wb.rewardsListLength();

        _tb = new tokenBribe[](tokenLen);

        uint256 k;
        uint256 _rewPerEpoch;
        IERC20 _t;
        for (k = 0; k < tokenLen; k++) {
            _t = IERC20(_wb.rewardTokens(k));
            if (
                address(_t) !=
                address(0xF0308D005717858756ACAa6B3DCd4D0De4A1ca54)
            ) {
                IBribeAPI.Reward memory _reward = _wb.rewardData(
                    address(_t),
                    _ts
                );
                _rewPerEpoch = _reward.rewardsPerEpoch;
                if (_rewPerEpoch > 0) {
                    _tb[k].token = address(_t);
                    _tb[k].symbol = _t.symbol();
                    _tb[k].decimals = _t.decimals();
                    _tb[k].amount = _rewPerEpoch;
                } else {
                    _tb[k].token = address(_t);
                    _tb[k].symbol = _t.symbol();
                    _tb[k].decimals = _t.decimals();
                    _tb[k].amount = 0;
                }
            } else {
                _tb[k].token = address(_t);
                _tb[k].symbol = "0x";
                _tb[k].decimals = 0;
                _tb[k].amount = 0;
            }
        }
    }

    /*  ╔══════════════════════════════╗
        ║            GETTER            ║
        ╚══════════════════════════════╝ */
    function getAllPair(
        address _user,
        uint256 _amounts,
        uint256 _offset
    ) external view returns (pairInfo[] memory Pairs) {
        require(_amounts <= MAX_PAIRS, "too many pair");

        Pairs = new pairInfo[](_amounts);

        uint256 i = _offset;
        uint256 totPairs = pairFactory.allPairsLength();
        address _pair;

        for (i; i < _offset + _amounts; i++) {
            // if totalPairs is reached, break.
            if (i == totPairs) {
                break;
            }
            _pair = pairFactory.allPairs(i);
            Pairs[i - _offset] = _pairAddressToInfo(_pair, _user);
        }
    }

    function getPair(address _pair, address _account)
        external
        view
        returns (pairInfo memory _pairInfo)
    {
        return _pairAddressToInfo(_pair, _account);
    }

    function getPairBribe(
        uint256 _amounts,
        uint256 _offset,
        address _pair
    ) external view returns (pairBribeEpoch[] memory _pairEpoch) {
        require(_amounts <= MAX_EPOCHS, "too many epochs");

        _pairEpoch = new pairBribeEpoch[](_amounts);

        address _gauge = voter.gauges(_pair);

        IBribeAPI bribe = IBribeAPI(voter.external_bribes(_gauge));

        // check bribe and checkpoints exists
        if (address(0) == address(bribe)) {
            return _pairEpoch;
        }

        // scan bribes
        // get latest balance and epoch start for bribes
        uint256 _epochStartTimestamp = bribe.firstBribeTimestamp();

        // if 0 then no bribe created so far
        if (_epochStartTimestamp == 0) {
            return _pairEpoch;
        }

        uint256 _supply;
        uint256 i = _offset;

        for (i; i < _offset + _amounts; i++) {
            _supply = bribe.totalSupplyAt(_epochStartTimestamp);
            _pairEpoch[i - _offset].epochTimestamp = _epochStartTimestamp;
            _pairEpoch[i - _offset].pair = _pair;
            _pairEpoch[i - _offset].totalVotes = _supply;
            _pairEpoch[i - _offset].bribes = _bribe(
                _epochStartTimestamp,
                address(bribe)
            );

            _epochStartTimestamp += WEEK;
        }
    }

    function left(address _pair, address _token)
        external
        view
        returns (uint256 _rewPerEpoch)
    {
        address _gauge = voter.gauges(_pair);
        IBribeAPI bribe = IBribeAPI(voter.internal_bribes(_gauge));

        uint256 _ts = bribe.getEpochStart();
        IBribeAPI.Reward memory _reward = bribe.rewardData(_token, _ts);
        _rewPerEpoch = _reward.rewardsPerEpoch;
    }
}
