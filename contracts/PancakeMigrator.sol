// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;


import "./interfaces/IRouter01.sol";
import "./interfaces/IUniswapRouterETH.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IPairFactory.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract PancakeMigrator is ReentrancyGuard {

    using SafeERC20 for IERC20;

    address public pcRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public pcFactory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    
    IPairFactory public pairFactory;

    IRouter01 public thRouter;

    constructor(address _pairFactory, address _thRouter) {

        pairFactory = IPairFactory(_pairFactory);
        thRouter = IRouter01(_thRouter);

    }



    /*
        @dev migrate univ2 LP to Thena
        @param _lp      lp to migrate
        @param stable   boolean to create/add to a (non)stable pair. True = stable
    */

    function migrate(address _lp, uint _amount, bool stable) external nonReentrant {
        
        require(IERC20(_lp).balanceOf(msg.sender) >= _amount, '_amount');

        address _tokenA = IUniswapV2Pair(_lp).token0();
        address _tokenB = IUniswapV2Pair(_lp).token1();

        _removeLiquidity(_lp, _tokenA, _tokenB, _amount);

        uint _balanceA = IERC20(_tokenA).balanceOf(address(this));
        uint _balanceB = IERC20(_tokenB).balanceOf(address(this));

        // add liquidity
        thRouter.addLiquidity(_tokenA, _tokenB, stable, _balanceA, _balanceB, 1, 1, msg.sender, block.timestamp);        
        
        // send back token > 0
        _balanceA = IERC20(_tokenA).balanceOf(address(this)); 
        if(_balanceA > 0){
            IERC20(_tokenA).safeTransfer(msg.sender, _balanceA);
        }
        _balanceB = IERC20(_tokenB).balanceOf(address(this));
        if(_balanceB > 0){
            IERC20(_tokenB).safeTransfer(msg.sender, _balanceA);
        }

    }


    function _removeLiquidity(address _lp,address _tokenA,address _tokenB, uint _amount) internal {
        
        // get lp
        IERC20(_lp).safeTransferFrom(msg.sender,address(this), _amount);
        
        // remove liq.
        IERC20(_lp).safeApprove(pcRouter,0);
        IERC20(_lp).safeApprove(pcRouter,_amount);
        IUniswapRouterETH(pcRouter).removeLiquidity(_tokenA, _tokenB, _amount, 1, 1, address(this), block.timestamp);       

    }






}