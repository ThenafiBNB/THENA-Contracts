// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


import '../interfaces/IBribeAPI.sol';
import '../interfaces/IERC20Full.sol';
import '../interfaces/IPair.sol';
import '../interfaces/IPairFactory.sol';
import '../interfaces/IVoter.sol';
import '../interfaces/IVotingEscrow.sol';
import '../interfaces/IRewardsDistributor.sol';

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


import "hardhat/console.sol";
interface IPairAPI {
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
    
    enum PoolType {STABLE, VOLATILE, CL}
    function getPairSingle(address _pair) external view returns(PairInfo memory _PairInfo);
    function pair_factory() external view returns(address);
}

contract veNFTAPI is Initializable {

    struct pairVotes {
        address pair;
        uint256 weight;
    }

    struct veNFT {
        uint8 decimals;
        
        bool voted;
        uint256 attachments;

        uint256 id;
        uint128 amount;
        uint256 voting_amount;
        uint256 rebase_amount;
        uint256 lockEnd;
        uint256 vote_ts;
        pairVotes[] votes;        
        
        address account;

        address token;
        string tokenSymbol;
        uint256 tokenDecimals;
    }

    struct Reward {
        
        uint8 decimals;
        uint256 amount;
        address token;
    }
   
    uint256 constant public MAX_RESULTS = 1000;
    uint256 constant public MAX_PAIRS = 30;

    IVoter public voter;
    address public underlyingToken;
    

    IVotingEscrow public ve;
    IRewardsDistributor public rewardDisitributor;

    address public pairAPI;
    IPairFactory public pairFactory;
    

    address public owner;
    event Owner(address oldOwner, address newOwner);

    struct AllPairRewards {
        Reward[] rewards;
    }
    constructor() {}

    function initialize(address _voter, address _rewarddistro, address _pairApi) initializer public {

        owner = msg.sender;

        pairAPI = _pairApi;
        voter = IVoter(_voter);
        rewardDisitributor = IRewardsDistributor(_rewarddistro);

        require(rewardDisitributor.voting_escrow() == voter._ve(), 've!=ve');
        
        ve = IVotingEscrow( rewardDisitributor.voting_escrow() );
        underlyingToken = IVotingEscrow(ve).token();

        pairFactory = IPairFactory(voter.factory());

    }



    function getAllNFT(uint256 _amounts, uint256 _offset) external view returns(veNFT[] memory _veNFT){

        require(_amounts <= MAX_RESULTS, 'too many nfts');
        _veNFT = new veNFT[](_amounts);

        uint i = _offset;
        address _owner;

        for(i; i < _offset + _amounts; i++){
            _owner = ve.ownerOf(i);
            // if id_i has owner read data
            if(_owner != address(0)){
                _veNFT[i-_offset] = _getNFTFromId(i, _owner);
            }
        }
    }

    function getNFTFromId(uint256 id) external view returns(veNFT memory){
        return _getNFTFromId(id,ve.ownerOf(id));
    }

    function getNFTFromAddress(address _user) external view returns(veNFT[] memory venft){

        uint256 i=0;
        uint256 _id;
        uint256 totNFTs = ve.balanceOf(_user);

        venft = new veNFT[](totNFTs);

        for(i; i < totNFTs; i++){
            _id = ve.tokenOfOwnerByIndex(_user, i);
            if(_id != 0){
                venft[i] = _getNFTFromId(_id, _user);
            }
        }
    }

    function _getNFTFromId(uint256 id, address _owner) internal view returns(veNFT memory venft){

        if(_owner == address(0)){
            return venft;
        }

        uint _totalPoolVotes = voter.poolVoteLength(id);
        pairVotes[] memory votes = new pairVotes[](_totalPoolVotes);

        IVotingEscrow.LockedBalance memory _lockedBalance;
        _lockedBalance = ve.locked(id);

        uint k;
        uint256 _poolWeight;
        address _votedPair;

        for(k = 0; k < _totalPoolVotes; k++){

            _votedPair = voter.poolVote(id, k);
            if(_votedPair == address(0)){
                break;
            }
            _poolWeight = voter.votes(id, _votedPair);
            votes[k].pair = _votedPair;
            votes[k].weight = _poolWeight;
        }

        venft.id = id;
        venft.account = _owner;
        venft.decimals = ve.decimals();
        venft.amount = uint128(_lockedBalance.amount);
        venft.voting_amount = ve.balanceOfNFT(id);
        venft.rebase_amount = rewardDisitributor.claimable(id);
        venft.lockEnd = _lockedBalance.end;
        venft.vote_ts = voter.lastVoted(id);
        venft.votes = votes;
        venft.token = ve.token();
        venft.tokenSymbol =  IERC20( ve.token() ).symbol();
        venft.tokenDecimals = IERC20( ve.token() ).decimals();
        venft.voted = ve.voted(id);
        venft.attachments = ve.attachments(id);
      
    }

    // used only for sAMM and vAMM    
    function allPairRewards(uint256 _amount, uint256 _offset, uint256 id) external view returns(AllPairRewards[] memory rewards){
        
        rewards = new AllPairRewards[](MAX_PAIRS);

        uint256 totalPairs = pairFactory.allPairsLength();
        
        uint i = _offset;
        address _pair;
        for(i; i < _offset + _amount; i++){
            if(i >= totalPairs){
                break;
            }
            _pair = pairFactory.allPairs(i);
            rewards[i].rewards = _pairReward(_pair, id, address(0));
        }
    }

    function singlePairRewardId(uint256 id, address _pair) external view returns(Reward[] memory _reward){
        return _pairReward(_pair, id, address(0));
    }

    function singlePairRewardAddress(address user, address _pair) external view returns(Reward[] memory _reward){
        return _pairReward(_pair, 0, user);
    }


    function _pairReward(address _pair, uint256 id, address user) internal view returns(Reward[] memory _reward){

        if(_pair == address(0)){
            return _reward;
        }

        
        IPairAPI.PairInfo memory _pairApi = IPairAPI(pairAPI).getPairSingle(_pair);
               
        address externalBribe = _pairApi.bribe;
        
        uint256 totBribeTokens = (externalBribe == address(0)) ? 0 : IBribeAPI(externalBribe).rewardsListLength();
        
        uint bribeAmount;
        bool exists = false;
        _reward = new Reward[](2+totBribeTokens);

        address _gauge = (voter.gauges(_pair));
        
        if(_gauge == address(0)){
            return new Reward[](0); 
        }
       
        {
        address t0 = _pairApi.token0;
        address t1 = _pairApi.token1;
        uint256 _feeToken0 = 0;
        uint256 _feeToken1 = 0;
        if(user == address(0)){
            _feeToken0 = IBribeAPI(_pairApi.fee).earned(id, t0);
            _feeToken1 = IBribeAPI(_pairApi.fee).earned(id, t1);
        } 
        else if(id == 0){
            _feeToken0 = IBribeAPI(_pairApi.fee).earned(user, t0);
            _feeToken1 = IBribeAPI(_pairApi.fee).earned(user, t1);
        }
        else {
            return _reward;
        }
        
        if(_feeToken0 > 0){
            _reward[0] = Reward({
                amount: _feeToken0,
                token: t0,
                decimals: IERC20(t0).decimals()
            });
            exists = true;
        }

        
        if(_feeToken1 > 0){
            _reward[1] = Reward({
                amount: _feeToken1,
                token: t1,
                decimals: IERC20(t1).decimals()
            });
            exists = true;
        }
        }

        uint k = 0;
        address _token;      
        if(externalBribe != address(0)) {
            for(k; k < totBribeTokens; k++){
                _token = IBribeAPI(externalBribe).rewardTokens(k);
                bribeAmount = user == address(0) ? IBribeAPI(externalBribe).earned(id, _token) : IBribeAPI(externalBribe).earned(user,_token);
                if(bribeAmount > 0) {
                    _reward[2+k] = Reward({
                        amount: bribeAmount,
                        token: _token,
                        decimals: IERC20(_token).decimals()
                    });
                    if(!exists) exists = true;
                }
            }  
        }   

        if(!exists) return new Reward[](0);

    }
    



    function setOwner(address _owner) external {
        require(msg.sender == owner, 'not owner');
        require(_owner != address(0), 'zeroAddr');
        owner = _owner;
        emit Owner(msg.sender, _owner);
    }

    
    function setVoter(address _voter) external  {
        require(msg.sender == owner);

        voter = IVoter(_voter);
    }


    function setRewardDistro(address _rewarddistro) external {
        require(msg.sender == owner);
        
        rewardDisitributor = IRewardsDistributor(_rewarddistro);
        require(rewardDisitributor.voting_escrow() == voter._ve(), 've!=ve');

        ve = IVotingEscrow( rewardDisitributor.voting_escrow() );
        underlyingToken = IVotingEscrow(ve).token();
    }
    
    function setPairAPI(address _pairApi) external {
        require(msg.sender == owner);
        
        pairAPI = _pairApi;
    }


    function setPairFactory(address _pairFactory) external {
        require(msg.sender == owner);  
        pairFactory = IPairFactory(_pairFactory);
    }

}