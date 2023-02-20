// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMinter {
    function updatePeriod() external returns (uint);
    function check() external view returns(bool);
    function period() external view returns(uint);
    function activePeriod() external view returns(uint);
}
