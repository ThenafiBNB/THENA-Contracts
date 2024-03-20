// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


import '../interfaces/IBribeAPI.sol';
import '../interfaces/IGaugeAPI.sol';
import '../interfaces/IGaugeFactory.sol';
import '../interfaces/IERC20Full.sol';
import '../interfaces/IMinter.sol';
import '../interfaces/IPair.sol';
import '../interfaces/IPairInfo.sol';
import '../interfaces/IPairFactory.sol';
import '../interfaces/IVoter.sol';
import '../interfaces/IVotingEscrow.sol';

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


interface IHypervisor{
    function pool() external view returns(address);
    function getTotalAmounts() external view returns(uint tot0,uint tot1);
}



interface IDefiEdgeFactory{
    function isValidStrategy(address) external view returns(bool);
}

interface IAlgebraFactory{
    function poolByPair(address, address) external view returns(address);
}

contract PairAPI is Initializable {


    struct PairInfo {
        // pair info
        address pair_address; 			// pair contract address
        uint decimals; 			        // pair decimals
        PoolType pooltype; 				// pair pool type 
        uint total_supply; 			    // pair tokens supply
    
        // token pair info
        address token0; 				// pair 1st token address
        string token0_symbol; 			// pair 1st token symbol
        uint token0_decimals; 		    // pair 1st token decimals
        uint reserve0; 			        // pair 1st token reserves (nr. of tokens in the contract)

        address token1; 				// pair 2nd token address
        string token1_symbol;           // pair 2nd token symbol
        uint token1_decimals;    		// pair 2nd token decimals
        uint reserve1; 			        // pair 2nd token reserves (nr. of tokens in the contract)

        // pairs gauge
        address gauge; 				    // pair gauge address
        uint gauge_total_supply; 		// pair staked tokens (less/eq than/to pair total supply)
        address fee; 				    // pair fees contract address
        address bribe; 				    // pair bribes contract address
        uint emissions; 			    // pair emissions (per second)
        address emissions_token; 		// pair emissions token address
        uint emissions_token_decimals; 	// pair emissions token decimals

    }

    struct UserInfo {
        
        // User deposit
        
        address pair_address; 			// pair contract address
        uint claimable0;                // claimable 1st token from fees (for unstaked positions)
        uint claimable1; 			    // claimable 2nd token from fees (for unstaked positions)
        uint account_lp_balance; 		// account LP tokens balance
        uint account_gauge_balance;     // account pair staked in gauge balance
        uint account_gauge_earned; 		// account earned emissions for this pair
    }


    struct tokenBribe {
        address token;
        uint8 decimals;
        uint256 amount;
        string symbol;
    }
    

    struct pairBribeEpoch {
        uint256 epochTimestamp;
        uint256 totalVotes;
        address pair;
        tokenBribe[] bribes;
    }

    // stable/volatile classic x*y=k, CL = conc. liquidity algebra
    enum PoolType {STABLE, VOLATILE, CL}

    uint256 public constant MAX_PAIRS = 1000;
    uint256 public constant MAX_EPOCHS = 200;
    uint256 public constant MAX_REWARDS = 16;
    uint256 public constant WEEK = 7 * 24 * 60 * 60;


    IPairFactory public pairFactory;
    IAlgebraFactory public algebraFactory;
    IVoter public voter;

    address public underlyingToken;
    address[] public defiEdgeFactory;

    address public owner;


    event Owner(address oldOwner, address newOwner);
    event Voter(address oldVoter, address newVoter);
    event WBF(address oldWBF, address newWBF);

    


    constructor() {}

    function initialize(address _voter) initializer public {
  
        owner = msg.sender;

        voter = IVoter(_voter);

        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();

        algebraFactory = IAlgebraFactory(address(0x306F06C147f064A010530292A1EB6737c3e378e4));
        defiEdgeFactory.push(0xB4B715a85B552381a82570a0bb4392d2c77bA883);
        defiEdgeFactory.push(0x0d190eD9033dFA2d6F3340f77A2068D92443BFfE);
        defiEdgeFactory.push(0x77E8526f3399f8C9e1125CCc893512D7F6b85709);
        defiEdgeFactory.push(0x3D823753B00DaEC603Ea7c1358F91641DC8E14B2);
        
    }


    // valid only for sAMM and vAMM
    function getAllPair(uint _amounts, uint _offset) external view returns(PairInfo[] memory Pairs){

        
        require(_amounts <= MAX_PAIRS, 'too many pair');

        Pairs = new PairInfo[](_amounts);
        
        uint i = _offset;
        uint totPairs = pairFactory.allPairsLength();
        address _pair;

        for(i; i < _offset + _amounts; i++){
            // if totalPairs is reached, break.
            if(i == totPairs) {
                break;
            }
            _pair = pairFactory.allPairs(i);
            Pairs[i - _offset] = _pairAddressToInfo(_pair);
        }
    }

    function getMultiplePair(address[] calldata pairs) external view returns(PairInfo[] memory Pairs){
        require(pairs.length <= MAX_PAIRS, 'too many pair');
        Pairs = new PairInfo[](pairs.length );
        address _pair;
        for(uint256 i = 0; i < pairs.length; i++){
            _pair = pairs[i];
            Pairs[i] = _pairAddressToInfo(_pair);
        }
    }


    function getPairAccount(address _pair, address _account) external view returns(UserInfo memory _UserInfo){
        return _pairAddressForAccount(_pair, _account);
    }

    // backward compatibility
    function getPair(address _pair, address /*account*/) external view returns(PairInfo memory _PairInfo){
        return _pairAddressToInfo(_pair);
    }

    function getPairSingle(address _pair) external view returns(PairInfo memory _PairInfo){
        return _pairAddressToInfo(_pair);
    }

    function _pairAddressForAccount(address _pair, address _account) internal view returns(UserInfo memory _UserInfo) {

        IPair ipair = IPair(_pair); 
         
        IGaugeAPI _gauge = IGaugeAPI(voter.gauges(_pair));
        uint accountGaugeLPAmount = 0;
        uint earned = 0;
        
        if(address(_gauge) != address(0)){
            if(_account != address(0)){
                accountGaugeLPAmount = _gauge.balanceOf(_account);
                earned = _gauge.earned(_account);
            } else {
                accountGaugeLPAmount = 0;
                earned = 0;
            }
        }

        // checkout is v2 or v3? if v3 then load algebra pool 
        bool _type = IPairFactory(pairFactory).isPair(_pair);
        
        // Account Info
        _UserInfo.pair_address = _pair;
        _UserInfo.claimable0 = _type == false ? 0 : ipair.claimable0(_account);
        _UserInfo.claimable1 = _type == false ? 0 : ipair.claimable1(_account);
        _UserInfo.account_lp_balance = IERC20(_pair).balanceOf(_account);
        _UserInfo.account_gauge_balance = accountGaugeLPAmount;
        _UserInfo.account_gauge_earned = earned;
        
    }

    function _pairAddressToInfo(address _pair) internal view returns(PairInfo memory _PairInfo) {

        IPair ipair = IPair(_pair); 
        address token_0 = ipair.token0();
        address token_1 = ipair.token1();
        uint r0;
        uint r1;
        

        // checkout is v2 or v3? if v3 then load algebra pool 
        bool _type = IPairFactory(pairFactory).isPair(_pair);
        PoolType _pooltype;
        
        if(_type == false){
            
            // not a solidly pool, check wheter is Gamma or DefiEdge
            // hypervisor totalAmounts = algebra.pool + gamma.unused
            // DeFiEdge is reserve 0 and reserve 1
            bool status;
            for(uint i = 0; i < defiEdgeFactory.length; i++){
                status = IDefiEdgeFactory(defiEdgeFactory[i]).isValidStrategy(_pair);
                if(status) break;
            } 

            if(status == false) (r0,r1) = IHypervisor(_pair).getTotalAmounts();
            else {
                r0 = IPairInfo(_pair).reserve0();
                r1 = IPairInfo(_pair).reserve1();
            } 
            _pooltype = PoolType(2);
        } else {
            (r0,r1,) = ipair.getReserves();
            _pooltype = ipair.isStable() == true ? PoolType(0) : PoolType(1);
        }

        IGaugeAPI _gauge = IGaugeAPI(voter.gauges(_pair));
        uint gaugeTotalSupply = 0;
        uint emissions = 0;
        

        if(address(_gauge) != address(0)){
            gaugeTotalSupply = _gauge.totalSupply();
            emissions = _gauge.rewardRate();
        }
        

        // Pair General Info
        _PairInfo.pair_address = _pair;
        _PairInfo.decimals = ipair.decimals();
        _PairInfo.pooltype = _pooltype;
        _PairInfo.total_supply = ipair.totalSupply();        
        
        // Token0 Info
        _PairInfo.token0 = token_0;
        _PairInfo.token0_decimals = IERC20(token_0).decimals();
        _PairInfo.token0_symbol = IERC20(token_0).symbol();
        _PairInfo.reserve0 = r0;

        // Token1 Info
        _PairInfo.token1 = token_1;
        _PairInfo.token1_decimals = IERC20(token_1).decimals();
        _PairInfo.token1_symbol = IERC20(token_1).symbol();
        _PairInfo.reserve1 = r1;

        // Pair's gauge Info
        _PairInfo.gauge = address(_gauge);
        _PairInfo.gauge_total_supply = gaugeTotalSupply;
        _PairInfo.emissions = emissions;
        _PairInfo.emissions_token = underlyingToken;
        _PairInfo.emissions_token_decimals = IERC20(underlyingToken).decimals();
        
        // external address
        _PairInfo.fee = voter.internal_bribes(address(_gauge)); 				    
        _PairInfo.bribe = voter.external_bribes(address(_gauge)); 				    

        
    }


    function getPairBribe(uint _amounts, uint _offset, address _pair) external view returns(pairBribeEpoch[] memory _pairEpoch){

        require(_amounts <= MAX_EPOCHS, 'too many epochs');

        _pairEpoch = new pairBribeEpoch[](_amounts);

        address _gauge = voter.gauges(_pair);
        if(_gauge == address(0)) return _pairEpoch;

        IBribeAPI bribe  = IBribeAPI(voter.external_bribes(_gauge));

        // check bribe and checkpoints exists
        if(address(0) == address(bribe)) return _pairEpoch;
        
      
        // scan bribes
        // get latest balance and epoch start for bribes
        uint _epochStartTimestamp = bribe.firstBribeTimestamp();

        // if 0 then no bribe created so far
        if(_epochStartTimestamp == 0){
            return _pairEpoch;
        }

        uint _supply;
        uint i = _offset;

        for(i; i < _offset + _amounts; i++){
            
            _supply            = bribe.totalSupplyAt(_epochStartTimestamp);
            _pairEpoch[i-_offset].epochTimestamp = _epochStartTimestamp;
            _pairEpoch[i-_offset].pair = _pair;
            _pairEpoch[i-_offset].totalVotes = _supply;
            _pairEpoch[i-_offset].bribes = _bribe(_epochStartTimestamp, address(bribe));
            
            _epochStartTimestamp += WEEK;

        }

    }

    function _bribe(uint _ts, address _br) internal view returns(tokenBribe[] memory _tb){

        IBribeAPI _wb = IBribeAPI(_br);
        uint tokenLen = _wb.rewardsListLength();

        _tb = new tokenBribe[](tokenLen);

        uint k;
        uint _rewPerEpoch;
        IERC20 _t;
        for(k = 0; k < tokenLen; k++){
            _t = IERC20(_wb.rewardTokens(k));
            IBribeAPI.Reward memory _reward = _wb.rewardData(address(_t), _ts);
            _rewPerEpoch = _reward.rewardsPerEpoch;
            if(_rewPerEpoch > 0){
                _tb[k].token = address(_t);
                _tb[k].symbol = _t.symbol();
                _tb[k].decimals = _t.decimals();
                _tb[k].amount = _rewPerEpoch;
            } else {
                _tb[k].token = address(_t);
                _tb[k].symbol = _t.symbol();
                _tb[k].decimals = _t.decimals();
                _tb[k].amount = 0;
            }
        }
    }


    function setOwner(address _owner) external {
        require(msg.sender == owner, 'not owner');
        require(_owner != address(0), 'zeroAddr');
        owner = _owner;
        emit Owner(msg.sender, _owner);
    }


    function setVoter(address _voter) external {
        require(msg.sender == owner, 'not owner');
        require(_voter != address(0), 'zeroAddr');
        address _oldVoter = address(voter);
        voter = IVoter(_voter);
        
        // update variable depending on voter
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();

        emit Voter(_oldVoter, _voter);
    }

    function pushdefiedgefactory(address factory) external {
        require(msg.sender == owner, 'not owner');
        defiEdgeFactory.push(factory);
    }


}