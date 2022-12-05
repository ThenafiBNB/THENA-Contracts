// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IBribeFactory.sol";
import '../InternalBribe.sol';
import '../ExternalBribe.sol';

contract BribeFactory is IBribeFactory {
    address public last_internal_bribe;
    address public last_external_bribe;

    function createInternalBribe(address[] memory allowedRewards) external returns (address) {
        last_internal_bribe = address(new InternalBribe(msg.sender, allowedRewards));
        return last_internal_bribe;
    }

    function createExternalBribe(address[] memory allowedRewards) external returns (address) {
        last_external_bribe = address(new ExternalBribe(msg.sender, allowedRewards));
        return last_external_bribe;
    }
}
