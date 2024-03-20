// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import './libraries/Math.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './interfaces/IRewardsDistributor.sol';
import './interfaces/IVotingEscrow.sol';
import './interfaces/IMinter.sol';

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/*

@title Curve Fee Distribution modified for ve(3,3) emissions
@author Thena Finance, Prometheus
@license MIT

*/

contract RewardsDistributor is ReentrancyGuard, IRewardsDistributor {

    event CheckpointToken(
        uint time,
        uint tokens
    );

    event Claimed(
        uint tokenId,
        uint amount,
        uint claim_epoch, //timestamp
        uint max_epoch
    );

    uint constant WEEK = 7 * 86400;

    uint public start_time;
    uint public last_token_time;
    uint public last_week;
    uint public total_distributed;
    uint public token_claimed;
    uint public time_cursor;


    uint[1000000000000000] public tokens_per_week;
    uint[1000000000000000] public ve_supply;

    address public owner;
    address public voting_escrow;
    address public token;
    address public depositor;

    
    mapping(uint => uint) public time_cursor_of;
    mapping(address => bool) public lockAddress;       // remove permissionless claim for an address owner
    mapping(uint => uint) internal time_to_block;

  

    constructor(address _voting_escrow) {
        uint _t = block.timestamp / WEEK * WEEK;
        last_token_time = _t;
        time_cursor = _t;
        
        address _token = IVotingEscrow(_voting_escrow).token();
        token = _token;

        voting_escrow = _voting_escrow;

        depositor = address(0x86069FEb223EE303085a1A505892c9D4BdBEE996);
        start_time = _t;

        owner = msg.sender;

        require(IERC20(_token).approve(_voting_escrow, type(uint).max));
    }

    function timestamp() public view returns (uint) {
        return block.timestamp / WEEK * WEEK;
    }

    // checkpoint the total supply at the current timestamp. Called by depositor
    function checkpoint_total_supply() external {
        assert(msg.sender == depositor || msg.sender == owner);
        _checkpoint_total_supply();
    }
    function _checkpoint_total_supply() internal {
        address ve = voting_escrow;
        uint t = time_cursor;
        uint rounded_timestamp = block.timestamp / WEEK * WEEK;
        IVotingEscrow(ve).checkpoint();

        for (uint i = 0; i < 20; i++) {
            if (t > rounded_timestamp) {
                break;
            } else {
                uint epoch = _find_timestamp_epoch(ve, t);
                IVotingEscrow.Point memory pt = IVotingEscrow(ve).point_history(epoch);
                int128 dt = 0;
                if (t > pt.ts) {
                    dt = int128(int256(t - pt.ts));
                }
                ve_supply[t] = Math.max(uint(int256(pt.bias - pt.slope * dt)), 0);
            }
            t += WEEK;
        }

        time_cursor = t;
    }

    
    function _find_timestamp_epoch(address ve, uint _timestamp) internal view returns (uint) {
        uint _min = 0;
        uint _max = IVotingEscrow(ve).epoch();
        for (uint i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint _mid = (_min + _max + 2) / 2;
            IVotingEscrow.Point memory pt = IVotingEscrow(ve).point_history(_mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }



    // checkpoint the token to distribute for the last epoch
    function checkpoint_token() external {
        assert(msg.sender == depositor || msg.sender == owner);
        _checkpoint_token();
    }

    function _checkpoint_token() internal {

        last_week = block.timestamp / WEEK * WEEK;
        time_to_block[last_week] = block.number;
        last_token_time = block.timestamp;
        
        uint token_balance = IERC20(token).balanceOf(address(this));
        uint diff = total_distributed - token_claimed;
        uint to_distribute = token_balance - diff;
        
        tokens_per_week[last_week] += to_distribute;
        total_distributed += to_distribute;

        emit CheckpointToken(block.timestamp, to_distribute);
    }
  

    
    function claimable(uint _tokenId) external view returns(uint) {
        uint t = time_cursor_of[_tokenId];
        if(t == 0) t = start_time;
        uint _last_week = last_week;
        uint to_claim = 0;
        for(uint i = 0; i < 100; i++){
            if(t > _last_week) break;
            to_claim += _toClaim(_tokenId, t);
            t += WEEK;
        }        
        return to_claim;
    }
        

    function claim_many(uint[] memory tokenIds) external nonReentrant returns(bool) {
        require(tokenIds.length <= 25);
        for(uint i = 0; i < tokenIds.length; i++){
            _claim(tokenIds[i]);
        }
        return true;
    }

    function claim(uint _tokenId) external nonReentrant returns(uint){
        return _claim(_tokenId);
    }

    function _claim(uint _tokenId) internal returns (uint) {
        address _owner = IVotingEscrow(voting_escrow).ownerOf(_tokenId);

        // if lockAddress then check if msg.sender is allowed to call claim 
        if(lockAddress[_owner]) require(IVotingEscrow(voting_escrow).isApprovedOrOwner(msg.sender, _tokenId), 'not approved');

        IVotingEscrow.LockedBalance memory _locked = IVotingEscrow(voting_escrow).locked(_tokenId);
        require(_locked.amount > 0, 'No existing lock found');
        require(_locked.end > block.timestamp, 'Cannot add to expired lock. Withdraw');

        uint t = time_cursor_of[_tokenId];
        if(t < start_time) t = start_time;
        uint _last_week = last_week;
        uint to_claim = 0;

        for(uint i = 0; i < 100; i++){
            if(t > _last_week) break;
            to_claim += _toClaim(_tokenId, t);
            t += WEEK;
        }        

        if(to_claim > 0) IVotingEscrow(voting_escrow).deposit_for(_tokenId, to_claim);
        time_cursor_of[_tokenId] = t;
        token_claimed += to_claim;

        emit Claimed(_tokenId, to_claim, last_week, _find_timestamp_epoch(voting_escrow, last_week));

        return to_claim;
    }

    function _toClaim(uint id, uint t) internal view returns(uint to_claim) {

        IVotingEscrow.Point memory userData = IVotingEscrow(voting_escrow).user_point_history(id,1);

        if(ve_supply[t] == 0) return 0;
        if(tokens_per_week[t] == 0) return 0;
        if(userData.ts > t) return 0;

        uint id_bal = IVotingEscrow(voting_escrow).balanceOfAtNFT(id, time_to_block[t]);
        uint share =  id_bal * 1e18 / ve_supply[t];
        
        to_claim = share * tokens_per_week[t] / 1e18;
    }




    
    // prevent to claim rebase from any non-auth source. If true then require isApprovedOrOwner(msg.sender, _tokenId). 
    // Saved per owner address to avoid recall after split/merge
    function _lockAddress(address caller) external {
        require(msg.sender == caller || msg.sender == owner);
        lockAddress[caller] = true;
    }
    function _unlockAddress(address caller) external {
        require(msg.sender == caller || msg.sender == owner);
        lockAddress[caller] = false;
    }





    /*  Owner Functions */

    function setDepositor(address _depositor) external {
        require(msg.sender == owner);
        depositor = _depositor;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }

    function increaseOrRemoveAllowances(bool what) external {
        require(msg.sender == owner);
        what == true ? IERC20(token).approve(voting_escrow, type(uint).max) : IERC20(token).approve(voting_escrow, 0);
    }

    function withdrawERC20(address _token) external {
        require(msg.sender == owner);
        require(_token != address(0));
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, _balance);
    }


}