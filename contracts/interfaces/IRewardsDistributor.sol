// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRewardsDistributor {
    function checkPointToken() external;

    function votingEscrow() external view returns (address);

    function checkPointTotalSupply() external;

    function claimable(uint256 _tokenId) external view returns (uint256);
}
