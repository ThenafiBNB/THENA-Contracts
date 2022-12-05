// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import './libraries/Math.sol';
import './interfaces/IERC20.sol';
import './interfaces/IRouter01.sol';

import './interfaces/IMasterchef.sol';

interface IPair {
    function claimStakingFees() external;
    function pairs() external returns(address[] memory);
    function allPairsLength() external returns(uint);
}

// The base pair of pools, either stable or volatile
contract StakingNFTFee  {

    uint256 public lastRewardtime;

    address public masterchef;
    address public wbnb;
    address public owner;
    address public router;
    address public pairFactory;

    address[] public tokens;

    mapping(address => bool) public isToken;
    mapping(address => uint256) internal tokenPos;
    mapping(address => IRouter01.route) public tokenToRoutes;
    mapping(address => bool) public isKeeper;

    event StakingReward(uint256 _timestamp, uint256 _amount);
    event TransferOwnership(address oldOwner, address newOwner);


    modifier onlyOwner {
        require(msg.sender == owner, 'not allowed');
        _;
    }

    modifier keeper {
        require(isKeeper[msg.sender] == true || msg.sender == owner, 'not keeper');
        _;
    }


    constructor() {
        owner = msg.sender;
        lastRewardtime = 0;
    }



    /* ---------------------- HANDLE FEES */
    /* ---------------------- ---------------------- */
    /* ---------------------- ---------------------- */

    function claimFees() external keeper {
        uint i = 0;
        uint _len = IPair(pairFactory).allPairsLength(); 
        address[] memory pairs = new address[](_len);
        pairs = IPair(pairFactory).pairs();

        for(i; i < pairs.length; i++){
            IPair(pairs[i]).claimStakingFees();
        }

    }

    function swap() external keeper {

        uint256 _balance;
        address _token;
        uint256 i;
        IRouter01.route[] memory _routes = new IRouter01.route[](1);


        for(i=0; i < tokens.length; i++){
            _token = tokens[i];
            _balance = IERC20(_token).balanceOf(address(this));
            if(_balance > 0 && isToken[_token]) {
                _routes[0] = tokenToRoutes[_token];
                _safeApprove(_token, masterchef, 0);
                _safeApprove(_token, masterchef, _balance);
                IRouter01(router).swapExactTokensForTokens(_balance, 0, _routes, address(this), block.timestamp);
            } 
        }

        _balance = IERC20(wbnb).balanceOf(address(this));
        _safeTransfer(wbnb, masterchef, _balance);
        IMasterchef(masterchef).setDistributionRate(_balance);
        lastRewardtime = block.timestamp;
        
        emit StakingReward(block.timestamp, _balance);

    }


    /* ---------------------- TOKEN SETTINGS */
    /* ---------------------- ---------------------- */
    /* ---------------------- ---------------------- */

    function setToken(address token, IRouter01.route memory routes) external onlyOwner {
        require(token != address(0));
        require(isToken[token] == false, 'already in');

        require(routes.from == token);
        require(routes.stable == false);
        require(routes.to == wbnb , 'wBNB must be last route');
        tokenToRoutes[token] = routes;
        isToken[token] = true;

        
        tokenPos[token] = tokens.length;
        tokens.push(token);
    }


    function removeToken(address token) external onlyOwner {
        require(token != address(0));
        require(isToken[token] == true);
        uint256 _tokenPos = tokenPos[token];
        delete tokenToRoutes[token];
        delete tokenPos[token];
        isToken[token] = false;

        if(tokens.length -1 == _tokenPos){
            tokens.pop();
        } else {
            address _lastToken = tokens[tokens.length -1];
            tokens[_tokenPos] = _lastToken;
            tokenPos[_lastToken] = _tokenPos;
            tokens.pop();
        }

    }

    
    function setRoutesFor(address token, IRouter01.route memory routes) external onlyOwner {
        require(token != address(0));
        require(isToken[token] == true);
        require(routes.from == token);
        require(routes.stable == false);
        require(routes.to == wbnb , 'wBNB must be last route');
        tokenToRoutes[token] = routes;
    }





    /* ---------------------- VIEW */
    /* ---------------------- ---------------------- */
    /* ---------------------- ---------------------- */

    function _tokens() external view returns(address[] memory){
        return tokens;
    }


    
    /* ---------------------- OWNER SETTINGS */
    /* ---------------------- ---------------------- */
    /* ---------------------- ---------------------- */

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address _oldOwner = owner;
        owner = newOwner;
        emit TransferOwnership(_oldOwner, newOwner);
    }
    
    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0));
        require(isKeeper[_keeper] == false);
        isKeeper[_keeper] = true;
    }

    function removeKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0));
        require(isKeeper[_keeper] == true);
        isKeeper[_keeper] = false;
    }
    
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), 'addr 0');
        router = _router;
    }

    function setMasterchef(address _masterchef) external onlyOwner {
        require(_masterchef != address(0), 'addr 0');
        masterchef = _masterchef;
    }

    function setPairFactory(address _pairFactory) external onlyOwner {
        require(_pairFactory != address(0), 'addr 0');
        pairFactory = _pairFactory;
    }


    function _safeTransfer(address token,address to,uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeApprove(address token,address spender,uint256 value) internal {
        require(token.code.length > 0);
        require((value == 0) || (IERC20(token).allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

}