// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import '../interfaces/IPermissionsRegistry.sol';
import '../interfaces/IGaugeFactoryV2.sol';
import '../GaugeV2_CL.sol';
import "../CLFeesVault.sol";

import "hardhat/console.sol";

interface IGauge{
    function setDistribution(address _distro) external;
    function activateEmergencyMode() external;
    function stopEmergencyMode() external;
    function setInternalBribe(address intbribe) external;
    function setRewarderPid(uint256 pid) external;
    function setGaugeRewarder(address _gr) external;
    function setFeeVault(address _feeVault) external;
}


contract GaugeFactoryV2_CL is IGaugeFactory, OwnableUpgradeable {
    address public last_gauge;
    address public last_feeVault;
    address public permissionsRegistry;
    address public gammaFeeRecipient;

    address[] internal __gauges;
    constructor() {}
    
    function initialize(address _permissionsRegistry, address _gammaFeeRecipient) initializer  public {
        __Ownable_init();   //after deploy ownership to multisig
        permissionsRegistry = _permissionsRegistry;
        gammaFeeRecipient = _gammaFeeRecipient;
    }

    function gauges() external view returns(address[] memory) {
        return __gauges;
    }

    function length() external view returns(uint) {
        return __gauges.length;
    }

    function createGaugeV2(address _rewardToken,address _ve,address _token,address _distribution, address _internal_bribe, address _external_bribe, bool /*_isPair*/) external returns (address) {
    
        last_feeVault = address( new CLFeesVault(_token, permissionsRegistry, _distribution, gammaFeeRecipient) );

        last_gauge = address(new GaugeV2_CL(_rewardToken,_ve,_token,_distribution,_internal_bribe,_external_bribe, last_feeVault) );

        __gauges.push(last_gauge);

        return last_gauge;
    }


    modifier onlyAllowed() {
        require(IPermissionsRegistry(permissionsRegistry).hasRole("GAUGE_ADMIN",msg.sender), 'ERR: GAUGE_ADMIN');
        _;
    }

    modifier EmergencyCouncil() {
        require( msg.sender == IPermissionsRegistry(permissionsRegistry).emergencyCouncil() );
        _;
    }
   


    function activateEmergencyMode( address[] memory _gauges) external EmergencyCouncil {
        uint i = 0;
        for ( i ; i < _gauges.length; i++){
            IGauge(_gauges[i]).activateEmergencyMode();
        }
    }

    function stopEmergencyMode( address[] memory _gauges) external EmergencyCouncil {
        uint i = 0;
        for ( i ; i < _gauges.length; i++){
            IGauge(_gauges[i]).stopEmergencyMode();
        }
    }
    

    function setRegistry(address _registry) external onlyAllowed {
        require(_registry != address(0));
        permissionsRegistry = _registry;
    }


    function setRewarderPid( address[] memory _gauges, uint[] memory _pids) external onlyAllowed {
        require(_gauges.length == _pids.length);
        uint i = 0;
        for ( i ; i < _gauges.length; i++){
            IGauge(_gauges[i]).setRewarderPid(_pids[i]);
        }
    }

    function setGaugeRewarder( address[] memory _gauges, address[] memory _rewarder) external onlyAllowed {
        require(_gauges.length == _rewarder.length);
        uint i = 0;
        for ( i ; i < _gauges.length; i++){
            IGauge(_gauges[i]).setGaugeRewarder(_rewarder[i]);
        }
    }

    function setDistribution(address[] memory _gauges,  address distro) external onlyAllowed {
        uint i = 0;
        for ( i ; i < _gauges.length; i++){
            IGauge(_gauges[i]).setDistribution(distro);
        }
    }


    function setInternalBribe(address[] memory _gauges,  address[] memory int_bribe) external onlyAllowed {
        require(_gauges.length == int_bribe.length);
        uint i = 0;
        for ( i ; i < _gauges.length; i++){
            IGauge(_gauges[i]).setInternalBribe(int_bribe[i]);
        }
    }

    function setGaugeFeeVault(address[] memory _gauges,  address _vault) external onlyAllowed {
        require(_vault != address(0));
        uint i = 0;
        for ( i ; i < _gauges.length; i++){
            require(_gauges[i] != address(0));
            IGauge(_gauges[i]).setFeeVault(_vault);
        }
    }

    function setGammaDefaultFeeRecipient(address _rec) external onlyAllowed {
        require(_rec != address(0));
        gammaFeeRecipient = _rec;
    }

}
