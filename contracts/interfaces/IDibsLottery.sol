// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IDibsLottery {
    function getActiveLotteryRound() external view returns (uint32);

    function roundDuration() external view returns (uint32);

    function firstRoundStartTime() external view returns (uint32);

    function roundToWinner(uint32) external view returns (address);

    function setRoundWinners(uint32 roundId, address[] memory winners) external;

    function setTopReferrers(uint32 day, address[] memory topReferrers)
    external;
}
