// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "./libraries/Math.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IStarBugToken.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract MinterUpgradeable is IMinter, OwnableUpgradeable {
    bool public isFirstMint;

    uint256 public EMISSION;
    uint256 public TAIL_EMISSION;
    uint256 public REBASEMAX;
    uint256 public constant PRECISION = 1000;
    uint256 public teamRate;
    uint256 public constant MAX_TEAM_RATE = 50; // 5%

    uint256 public constant WEEK = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint256 public weekly; // represents a starting weekly emission of 2.6M StarBugToken (StarBugToken has 18 decimals)
    uint256 public activePeriod;
    uint256 public constant LOCK = 86400 * 7 * 52 * 2;

    address internal _initializer;
    address public team;
    address public pendingTeam;

    IStarBugToken public _starBugToken;
    IVoter public _voter;
    IVotingEscrow public _ve;
    IRewardsDistributor public _rewardsDistributor;

    event Mint(
        address indexed sender,
        uint256 weekly,
        uint256 circulatingSupply,
        uint256 circulatingEmission
    );

    /*  ╔══════════════════════════════╗
        ║          INITIALIZER         ║
        ╚══════════════════════════════╝ */

    function initialize(
        address __voter, // the voting & distribution system
        address __ve, // the ve(3,3) system that will be locked into
        address __rewardsDistributor // the distribution system that ensures users aren't diluted
    ) public initializer {
        __Ownable_init();

        _initializer = msg.sender;
        team = msg.sender;

        teamRate = 40; // 300 bps = 3%

        EMISSION = 990;
        TAIL_EMISSION = 2;
        REBASEMAX = 300;

        _starBugToken = IStarBugToken(IVotingEscrow(__ve).token());
        _voter = IVoter(__voter);
        _ve = IVotingEscrow(__ve);
        _rewardsDistributor = IRewardsDistributor(__rewardsDistributor);

        activePeriod = ((block.timestamp + (2 * WEEK)) / WEEK) * WEEK;
        weekly = 2_600_000 * 1e18; // represents a starting weekly emission of 2.6M THENA (THENA has 18 decimals)
        isFirstMint = true;
    }

    function _initialize(
        address[] memory claimants,
        uint256[] memory amounts,
        uint256 max // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
    ) external {
        require(_initializer == msg.sender);
        if (max > 0) {
            _starBugToken.mint(address(this), max);
            _starBugToken.approve(address(_ve), type(uint256).max);
            for (uint256 i = 0; i < claimants.length; i++) {
                _ve.createLockFor(amounts[i], LOCK, claimants[i]);
            }
        }

        _initializer = address(0);
        activePeriod = ((block.timestamp) / WEEK) * WEEK; // allow minter.updatePeriod() to mint new emissions THIS Thursday
    }

    function setTeam(address _team) external {
        require(msg.sender == team, "not team");
        pendingTeam = _team;
    }

    function acceptTeam() external {
        require(msg.sender == pendingTeam, "not pending team");
        team = pendingTeam;
    }

    function setVoter(address __voter) external {
        require(__voter != address(0));
        require(msg.sender == team, "not team");
        _voter = IVoter(__voter);
    }

    function setTeamRate(uint256 _teamRate) external {
        require(msg.sender == team, "not team");
        require(_teamRate <= MAX_TEAM_RATE, "rate too high");
        teamRate = _teamRate;
    }

    function setEmission(uint256 _emission) external {
        require(msg.sender == team, "not team");
        require(_emission <= PRECISION, "rate too high");
        EMISSION = _emission;
    }

    function setRebase(uint256 _rebase) external {
        require(msg.sender == team, "not team");
        require(_rebase <= PRECISION, "rate too high");
        REBASEMAX = _rebase;
    }

    // calculate circulating supply as total token supply - locked supply
    function circulatingSupply() public view returns (uint256) {
        return
            _starBugToken.totalSupply() - _starBugToken.balanceOf(address(_ve));
    }

    // emission calculation is 1% of available supply to mint adjusted by circulating / total supply
    function calculateEmission() public view returns (uint256) {
        return (weekly * EMISSION) / PRECISION;
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weeklyEmission() public view returns (uint256) {
        return Math.max(calculateEmission(), circulatingEmission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulatingEmission() public view returns (uint256) {
        return (circulatingSupply() * TAIL_EMISSION) / PRECISION;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculateRebate(uint256 _weeklyMint)
        public
        view
        returns (uint256)
    {
        uint256 _veTotal = _starBugToken.balanceOf(address(_ve));
        uint256 _starBugTokenTotal = _starBugToken.totalSupply();

        uint256 lockedShare = ((_veTotal) * PRECISION) / _starBugTokenTotal;
        if (lockedShare >= REBASEMAX) {
            return (_weeklyMint * REBASEMAX) / PRECISION;
        } else {
            return (_weeklyMint * lockedShare) / PRECISION;
        }
    }

    // update period can only be called once per cycle (1 week)
    function updatePeriod() external returns (uint256) {
        uint256 _period = activePeriod;
        if (block.timestamp >= _period + WEEK && _initializer == address(0)) {
            // only trigger if new week
            _period = (block.timestamp / WEEK) * WEEK;
            activePeriod = _period;

            if (!isFirstMint) {
                weekly = weeklyEmission();
            } else {
                isFirstMint = false;
            }

            uint256 _rebase = calculateRebate(weekly);
            uint256 _teamEmissions = (weekly * teamRate) / PRECISION;
            uint256 _required = weekly;

            uint256 _gauge = weekly - _rebase - _teamEmissions;

            uint256 _balanceOf = _starBugToken.balanceOf(address(this));
            if (_balanceOf < _required) {
                _starBugToken.mint(address(this), _required - _balanceOf);
            }

            require(_starBugToken.transfer(team, _teamEmissions));

            require(
                _starBugToken.transfer(address(_rewardsDistributor), _rebase)
            );
            _rewardsDistributor.checkPointToken(); // checkPoint token balance that was just minted in rewards distributor
            _rewardsDistributor.checkPointTotalSupply(); // checkPoint supply

            _starBugToken.approve(address(_voter), _gauge);
            _voter.notifyRewardAmount(_gauge);

            emit Mint(
                msg.sender,
                weekly,
                circulatingSupply(),
                circulatingEmission()
            );
        }
        return _period;
    }

    function check() external view returns (bool) {
        uint256 _period = activePeriod;
        return (block.timestamp >= _period + WEEK &&
            _initializer == address(0));
    }

    function period() external view returns (uint256) {
        return (block.timestamp / WEEK) * WEEK;
    }

    function setRewardDistributor(address _rewardDistro) external {
        require(msg.sender == team);
        _rewardsDistributor = IRewardsDistributor(_rewardDistro);
    }
}
