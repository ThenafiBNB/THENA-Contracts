// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '../interfaces/IGaugeFactoryV2.sol';
import '../GaugeV2_1.sol';

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract GaugeFactoryV2_1 is IGaugeFactory, OwnableUpgradeable {
    address public last_gauge;

    constructor() {}

    function initialize() initializer  public {
        __Ownable_init();
    }

    function createGaugeV2(address _rewardToken,address _ve,address _token,address _distribution, address _internal_bribe, address _external_bribe, bool _isPair) external returns (address) {
        last_gauge = address(new GaugeV21(_rewardToken,_ve,_token,_distribution,_internal_bribe,_external_bribe,_isPair) );
        return last_gauge;
    }

}
