// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IVoter {
    function ve() external view returns (address);
    function _ve() external view returns (address);
    function gauges(address _pair) external view returns (address);
    function isGauge(address _gauge) external view returns (bool);
    function poolForGauge(address _gauge) external view returns (address);
    function factory() external view returns (address);
    function minter() external view returns(address);
    function isWhitelisted(address token) external view returns (bool);
    function notifyRewardAmount(uint amount) external;
    function distributeAll() external;    
    function distribute(uint start, uint finish) external;
    function distributeFees(address[] memory _gauges) external;

    function internal_bribes(address _gauge) external view returns (address);
    function external_bribes(address _gauge) external view returns (address);

    function usedWeights(uint id) external view returns(uint);
    function lastVoted(uint id) external view returns(uint);
    function poolVote(uint id, uint _index) external view returns(address _pair);
    function votes(uint id, address _pool) external view returns(uint votes);
    function poolVoteLength(uint tokenId) external view returns(uint);
    
    function length() external view returns (uint);
    
}