// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AutomationCompatibleInterface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
interface IVoter {
    function length() external view returns (uint);
    function pools(uint index) external view returns (address);
    function isAlive(address _gauge) external view returns (bool);
    function gauges(address _pool) external view returns (address);
    function distributeFees(address[] memory _gauges) external;
    
}


contract DistributeFees is AutomationCompatibleInterface, OwnableUpgradeable {

    // lock checkUpkeep during performupkeep
    bool internal lock;

    // last time automation was called
    //uint256 public lastCalledAt;
    // last time automation completed all distribution
    uint256 public lastCompletedAt;
    // delta from last lastCompletedAt and the previous
    uint256 public deltaTimestamp;
    // track pool length
    uint256 public index;
    // voter interface
    IVoter public voter;
    // max number of gauges for batch (used to limit gas on each call)
    uint256 public maxLoops;

    // remove a gauge from distribution, used in case of gauge with tax token not whitelisted and blocking automation
    mapping(address => bool) public lockedGauge;

    constructor() {}

    function initialize(address _voter, uint256 _maxLoops) public initializer {
          voter = IVoter(_voter);
        maxLoops = _maxLoops;
        lockedGauge[address(0xd9694Bb4538596dF94Cc6A76145560097865Bba4)] = true;
        // init with last automation run data
        lastCompletedAt = 1701093914;
        deltaTimestamp = 259219;
        lock = false;

    }

    function lockGauge(address[] memory gauges) external onlyOwner {
        uint i = 0;
        for(i ; i < gauges.length; i++){
            lockedGauge[gauges[i]] = true;
        }
    }

    function unlockGauge(address[] memory gauges) external onlyOwner {
        uint i = 0;
        for(i ; i < gauges.length; i++){
            lockedGauge[gauges[i]] = false;
        }
    }

    function setIndex(uint256 _idx) public onlyOwner {
        index = _idx;
    }

    function setMaxLoops(uint256 _maxLoops) public onlyOwner {
        maxLoops = _maxLoops;
    }
    
    function getWeekSection(uint256 timestamp) public pure returns(uint8 sector){
        return _getWeekSection(timestamp);
    }

    function _getWeekSection(uint256 timestamp) internal pure returns (uint8 sector) {
        uint256 day = (timestamp / 86400 + 4) % 7;
        uint256 hour = (timestamp / 3600) % 24;

        //Divide the week in 3 "sections": Mon 14:00 -> Wed 18:00, Wed 18:00 -> Fri 14:00, Fri 14:00 -> Mon 14:00
        return ((day == 1 && hour >= 14) || day == 2 || (day == 3 && hour < 18)) ? 0 : ((day == 3 && hour >= 18) || day == 4 || (day == 5 && hour < 14))? 1 : 2;
    }

    function checkUpkeep(bytes memory /*checkdata*/) public view override returns (bool upkeepNeeded, bytes memory performData) {
        //upkeepneeded should be true monday, friday at 14 UTC, wednesday at 18UTC
        //If more than 3 days have passed since lastCompletedAt we must update!
        if (block.timestamp - lastCompletedAt > 3 days) {
            upkeepNeeded = true;
        } else {
            //Miners use UTC time as a timestamp -> should check if hour is past 14 UTC (monday, friday) or 18UTC (friday)
            //We are in the same week, compare the section!
            upkeepNeeded = (_getWeekSection(block.timestamp) != _getWeekSection(lastCompletedAt));
        }
        if(lock) upkeepNeeded = false;
        
        
        address[] memory tempGauges = new address[](maxLoops);
        uint256 _index = index;
        uint256 i = 0;
        for (; i < maxLoops && _index < voter.length(); i++) {
            address gauge = address(0x0);
            gauge = voter.gauges(voter.pools(_index));

            // check wheter a gauge is alive and != address(0), else sub 1 by i. We need 20 clean gauge for batch
            if(gauge != address(0) && voter.isAlive(gauge) && !lockedGauge[gauge]) tempGauges[i] = gauge;
            else i == 0? i = 0 : i--;
            
            _index++;
        }
        
        if(i >= maxLoops) {
            performData = abi.encode(tempGauges, _index, i);
        } else {
            address[] memory gauges = new address[](i);
            for(uint256 j = 0; j < i; j++) {
                gauges[j] = tempGauges[j];
            }
            if(gauges.length > 0) performData = abi.encode(gauges, _index, i);
        }




    }

    function performUpkeep(bytes calldata performData) external override {

        //lastCalledAt = block.timestamp;

        if(block.timestamp - lastCompletedAt <= 3 days && (_getWeekSection(block.timestamp) ==_getWeekSection(lastCompletedAt)) && lock ) {
            revert("!checkUpkeep");
        }
        lock = true;
        address[] memory tempGauges;
        uint256 i;
        (tempGauges, index, i) = abi.decode(performData, (address[], uint256, uint256));

        if(tempGauges.length > 0) voter.distributeFees(tempGauges);
        
        if(index >= voter.length()) {
            deltaTimestamp = block.timestamp - lastCompletedAt;
            lastCompletedAt = block.timestamp;
            index = 0;
        }
        
        lock = false;
    }
}