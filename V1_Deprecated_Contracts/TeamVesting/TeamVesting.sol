// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TeamVesting  {

    
    using SafeERC20 for IERC20;

    address public owner;
    address public token;

    
    uint256 public totalSupply;
    uint256 public CLIFF = 86400 * 365;
    uint256 public LINEAR = 86400 * 365;
    uint256 public PRECISION = 1e6;
    uint256 public startTimestamp;
    uint256 public teamCount;


    mapping(address => uint256) public userAmount;
    mapping(address => uint256) public userLastTimestamp;
    mapping(address => bool) public hasCliff;
    mapping(address => bool) public isTeam;
    mapping(address => bool) public depositors;


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        token = address(0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11);
        totalSupply =  2_600_000 * 1e18;
        startTimestamp = block.timestamp;
    }

    function deposit(uint256 amount) external {
        require(depositors[msg.sender] == true || msg.sender == owner);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount, address _token, address _to) external {
        require(depositors[msg.sender] == true || msg.sender == owner);
        IERC20(_token).safeTransfer(_to, amount);
    }

    function withdraw() external {
        require(depositors[msg.sender] == true || msg.sender == owner);
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }


    function registerUsers(address[] memory _users) external onlyOwner {

        uint256 i = 0;
        uint256 len = _users.length;

        address _user;

        for(i; i < len; i++){
            _user = _users[i];
            require(_user != address(0));
            isTeam[_user] = true;
            userAmount[_user] = totalSupply * PRECISION / len;    
            teamCount += 1;  
        }
    }


    function claimCliff() external {
        require(userAmount[msg.sender] > 0);
        require(isTeam[msg.sender] == true);
        require(hasCliff[msg.sender] == false);

        uint256 dt = block.timestamp - startTimestamp;

        require(dt >= CLIFF, 'wait');
        
        uint256 toWithdraw = userAmount[msg.sender] / 2 / PRECISION;

        // set new userAmount
        userAmount[msg.sender] = toWithdraw;
        userLastTimestamp[msg.sender] = startTimestamp + CLIFF;
        IERC20(token).safeTransfer(msg.sender, toWithdraw);
        hasCliff[msg.sender] = true;
    }

    function claimDistribution() external {
        require(userAmount[msg.sender] > 0);
        require(isTeam[msg.sender] == true);
        require(hasCliff[msg.sender] == true);
        
        uint256 _timestamp = userLastTimestamp[msg.sender];
        require(_timestamp >= startTimestamp + CLIFF);

        uint256 dt = block.timestamp - _timestamp;

        uint256 totalSupplyToDistribute = totalSupply / 2;

        uint256 tokenPerSecPerTeam = totalSupplyToDistribute / LINEAR / teamCount;

        
        uint256 toDistribute = tokenPerSecPerTeam * dt / PRECISION;
        
        IERC20(token).transfer(msg.sender, toDistribute);
        userAmount[msg.sender] = toDistribute;
        userLastTimestamp[msg.sender] = block.timestamp;

    }


    
    
    function setDepositor(address depositor) external onlyOwner {
        require(depositors[depositor] == false);
        depositors[depositor] = true;
    }



    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0));
        owner = _owner;
    }


}