// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../chainlink/AutomationCompatible.sol";
import "../interfaces/IMinter.sol";
import "../interfaces/IVoter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract EpochController is AutomationCompatibleInterface, Ownable  {

    address public automationRegistry;

    address public minter;
    address public voter;

    
    // last time automation was called
    uint256 public lastCalledAt;
    // last time automation completed all distribution
    uint256 public lastCompletedAt;

    // track pool length
    uint256 public index;
    // max number of gauges for batch (used to limit gas on each call)
    uint256 public maxLoops;

    uint256 constant public WEEK = 7 * 86400;


    constructor() {
        minter = address(0x86069FEb223EE303085a1A505892c9D4BdBEE996);
        voter = address(0x3A1D0952809F4948d15EBCe8d345962A282C4fCb);
        automationRegistry = address(0x02777053d6764996e594c3E88AF1D58D5363a2e6);
        maxLoops = 10;
        lastCalledAt = block.timestamp;
        lastCompletedAt = block.timestamp / WEEK * WEEK;
    }


    function checkUpkeep(bytes memory /*checkdata*/) public view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        upkeepNeeded = IMinter(minter).check() || lastCompletedAt + WEEK <= block.timestamp;
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        require(msg.sender == automationRegistry || msg.sender == owner(), 'cannot execute');
        bool upkeepNeeded = IMinter(minter).check() || lastCompletedAt + WEEK <= block.timestamp;
        require(upkeepNeeded, "condition not met");

        uint length = IVoter(voter).length() - 1;
        uint end = index + maxLoops - 1;

        if(end > length) end = length;

        IVoter(voter).distribute(index, end);    
        
        index += maxLoops;       
        if(index >= length) {
            lastCalledAt = block.timestamp;
            lastCompletedAt = block.timestamp / WEEK * WEEK;
            index = 0;
        } 
    }





    function setIndex(uint _index) external onlyOwner {
        index = _index;
    }



    function setMaxLoops(uint _maxLoops) external onlyOwner {
        maxLoops = _maxLoops;
    }



    function setAutomationRegistry(address _automationRegistry) external onlyOwner {
        require(_automationRegistry != address(0));
        automationRegistry = _automationRegistry;
    }

    function setVoter(address _voter) external onlyOwner {
        require(_voter != address(0));
        voter = _voter;
    }

    function setMinter(address _minter ) external onlyOwner {
        require(_minter != address(0));
        minter = _minter;
    }



}