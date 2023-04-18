// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SimpleTeamVesting  {

    
    using SafeERC20 for IERC20;

    struct User {
        address to;                     //  receiver
        uint256 totalAmount;            //  total amount to receive
        uint256 linearTokenPerSeconds;  //  token per second at distribution  
        uint256 timestamp;              //  last time claim was called
    }

    address public owner;
    address public token;
    address[] public usersList;
    
    uint256 public totalSupply;
    uint256 public CLIFF_PERIOD = 86400 * 365;
    uint256 public LINEAR = 86400 * 365;
    uint256 public PRECISION = 1e6;
    uint256 public startTimestamp;

    mapping(address => User) public users;
    mapping(address => bool) public isUser;


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        token = address(0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11);
        totalSupply =  0;
        startTimestamp = 1672876800; //	Thu Jan 05 2023 00:00:00 GMT+0000
    }

   

    // init distribution
    function _init(address[] memory who, uint[] memory amounts) external onlyOwner {
        require(who.length == amounts.length);
        uint256 i = 0;
        uint256 len = who.length;

        address wallet;
        uint amount;

        for(i; i < len; i++){
            wallet = who[i];
            amount = amounts[i];

            require(wallet != address(0));
            require(isUser[wallet] == false);
            require(amount > 0);

            users[wallet] = User({
                to:             wallet,
                totalAmount:    amount,
                linearTokenPerSeconds: (amount / 2) * PRECISION / LINEAR,
                timestamp:      0
            });

            isUser[wallet] = true;
            usersList.push(wallet);  
        }
    }


    function claimCliff() external returns(uint){
        require(isUser[msg.sender], 'not allowed');

        uint256 dt = block.timestamp - startTimestamp;
        require(dt >= CLIFF_PERIOD, 'wait');

        User memory _user = users[msg.sender];
        require(_user.timestamp <= startTimestamp + CLIFF_PERIOD, 'claimed');
                
        uint256 toDistribute = _user.totalAmount / 2;

        _user.timestamp = startTimestamp + CLIFF_PERIOD;
        users[msg.sender] = _user;

        
        IERC20(token).safeTransfer(msg.sender, toDistribute);
        return toDistribute;
    }

    function claimDistribution() external returns(uint) {
        require(isUser[msg.sender], 'not allowed');

        User memory _user = users[msg.sender];
        uint256 _timestamp = _user.timestamp;
        require(_timestamp >= startTimestamp + CLIFF_PERIOD, 'claimCliff before');
        require(_timestamp <= startTimestamp + CLIFF_PERIOD + LINEAR, 'claimed');
        
        uint256 dt = block.timestamp - _timestamp;
        require(dt > 0);
        
        uint256 toDistribute = _user.linearTokenPerSeconds * dt / PRECISION;

        _user.timestamp = block.timestamp;
        users[msg.sender] = _user;
               
        IERC20(token).safeTransfer(msg.sender, toDistribute);
        return toDistribute;

    }
    
    function claimable(address _who) public view returns(uint) {
        if(isUser[_who] == false){
            return 0;
        }
        if(block.timestamp < startTimestamp + CLIFF_PERIOD){
            return 0;
        }
        
        User memory _user = users[_who];
        if(_user.timestamp <= startTimestamp + CLIFF_PERIOD){
            return _user.totalAmount / 2;
        } else {
            uint256 dt = block.timestamp - _user.timestamp;
            return _user.linearTokenPerSeconds * dt / PRECISION;
        }
    }

    function usersLength() external view returns(uint){
        return usersList.length;
    }
    
    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0));
        owner = _owner;
    }

     function deposit(uint256 amount) external onlyOwner {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount, address _token, address _to) external onlyOwner {
        IERC20(_token).safeTransfer(_to, amount);
    }

    function withdrawAll(address _token) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }


}