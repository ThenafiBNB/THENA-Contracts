// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../Bribes.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import '../interfaces/IPermissionsRegistry.sol';

interface IBribe {
    function addReward(address) external;
    function setVoter(address _Voter) external;
    function setMinter(address _Voter) external;
    function setOwner(address _Voter) external;
    function emergencyRecoverERC20(address tokenAddress, uint256 tokenAmount) external;
    function recoverERC20AndUpdateData(address tokenAddress, uint256 tokenAmount) external;
}

contract BribeFactoryV3 is OwnableUpgradeable {
    address public last_bribe;
    address[] internal _bribes;
    address public voter;

    address[] public defaultRewardToken;

    IPermissionsRegistry public permissionsRegistry;

    modifier onlyAllowed() {
        require(owner() == msg.sender || permissionsRegistry.hasRole("BRIBE_ADMIN",msg.sender), 'ERR: BRIBE_ADMIN');
        _;
    }

    constructor() {}
    function initialize(address _voter, address _permissionsRegistry) initializer  public {
        __Ownable_init();   //after deploy ownership to multisig
        voter = _voter;
        
        //bribe default tokens
        defaultRewardToken.push(address(0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11));   // $the
        defaultRewardToken.push(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));   // $wbnb
        defaultRewardToken.push(address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d));   // $usdc
        defaultRewardToken.push(address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56));   // $busd
        defaultRewardToken.push(address(0x55d398326f99059fF775485246999027B3197955));   // $usdt

        // registry to check accesses
        permissionsRegistry = IPermissionsRegistry(_permissionsRegistry);

    }


    /// @notice create a bribe contract
    /// @dev    _owner must be thenaTeamMultisig
    function createBribe(address _owner,address _token0,address _token1, string memory _type) external returns (address) {
        require(msg.sender == voter || msg.sender == owner(), 'only voter');

        Bribe lastBribe = new Bribe(_owner,voter,address(this), _type);

        if(_token0 != address(0)) lastBribe.addRewardToken(_token0);  
        if(_token1 != address(0)) lastBribe.addRewardToken(_token1); 

        lastBribe.addRewardTokens(defaultRewardToken);      
         
        last_bribe = address(lastBribe);
        _bribes.push(last_bribe);
        return last_bribe;
    }


    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    ONLY OWNER
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */


    /// @notice set the bribe factory voter
    function setVoter(address _Voter) external {
        require(owner() == msg.sender, 'not owner');
        require(_Voter != address(0));
        voter = _Voter;
    }

    
    /// @notice set the bribe factory permission registry
    function setPermissionsRegistry(address _permReg) external {
        require(owner() == msg.sender, 'not owner');
        require(_permReg != address(0));
        permissionsRegistry = IPermissionsRegistry(_permReg);
    }

    /// @notice set the bribe factory permission registry
    function pushDefaultRewardToken(address _token) external {
        require(owner() == msg.sender, 'not owner');
        require(_token != address(0));
        defaultRewardToken.push(_token);    
    }

    
    /// @notice set the bribe factory permission registry
    function removeDefaultRewardToken(address _token) external {
        require(owner() == msg.sender, 'not owner');
        require(_token != address(0));
        uint i = 0;
        for(i; i < defaultRewardToken.length; i++){
            if(defaultRewardToken[i] == _token){
                defaultRewardToken[i] = defaultRewardToken[defaultRewardToken.length -1];
                defaultRewardToken.pop();
                break;
            }
        }    
    }

    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    ONLY OWNER or BRIBE ADMIN
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    /// @notice Add a reward token to a given bribe
    function addRewardToBribe(address _token, address __bribe) external onlyAllowed {
        IBribe(__bribe).addReward(_token);
    }

    /// @notice Add multiple reward token to a given bribe
    function addRewardsToBribe(address[] memory _token, address __bribe) external onlyAllowed {
        uint i = 0;
        for ( i ; i < _token.length; i++){
            IBribe(__bribe).addReward(_token[i]);
        }
    }

    /// @notice Add a reward token to given bribes
    function addRewardToBribes(address _token, address[] memory __bribes) external onlyAllowed {
        uint i = 0;
        for ( i ; i < __bribes.length; i++){
            IBribe(__bribes[i]).addReward(_token);
        }

    }

    /// @notice Add multiple reward tokens to given bribes
    function addRewardsToBribes(address[][] memory _token, address[] memory __bribes) external onlyAllowed {
        uint i = 0;
        uint k;
        for ( i ; i < __bribes.length; i++){
            address _br = __bribes[i];
            for(k = 0; k < _token.length; k++){
                IBribe(_br).addReward(_token[i][k]);
            }
        }

    }

    /// @notice set a new voter in given bribes
    function setBribeVoter(address[] memory _bribe, address _voter) external onlyOwner {
        uint i = 0;
        for(i; i< _bribe.length; i++){
            IBribe(_bribe[i]).setVoter(_voter);
        }
    }

    /// @notice set a new minter in given bribes
    function setBribeMinter(address[] memory _bribe, address _minter) external onlyOwner {
        uint i = 0;
        for(i; i< _bribe.length; i++){
            IBribe(_bribe[i]).setMinter(_minter);
        }
    }

    /// @notice set a new owner in given bribes
    function setBribeOwner(address[] memory _bribe, address _owner) external onlyOwner {
        uint i = 0;
        for(i; i< _bribe.length; i++){
            IBribe(_bribe[i]).setOwner(_owner);
        }
    }

    /// @notice recover an ERC20 from bribe contracts.
    function recoverERC20From(address[] memory _bribe, address[] memory _tokens, uint[] memory _amounts) external onlyOwner {
        uint i = 0;
        require(_bribe.length == _tokens.length, 'mismatch len');
        require(_tokens.length == _amounts.length, 'mismatch len');

        for(i; i< _bribe.length; i++){
            if(_amounts[i] > 0) IBribe(_bribe[i]).emergencyRecoverERC20(_tokens[i], _amounts[i]);
        }
    }

     /// @notice recover an ERC20 from bribe contracts and update. 
    function recoverERC20AndUpdateData(address[] memory _bribe, address[] memory _tokens, uint[] memory _amounts) external onlyOwner {
        uint i = 0;
        require(_bribe.length == _tokens.length, 'mismatch len');
        require(_tokens.length == _amounts.length, 'mismatch len');

        for(i; i< _bribe.length; i++){
            if(_amounts[i] > 0) IBribe(_bribe[i]).emergencyRecoverERC20(_tokens[i], _amounts[i]);
        }
    }

}