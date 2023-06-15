// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import './interfaces/IBribe.sol';
import './interfaces/IBribeFactory.sol';
import './interfaces/IGauge.sol';
import './interfaces/IGaugeFactory.sol';
import './interfaces/IERC20.sol';
import './interfaces/IMinter.sol';
import './interfaces/IPairInfo.sol';
import './interfaces/IPairFactory.sol';
import './interfaces/IVotingEscrow.sol';
import './interfaces/IPermissionsRegistry.sol';
import './interfaces/IAlgebraFactory.sol';

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";


interface IHypervisor {
    function pool() external view returns(address);
}

contract VoterV3 is OwnableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    bool internal initflag;

    address internal _ve;                                         // the ve token that governs these contracts
    address public factory;                                     // classic stable and volatile Pair Factory
    address[] internal _factories;                                 // Array with all the pair factories
    address internal base;                                      // $the token
    address public gaugefactory;                                // gauge factory
    address[] internal _gaugeFactories;                            // array with all the gauge factories
    address public bribefactory;                                // bribe factory (internal and external)
    address public minter;                                      // minter mints $the each epoch
    address public permissionRegistry;                          // registry to check accesses
    address[] public pools;                                     // all pools viable for incentives


    uint internal index;                                        // gauge index
    uint internal constant DURATION = 7 days;                   // rewards are released over 7 days
    uint public VOTE_DELAY;                                     // delay between votes in seconds
    uint public constant MAX_VOTE_DELAY = 7 days;               // Max vote delay allowed


    mapping(address => uint) internal supplyIndex;              // gauge    => index
    mapping(address => uint) public claimable;                  // gauge    => claimable $the
    mapping(address => address) public gauges;                  // pool     => gauge
    mapping(address => uint) public gaugesDistributionTimestamp;// gauge    => last Distribution Time
    mapping(address => address) public poolForGauge;            // gauge    => pool
    mapping(address => address) public internal_bribes;         // gauge    => internal bribe (only fees)
    mapping(address => address) public external_bribes;         // gauge    => external bribe (real bribes)
    mapping(uint => mapping(address => uint256)) public votes;  // nft      => pool     => votes
    mapping(uint => address[]) public poolVote;                 // nft      => pools
    mapping(uint => mapping(address => uint)) internal weightsPerEpoch; // timestamp => pool => weights
    mapping(uint => uint) internal totalWeightsPerEpoch;        // timestamp => total weights
    mapping(uint => uint) public lastVoted;                     // nft      => timestamp of last vote
    mapping(address => bool) public isGauge;                    // gauge    => boolean [is a gauge?]
    mapping(address => bool) public isWhitelisted;              // token    => boolean [is an allowed token?]
    mapping(address => bool) public isAlive;                    // gauge    => boolean [is the gauge alive?]
    mapping(address => bool) public isFactory;                  // factory  => boolean [the pair factory exists?]
    mapping(address => bool) public isGaugeFactory;             // g.factory=> boolean [the gauge factory exists?]

    event GaugeCreated(address indexed gauge, address creator, address internal_bribe, address indexed external_bribe, address indexed pool);
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event Voted(address indexed voter, uint tokenId, uint256 weight);
    event Abstained(uint indexed tokenId, uint256 weight);
    event NotifyReward(address indexed sender, address indexed reward, uint amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event Attach(address indexed owner, address indexed gauge, uint tokenId);
    event Detach(address indexed owner, address indexed gauge, uint tokenId);
    event Whitelisted(address indexed whitelister, address indexed token);
    event RemovedFromWhitelist(address indexed blacklister, address indexed token);

    constructor() {}

    function initialize(address __ve, address _factory, address  _gauges, address _bribes) initializer public {
        __Ownable_init();
        __ReentrancyGuard_init();

        _ve = __ve;
        base = IVotingEscrow(__ve).token();

        factory = _factory;
        _factories.push(factory);
        isFactory[factory] = true;

        gaugefactory = _gauges;
        _gaugeFactories.push(_gauges);
        isGaugeFactory[_gauges] = true;

        bribefactory = _bribes;

        minter = msg.sender;
        permissionRegistry = msg.sender;

        VOTE_DELAY = 0;
        initflag = false;
    }

 
    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    MODIFIERS
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    modifier VoterAdmin() {
        require(IPermissionsRegistry(permissionRegistry).hasRole("VOTER_ADMIN",msg.sender), 'VOTER_ADMIN');
        _;
    }

    modifier Governance() {
        require(IPermissionsRegistry(permissionRegistry).hasRole("GOVERNANCE",msg.sender), 'GOVERNANCE');
        _;
    }

    
    /// @notice initialize the voter contract 
    /// @param  _tokens array of tokens to whitelist
    /// @param  _minter the minter of $the
    function initVoter(address[] memory _tokens, address _permissionsRegistry, address _minter) external {
        require(msg.sender == minter || IPermissionsRegistry(permissionRegistry).hasRole("VOTER_ADMIN",msg.sender));
        require(!initflag);
        for (uint i = 0; i < _tokens.length; i++) {
            _whitelist(_tokens[i]);
        }
        minter = _minter;
        permissionRegistry = _permissionsRegistry;
        initflag = true;
    }

    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    VoterAdmin
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    /// @notice set vote delay in seconds
    function setVoteDelay(uint _delay) external VoterAdmin {
        require(_delay != VOTE_DELAY, "already set");
        require(_delay <= MAX_VOTE_DELAY, "max delay");
        VOTE_DELAY = _delay;
    }

    /// @notice Set a new Minter
    function setMinter(address _minter) external VoterAdmin {
        require(_minter != address(0), "addr0");
        require(_minter.code.length > 0, "!contract");
        minter = _minter;
    }

    /// @notice Set a new Bribe Factory
    function setBribeFactory(address _bribeFactory) external VoterAdmin {
        require(_bribeFactory.code.length > 0, "!contract");
        require(_bribeFactory != address(0), "addr0");
        bribefactory = _bribeFactory;
    }

    /// @notice Set a new Gauge Factory
    function setGaugeFactory(address _gaugeFactory) external VoterAdmin {
        require(_gaugeFactory.code.length > 0, "!contract");
        require(_gaugeFactory != address(0), "addr0");
        gaugefactory = _gaugeFactory;
    }

    /// @notice Set a new Pair Factory
    function setPairFactory(address _factory) external VoterAdmin {
        require(_factory.code.length > 0, "!contract");
        require(_factory != address(0), "addr0");
        factory = _factory;
    }

    /// @notice Set a new PermissionRegistry
    function setPermissionsRegistry(address _permissionRegistry) external VoterAdmin {
        require(_permissionRegistry.code.length > 0, "!contract");
        require(_permissionRegistry != address(0), "addr0");
        permissionRegistry = _permissionRegistry;
    }

    /// @notice Set a new bribes for a given gauge
    function setNewBribes(address _gauge, address _internal, address _external) external VoterAdmin {
        require(isGauge[_gauge] == true, "not a gauge");
        require(_gauge.code.length > 0, "!contract");
        _setInternalBribe(_gauge, _internal);
        _setExternalBribe(_gauge, _external);
    }

    /// @notice Set a new internal bribe for a given gauge
    function setInternalBribeFor(address _gauge, address _internal) external VoterAdmin {
        require(isGauge[_gauge], "not a gauge");
        _setInternalBribe(_gauge, _internal);
    }

    /// @notice Set a new External bribe for a given gauge
    function setExternalBribeFor(address _gauge, address _external) external VoterAdmin {
        require(isGauge[_gauge], "not a gauge");
        _setExternalBribe(_gauge, _external);
    }

    function _setInternalBribe(address _gauge, address _internal) private {
        require(_internal.code.length > 0, "!contract");
        internal_bribes[_gauge] = _internal;
    }

    function _setExternalBribe(address _gauge, address _external) private {
        require(_external.code.length > 0, "!contract");
        external_bribes[_gauge] = _external;
    }
    
 
    
    function addFactory(address _pairFactory, address _gaugeFactory) external VoterAdmin {
        require(_pairFactory != address(0), 'addr0');
        require(_gaugeFactory != address(0), 'addr0');
        require(!isFactory[_pairFactory], 'fact in');
        require(!isGaugeFactory[_gaugeFactory], 'g.fact true');
        require(_pairFactory.code.length > 0, "!contract");
        require(_gaugeFactory.code.length > 0, "!contract");

        _factories.push(_pairFactory);
        _gaugeFactories.push(_gaugeFactory);
        isFactory[_pairFactory] = true;
        isGaugeFactory[_gaugeFactory] = true;
    }

    function replaceFactory(address _pairFactory, address _gaugeFactory, uint256 _pos) external VoterAdmin {
        require(_pairFactory != address(0), 'addr0');
        require(_gaugeFactory != address(0), 'addr0');
        require(isFactory[_pairFactory], 'fact in');
        require(isGaugeFactory[_gaugeFactory], 'g.fact false');
        address oldPF = _factories[_pos];
        address oldGF = _gaugeFactories[_pos];
        isFactory[oldPF] = false;
        isGaugeFactory[oldGF] = false;

        _factories[_pos] = (_pairFactory);
        _gaugeFactories[_pos] = (_gaugeFactory);
        isFactory[_pairFactory] = true;
        isGaugeFactory[_gaugeFactory] = true;
    }

    function removeFactory(uint256 _pos) external VoterAdmin {

        address oldPF = _factories[_pos];
        address oldGF = _gaugeFactories[_pos];
        require(isFactory[oldPF], 'fact in');
        require(isGaugeFactory[oldGF], 'g.fact false');
        _factories[_pos] = address(0);
        _gaugeFactories[_pos] = address(0);
        isFactory[oldPF] = false;
        isGaugeFactory[oldGF] = false;
    }
    
    
    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    GOVERNANCE
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */
    
    
    /// @notice Whitelist a token for gauge creation
    function whitelist(address[] memory _tokens) external Governance {
        uint256 i = 0;
        for(i = 0; i < _tokens.length; i++){
            _whitelist(_tokens[i]);
        }
    }
       
    function _whitelist(address _token) private {
        require(!isWhitelisted[_token], "in");
        require(_token.code.length > 0, "!contract");
        isWhitelisted[_token] = true;
        emit Whitelisted(msg.sender, _token);
    }
    
    /// @notice Blacklist a malicious token
    function removeFromWhitelist(address[] memory _tokens) external Governance {
        uint256 i = 0;
        for(i = 0; i < _tokens.length; i++){
            _removeFromWhitelist(_tokens[i]);
        }
    }
       
    function _removeFromWhitelist(address _token) private {
        require(isWhitelisted[_token]);
        isWhitelisted[_token] = false;
        emit RemovedFromWhitelist(msg.sender, _token);
    }

    /// @notice Kill a malicious gauge 
    /// @param  _gauge gauge to kill
    function killGauge(address _gauge) external Governance {
        require(isAlive[_gauge], "killed");
        isAlive[_gauge] = false;
        claimable[_gauge] = 0;
        uint _time = _epochTimestamp();
        totalWeightsPerEpoch[_time] -= weightsPerEpoch[_time][poolForGauge[_gauge]]; 

        emit GaugeKilled(_gauge);
    }

    /// @notice Revive a killed gauge 
    /// @param  _gauge gauge to revive
    function reviveGauge(address _gauge) external Governance {
        require(!isAlive[_gauge], "alive");
        require(isGauge[_gauge], 'killed');
        isAlive[_gauge] = true;
        emit GaugeRevived(_gauge);
    }

    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    USER INTERACTION
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    
    /// @notice Reset the votes of a given TokenID
    function reset(uint256 _tokenId) external nonReentrant {
        _voteDelay(_tokenId);
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId), "!approved/Owner");
        _reset(_tokenId);
        IVotingEscrow(_ve).abstain(_tokenId);
        lastVoted[_tokenId] = _epochTimestamp() + 1;
    }

    function _reset(uint256 _tokenId) internal {
        address[] storage _poolVotes = poolVote[_tokenId];
        uint256 _poolVotesCnt = _poolVotes.length;
        uint256 _totalWeight = 0;
        uint256 _time = _epochTimestamp();

        for (uint256 i = 0; i < _poolVotesCnt; i ++) {
            address _pool = _poolVotes[i];
            uint256 _votes = votes[_tokenId][_pool];

            if (_votes != 0) {

                // if user last vote is < than epochTimestamp then votes are 0! IF not underflow occur
                if(lastVoted[_tokenId] > _time) weightsPerEpoch[_time][_pool] -= _votes;

                votes[_tokenId][_pool] -= _votes;
                
                IBribe(internal_bribes[gauges[_pool]]).withdraw(uint256(_votes), _tokenId);
                IBribe(external_bribes[gauges[_pool]]).withdraw(uint256(_votes), _tokenId);

                // if is alive remove _votes, else don't because we already done it in killGauge()
                if(isAlive[gauges[_pool]]) _totalWeight += _votes;

                
                emit Abstained(_tokenId, _votes);
            }
        }

        
        // if user last vote is < than epochTimestamp then _totalWeight is 0! IF not underflow occur
        if(lastVoted[_tokenId] < _time) _totalWeight = 0;
        
        totalWeightsPerEpoch[_time] -= _totalWeight;
        delete poolVote[_tokenId];
    }

    /// @notice Recast the saved votes of a given TokenID
    function poke(uint256 _tokenId) external nonReentrant {
        _voteDelay(_tokenId);
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId),"!approved/Owner");
        address[] memory _poolVotes = poolVote[_tokenId];
        uint256 _poolCnt = _poolVotes.length;

        uint256[] memory _weights = new uint256[](_poolCnt);

        for (uint256 i = 0; i < _poolCnt; i ++) {
            _weights[i] = votes[_tokenId][_poolVotes[i]];
        }

        _vote(_tokenId, _poolVotes, _weights);
        lastVoted[_tokenId] = _epochTimestamp() + 1;
    }

    
    /// @notice Vote for pools
    /// @param  _tokenId    veNFT tokenID used to vote
    /// @param  _poolVotes   array of LPs addresses to vote  (eg.: [sAMM usdc-usdt   , sAMM busd-usdt, vAMM wbnb-the ,...])
    /// @param  _weights    array of weights for each LPs   (eg.: [10               , 90            , 45             ,...])  
    function vote(uint256 _tokenId, address[] calldata _poolVotes, uint256[] calldata _weights) external nonReentrant {
        _voteDelay(_tokenId);
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId),"!approved/Owner");
        require(_poolVotes.length == _weights.length);
        _vote(_tokenId, _poolVotes, _weights);

        lastVoted[_tokenId] = _epochTimestamp() + 1;
    }
    
    function _vote(uint256 _tokenId, address[] memory _poolVotes, uint256[] memory _weights) internal {
        _reset(_tokenId);
        uint256 _poolCnt = _poolVotes.length;
        uint256 _weight = IVotingEscrow(_ve).balanceOfNFT(_tokenId);
        uint256 _totalVoteWeight = 0;
        uint256 _totalWeight = 0;
        uint256 _usedWeight = 0;
        uint256 _time = _epochTimestamp();


        for (uint i = 0; i < _poolCnt; i++) {
            if(isAlive[gauges[_poolVote[i]]]) _totalVoteWeight += _weights[i];
        }

        for (uint256 i = 0; i < _poolCnt; i++) {
            address _pool = _poolVotes[i];
            address _gauge = gauges[_pool];

            if (isGauge[_gauge] && isAlive[_gauge]) {
                uint256 _poolWeight = _weights[i] * _weight / _totalVoteWeight;

                require(votes[_tokenId][_pool] == 0);
                require(_poolWeight != 0);

                poolVote[_tokenId].push(_pool);
                weightsPerEpoch[_time][_pool] += _poolWeight;

                votes[_tokenId][_pool] += _poolWeight;

                IBribe(internal_bribes[_gauge]).deposit(uint256(_poolWeight), _tokenId);
                IBribe(external_bribes[_gauge]).deposit(uint256(_poolWeight), _tokenId);
                
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                emit Voted(msg.sender, _tokenId, _poolWeight);
            }
        }
        if (_usedWeight > 0) IVotingEscrow(_ve).voting(_tokenId);

        totalWeightsPerEpoch[_time] += _totalWeight;

    }

    /// @notice claim LP gauge rewards
    function claimRewards(address[] memory _gauges) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).getReward(msg.sender);
        }
    }

    /// @notice claim bribes rewards given a TokenID

    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) external {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId), "!approved/Owner");
        for (uint256 i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    /// @notice claim fees rewards given a TokenID
    function claimFees(address[] memory _fees, address[][] memory _tokens, uint _tokenId) external {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId), "!approved/Owner");
        for (uint i = 0; i < _fees.length; i++) {
            IBribe(_fees[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    /// @notice claim bribes rewards given an address
    function claimBribes(address[] memory _bribes, address[][] memory _tokens) external {
        for (uint256 i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForAddress(msg.sender, _tokens[i]);
        }
    }

    /// @notice claim fees rewards given an address
    function claimFees(address[] memory _bribes, address[][] memory _tokens) external {
        for (uint256 i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForAddress(msg.sender, _tokens[i]);
        }
    }    


    /// @notice check if user can vote
    function _voteDelay(uint256 _tokenId) internal view {
        require(block.timestamp > lastVoted[_tokenId] + VOTE_DELAY, "ERR: VOTE_DELAY");
    }



     /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    GAUGE CREATION
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */
    /// @notice create multiple gauges
    function createGauges(address[] memory _pool, uint256[] memory _gaugeTypes) external nonReentrant returns(address[] memory, address[] memory, address[] memory)  {
        require(_pool.length == _gaugeTypes.length, "len mismatch");
        require(_pool.length <= 10, "max 10");
        address[] memory _gauge = new address[](_pool.length);
        address[] memory _int = new address[](_pool.length);
        address[] memory _ext = new address[](_pool.length);

        uint256 i = 0;
        for(i; i < _pool.length; i++){
            (_gauge[i], _int[i], _ext[i]) = _createGauge(_pool[i], _gaugeTypes[i]);
        }
        return (_gauge, _int, _ext);
    }

     /// @notice create a gauge  
    function createGauge(address _pool, uint256 _gaugeType) external nonReentrant returns (address _gauge, address _internal_bribe, address _external_bribe)  {
        (_gauge, _internal_bribe, _external_bribe) = _createGauge(_pool, _gaugeType);
    }

    /// @notice create a gauge
    /// @param  _pool       LP address 
    /// @param  _gaugeType  the type of the gauge you want to create
    /// @dev    To create stable/Volatile pair gaugeType = 0, Concentrated liqudity = 1, ...
    ///         Make sure to use the corrcet gaugeType or it will fail

    function _createGauge(address _pool, uint256 _gaugeType) internal returns (address _gauge, address _internal_bribe, address _external_bribe) {
        require(_gaugeType < _factories.length, "gaugetype");
        require(gauges[_pool] == address(0x0), "!exists");
        require(_pool.code.length > 0, "!contract");

        bool isPair;
        address _factory = _factories[_gaugeType];
        address _gaugeFactory = _gaugeFactories[_gaugeType];
        require(_factory != address(0), "addr0");
        require(_gaugeFactory != address(0), "addr0");

        address tokenA = address(0);
        address tokenB = address(0);
        (tokenA) = IPairInfo(_pool).token0();
        (tokenB) = IPairInfo(_pool).token1();

        // for future implementation add isPair() in factory
        if(_gaugeType == 0){
            isPair = IPairFactory(_factory).isPair(_pool);
        } 
        if(_gaugeType == 1) {
            address _pool_factory = IAlgebraFactory(_factory).poolByPair(tokenA, tokenB);
            address _pool_hyper = IHypervisor(_pool).pool();
            require(_pool_hyper == _pool_factory, 'wrong tokens');    
            isPair = true;
        } else {
            //update
            //isPair = false;
        }

        // gov can create for any pool, even non-Thena pairs
        if (!IPermissionsRegistry(permissionRegistry).hasRole("GOVERNANCE",msg.sender)) { 
            require(isPair, "!_pool");
            require(isWhitelisted[tokenA] && isWhitelisted[tokenB], "!whitelisted");
            require(tokenA != address(0) && tokenB != address(0), "!pair.tokens");
        }

        // create internal and external bribe
        address _owner = IPermissionsRegistry(permissionRegistry).thenaTeamMultisig();
        string memory _type =  string.concat("Thena LP Fees: ", IERC20(_pool).symbol() );
        _internal_bribe = IBribeFactory(bribefactory).createBribe(_owner, tokenA, tokenB, _type);

        _type = string.concat("Thena Bribes: ", IERC20(_pool).symbol() );
        _external_bribe = IBribeFactory(bribefactory).createBribe(_owner, tokenA, tokenB, _type);

        // create gauge
        _gauge = IGaugeFactory(_gaugeFactory).createGaugeV2(base, _ve, _pool, address(this), _internal_bribe, _external_bribe, isPair);
     
        // approve spending for $the
        IERC20(base).approve(_gauge, type(uint256).max);

        // save data
        internal_bribes[_gauge] = _internal_bribe;
        external_bribes[_gauge] = _external_bribe;
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        isAlive[_gauge] = true;
        pools.push(_pool);

        // update index
        supplyIndex[_gauge] = index; // new gauges are set to the default global state

        emit GaugeCreated(_gauge, msg.sender, _internal_bribe, _external_bribe, _pool);
    }

   
    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    VIEW FUNCTIONS
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    /// @notice view the total length of the pools
    function length() external view returns (uint256) {
        return pools.length;
    }

    /// @notice view the total length of the voted pools given a tokenId
    function poolVoteLength(uint256 tokenId) external view returns(uint256) { 
        return poolVote[tokenId].length;
    }

    function factories() external view returns(address[] memory){
        return _factories;
    }
    
    function factoryLength() external view returns(uint256){
        return _factories.length;
    }
    
    function gaugeFactories() external view returns(address[] memory){
        return _gaugeFactories;
    }
    
    function gaugeFactoriesLength() external view returns(uint256) {
        return _gaugeFactories.length;
    }

    function weights(address _pool) public view returns(uint256) {
        uint256 _time = _epochTimestamp();
        return weightsPerEpoch[_time][_pool];
    }

    function weightsAt(address _pool, uint256 _time) public view returns(uint256) {
        return weightsPerEpoch[_time][_pool];
    }

    function totalWeight() public view returns(uint256) {
        uint256 _time = _epochTimestamp();
        return totalWeightsPerEpoch[_time];
    }

    function totalWeightAt(uint256 _time) public view returns(uint256) {
        return totalWeightsPerEpoch[_time];
    }

    function _epochTimestamp() internal view returns(uint256) {
        return IMinter(minter).active_period();
    }

    function ve() external view returns(address) {
        return _ve;
    }
    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    DISTRIBUTION
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    /// @notice notify reward amount for gauge
    /// @dev    the function is called by the minter each epoch. Anyway anyone can top up some extra rewards.
    /// @param  amount  amount to distribute
    function notifyRewardAmount(uint256 amount) external {
        require(msg.sender == minter, "!minter");
        IERC20Upgradeable(base).safeTransferFrom(msg.sender, address(this), amount);

        uint256 _totalWeight = totalWeightAt(_epochTimestamp() - 1 weeks);   // minter call notify after updates active_period, loads votes - 1 week

        uint256 _ratio = 0;

        if(_totalWeight > 0) _ratio = amount * 1e18 / _totalWeight;     // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
            index += _ratio;
        }

        emit NotifyReward(msg.sender, base, amount);
    }


    /// @notice distribute the LP Fees to the internal bribes
    /// @param  _gauges  gauge address where to claim the fees 
    /// @dev    the gauge is the owner of the LPs so it has to claim
    function distributeFees(address[] memory _gauges) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            if (isGauge[_gauges[i]] && isAlive[_gauges[i]]){
                IGauge(_gauges[i]).claimFees();
            }
        }
    }

    
    /// @notice Distribute the emission for ALL gauges 
    function distributeAll() external nonReentrant {
        
        IMinter(minter).update_period();

        uint256 x = 0;
        uint256 stop = pools.length;
        for (x; x < stop; x++) {
            _distribute(gauges[pools[x]]);
        }
    }

    /// @notice distribute the emission for N gauges
    /// @param  start   start index point of the pools array
    /// @param  finish  finish index point of the pools array
    /// @dev    this function is used in case we have too many pools and gasLimit is reached
    function distribute(uint256 start, uint256 finish) public nonReentrant {
        IMinter(minter).update_period();
        for (uint256 x = start; x < finish; x++) {
            _distribute(gauges[pools[x]]);
        }
    }

    /// @notice distribute reward onyl for given gauges
    /// @dev    this function is used in case some distribution fails
    function distribute(address[] memory _gauges) external nonReentrant {
        IMinter(minter).update_period();
        for (uint256 x = 0; x < _gauges.length; x++) {
            _distribute(_gauges[x]);
        }
    }

    /// @notice distribute the emission
    function _distribute(address _gauge) internal {

        uint256 lastTimestamp = gaugesDistributionTimestamp[_gauge];
        uint256 currentTimestamp = _epochTimestamp();
        if(lastTimestamp < currentTimestamp){
            _updateForAfterDistribution(_gauge); // should set claimable to 0 if killed

            uint256 _claimable = claimable[_gauge];

            // distribute only if claimable is > 0, currentEpoch != lastepoch and gauge is alive
            if (_claimable > 0 && isAlive[_gauge]) {
                claimable[_gauge] = 0;
                gaugesDistributionTimestamp[_gauge] = currentTimestamp;
                IGauge(_gauge).notifyRewardAmount(base, _claimable);
                emit DistributeReward(msg.sender, _gauge, _claimable);
            }
        }
    }


    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    HELPERS
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    /// @notice update info for gauges
    /// @dev    this function track the gauge index to emit the correct $the amount after the distribution
    function _updateForAfterDistribution(address _gauge) private {
        address _pool = poolForGauge[_gauge];
        uint256 _time = _epochTimestamp() - 1 weeks;
        uint256 _supplied = weightsPerEpoch[_time][_pool];

        if (_supplied > 0) {
            uint256 _supplyIndex = supplyIndex[_gauge];
            uint256 _index = index; // get global index0 for accumulated distro
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint256 _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta > 0) {

                uint _share = _supplied * _delta / 1e18; // add accrued difference for each supplied token

                if (isAlive[_gauge]) {
                    claimable[_gauge] += _share;
                }
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

 

    
    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    PROXY UPDATES
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    /// @notice Fix wrong timestamp of a tokenId
    /// @dev    this is used only if a user weight is saved into the wrong timestamp in weightsPerEpoch [fix 28/04/2023]
    function forceResetTo(uint256 _tokenId) external VoterAdmin {
        lastVoted[_tokenId] = _epochTimestamp() - 1 days;
    }

    
}
