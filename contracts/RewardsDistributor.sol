// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "./libraries/Math.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IVotingEscrow.sol";

/*
@title Curve Fee Distribution modified for ve(3,3) emissions
@author Curve Finance, andrecronje
@license MIT
*/

contract RewardsDistributor is IRewardsDistributor {
    event CheckpointToken(uint256 time, uint256 tokens);

    event Claimed(
        uint256 tokenId,
        uint256 amount,
        uint256 claimEpoch,
        uint256 maxEpoch
    );

    uint256 constant WEEK = 7 * 86400;

    uint256 public startTime;
    uint256 public timeCursor;
    mapping(uint256 => uint256) public timeCursorOf;
    mapping(uint256 => uint256) public userEpochOf;

    uint256 public lastTokenTime;
    uint256[1000000000000000] public tokensPerWeek;
    uint256 public tokenLastBalance;
    uint256[1000000000000000] public veSupply;

    address public owner;
    address public votingEscrow;
    address public token;
    address public depositor;

    constructor(address _votingEscrow) {
        uint256 _t = (block.timestamp / WEEK) * WEEK;
        startTime = _t;
        lastTokenTime = _t;
        timeCursor = _t;
        address _token = IVotingEscrow(_votingEscrow).token();
        token = _token;
        votingEscrow = _votingEscrow;
        depositor = msg.sender;
        owner = msg.sender;
        require(IERC20(_token).approve(_votingEscrow, type(uint256).max));
    }

    function timestamp() external view returns (uint256) {
        return (block.timestamp / WEEK) * WEEK;
    }

    function _checkPointToken() internal {
        uint256 token_balance = IERC20(token).balanceOf(address(this));
        uint256 toDistribute = token_balance - tokenLastBalance;
        tokenLastBalance = token_balance;

        uint256 t = lastTokenTime;
        uint256 since_last = block.timestamp - t;
        lastTokenTime = block.timestamp;
        uint256 this_week = (t / WEEK) * WEEK;
        uint256 next_week = 0;

        for (uint256 i = 0; i < 20; i++) {
            next_week = this_week + WEEK;
            if (block.timestamp < next_week) {
                if (since_last == 0 && block.timestamp == t) {
                    tokensPerWeek[this_week] += toDistribute;
                } else {
                    tokensPerWeek[this_week] +=
                        (toDistribute * (block.timestamp - t)) /
                        since_last;
                }
                break;
            } else {
                if (since_last == 0 && next_week == t) {
                    tokensPerWeek[this_week] += toDistribute;
                } else {
                    tokensPerWeek[this_week] +=
                        (toDistribute * (next_week - t)) /
                        since_last;
                }
            }
            t = next_week;
            this_week = next_week;
        }
        emit CheckpointToken(block.timestamp, toDistribute);
    }

    function checkPointToken() external {
        assert(msg.sender == depositor);
        _checkPointToken();
    }

    function _find_timestamp_epoch(address ve, uint256 _timestamp)
        internal
        view
        returns (uint256)
    {
        uint256 _min = 0;
        uint256 _max = IVotingEscrow(ve).epoch();
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 2) / 2;
            IVotingEscrow.Point memory pt = IVotingEscrow(ve).pointHistory(
                _mid
            );
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function _findTimestampUserEpoch(
        address ve,
        uint256 tokenId,
        uint256 _timestamp,
        uint256 maxUserEpoch
    ) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = maxUserEpoch;
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 2) / 2;
            IVotingEscrow.Point memory pt = IVotingEscrow(ve).userPointHistory(
                tokenId,
                _mid
            );
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function ve_for_at(uint256 _tokenId, uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        address ve = votingEscrow;
        uint256 maxUserEpoch = IVotingEscrow(ve).userPointEpoch(_tokenId);
        uint256 epoch = _findTimestampUserEpoch(
            ve,
            _tokenId,
            _timestamp,
            maxUserEpoch
        );
        IVotingEscrow.Point memory pt = IVotingEscrow(ve).userPointHistory(
            _tokenId,
            epoch
        );
        return
            Math.max(
                uint256(
                    int256(
                        pt.bias -
                            pt.slope *
                            (int128(int256(_timestamp - pt.ts)))
                    )
                ),
                0
            );
    }

    function _checkPointTotalSupply() internal {
        address ve = votingEscrow;
        uint256 t = timeCursor;
        uint256 rounded_timestamp = (block.timestamp / WEEK) * WEEK;
        IVotingEscrow(ve).checkpoint();

        for (uint256 i = 0; i < 20; i++) {
            if (t > rounded_timestamp) {
                break;
            } else {
                uint256 epoch = _find_timestamp_epoch(ve, t);
                IVotingEscrow.Point memory pt = IVotingEscrow(ve).pointHistory(
                    epoch
                );
                int128 dt = 0;
                if (t > pt.ts) {
                    dt = int128(int256(t - pt.ts));
                }
                veSupply[t] = Math.max(
                    uint256(int256(pt.bias - pt.slope * dt)),
                    0
                );
            }
            t += WEEK;
        }
        timeCursor = t;
    }

    function checkPointTotalSupply() external {
        _checkPointTotalSupply();
    }

    function _claim(
        uint256 _tokenId,
        address ve,
        uint256 _lastTokenTime
    ) internal returns (uint256) {
        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = IVotingEscrow(ve).userPointEpoch(_tokenId);
        uint256 _startTime = startTime;

        if (maxUserEpoch == 0) return 0;

        uint256 weekCursor = timeCursorOf[_tokenId];
        if (weekCursor == 0) {
            userEpoch = _findTimestampUserEpoch(
                ve,
                _tokenId,
                _startTime,
                maxUserEpoch
            );
        } else {
            userEpoch = userEpochOf[_tokenId];
        }

        if (userEpoch == 0) userEpoch = 1;

        IVotingEscrow.Point memory user_point = IVotingEscrow(ve)
            .userPointHistory(_tokenId, userEpoch);

        if (weekCursor == 0)
            weekCursor = ((user_point.ts + WEEK - 1) / WEEK) * WEEK;
        if (weekCursor >= lastTokenTime) return 0;
        if (weekCursor < _startTime) weekCursor = _startTime;

        IVotingEscrow.Point memory oldUserPoint;

        for (uint256 i = 0; i < 50; i++) {
            if (weekCursor >= _lastTokenTime) break;

            if (weekCursor >= user_point.ts && userEpoch <= maxUserEpoch) {
                userEpoch += 1;
                oldUserPoint = user_point;
                if (userEpoch > maxUserEpoch) {
                    user_point = IVotingEscrow.Point(0, 0, 0, 0);
                } else {
                    user_point = IVotingEscrow(ve).userPointHistory(
                        _tokenId,
                        userEpoch
                    );
                }
            } else {
                int128 dt = int128(int256(weekCursor - oldUserPoint.ts));
                uint256 balance_of = Math.max(
                    uint256(
                        int256(oldUserPoint.bias - dt * oldUserPoint.slope)
                    ),
                    0
                );
                if (balance_of == 0 && userEpoch > maxUserEpoch) break;
                if (balance_of != 0) {
                    toDistribute +=
                        (balance_of * tokensPerWeek[weekCursor]) /
                        veSupply[weekCursor];
                }
                weekCursor += WEEK;
            }
        }

        userEpoch = Math.min(maxUserEpoch, userEpoch - 1);
        userEpochOf[_tokenId] = userEpoch;
        timeCursorOf[_tokenId] = weekCursor;

        emit Claimed(_tokenId, toDistribute, userEpoch, maxUserEpoch);

        return toDistribute;
    }

    function _claimable(
        uint256 _tokenId,
        address ve,
        uint256 _lastTokenTime
    ) internal view returns (uint256) {
        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = IVotingEscrow(ve).userPointEpoch(_tokenId);
        uint256 _startTime = startTime;

        if (maxUserEpoch == 0) return 0;

        uint256 weekCursor = timeCursorOf[_tokenId];
        if (weekCursor == 0) {
            userEpoch = _findTimestampUserEpoch(
                ve,
                _tokenId,
                _startTime,
                maxUserEpoch
            );
        } else {
            userEpoch = userEpochOf[_tokenId];
        }

        if (userEpoch == 0) userEpoch = 1;

        IVotingEscrow.Point memory user_point = IVotingEscrow(ve)
            .userPointHistory(_tokenId, userEpoch);

        if (weekCursor == 0)
            weekCursor = ((user_point.ts + WEEK - 1) / WEEK) * WEEK;
        if (weekCursor >= lastTokenTime) return 0;
        if (weekCursor < _startTime) weekCursor = _startTime;

        IVotingEscrow.Point memory oldUserPoint;

        for (uint256 i = 0; i < 50; i++) {
            if (weekCursor >= _lastTokenTime) break;

            if (weekCursor >= user_point.ts && userEpoch <= maxUserEpoch) {
                userEpoch += 1;
                oldUserPoint = user_point;
                if (userEpoch > maxUserEpoch) {
                    user_point = IVotingEscrow.Point(0, 0, 0, 0);
                } else {
                    user_point = IVotingEscrow(ve).userPointHistory(
                        _tokenId,
                        userEpoch
                    );
                }
            } else {
                int128 dt = int128(int256(weekCursor - oldUserPoint.ts));
                uint256 balance_of = Math.max(
                    uint256(
                        int256(oldUserPoint.bias - dt * oldUserPoint.slope)
                    ),
                    0
                );
                if (balance_of == 0 && userEpoch > maxUserEpoch) break;
                if (balance_of != 0) {
                    toDistribute +=
                        (balance_of * tokensPerWeek[weekCursor]) /
                        veSupply[weekCursor];
                }
                weekCursor += WEEK;
            }
        }

        return toDistribute;
    }

    function claimable(uint256 _tokenId) external view returns (uint256) {
        uint256 _lastTokenTime = (lastTokenTime / WEEK) * WEEK;
        return _claimable(_tokenId, votingEscrow, _lastTokenTime);
    }

    function claim(uint256 _tokenId) external returns (uint256) {
        if (block.timestamp >= timeCursor) _checkPointTotalSupply();
        uint256 _lastTokenTime = lastTokenTime;
        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;
        uint256 amount = _claim(_tokenId, votingEscrow, _lastTokenTime);
        if (amount != 0) {
            // if locked.end then send directly
            IVotingEscrow.LockedBalance memory _locked = IVotingEscrow(
                votingEscrow
            ).locked(_tokenId);
            if (_locked.end < block.timestamp) {
                address _nftOwner = IVotingEscrow(votingEscrow).ownerOf(
                    _tokenId
                );
                IERC20(token).transfer(_nftOwner, amount);
            } else {
                IVotingEscrow(votingEscrow).depositFor(_tokenId, amount);
            }
            tokenLastBalance -= amount;
        }
        return amount;
    }

    function claimMany(uint256[] memory _tokenIds) external returns (bool) {
        if (block.timestamp >= timeCursor) _checkPointTotalSupply();
        uint256 _lastTokenTime = lastTokenTime;
        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;
        address _votingEscrow = votingEscrow;
        uint256 total = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            if (_tokenId == 0) break;
            uint256 amount = _claim(_tokenId, _votingEscrow, _lastTokenTime);
            if (amount != 0) {
                // if locked.end then send directly
                IVotingEscrow.LockedBalance memory _locked = IVotingEscrow(
                    _votingEscrow
                ).locked(_tokenId);
                if (_locked.end < block.timestamp) {
                    address _nftOwner = IVotingEscrow(_votingEscrow).ownerOf(
                        _tokenId
                    );
                    IERC20(token).transfer(_nftOwner, amount);
                } else {
                    IVotingEscrow(_votingEscrow).depositFor(_tokenId, amount);
                }
                total += amount;
            }
        }
        if (total != 0) {
            tokenLastBalance -= total;
        }

        return true;
    }

    function setDepositor(address _depositor) external {
        require(msg.sender == owner);
        depositor = _depositor;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }

    function withdrawERC20(address _token) external {
        require(msg.sender == owner);
        require(_token != address(0));
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, _balance);
    }
}
