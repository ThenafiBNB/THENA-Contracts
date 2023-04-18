// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITradeHelper {
    struct Route {
        address from;
        address to;
        bool stable;
    }
    function getAmountOutStable(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount);
    function getAmountOutVolatile(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount);
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable);
    function getAmountsOut(uint amountIn, Route[] memory routes) external view returns (uint[] memory amounts);
    function getAmountInStable(uint amountOut, address tokenIn, address tokenOut) external view returns (uint amountIn);
    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);
}


interface IBaseV1Factory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

interface IBaseV1Pair {
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function getAmountOut(uint, address) external view returns (uint);
}

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

interface IPairFactory {
    function getFee(bool _stable) external view returns(uint256);
    function MAX_REFERRAL_FEE() external view returns(uint256);
}


library Math {
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'Math: Sub-underflow');
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IRouterV3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Unlike standard swaps, handles transferring from user before the actual swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingleSupportingFeeOnTransferTokens(ExactInputSingleParams calldata params)
        external
        returns (uint256 amountOut);
}


contract GlobalRouter {


    ITradeHelper public tradeHelper;


    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'BaseV1Router: EXPIRED');
        _;
    }


    constructor(address _tradeHelper) {
        tradeHelper = ITradeHelper(_tradeHelper);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, ITradeHelper.Route[] memory routes, address _to) internal virtual {
        for (uint i = 0; i < routes.length; i++) {
            (address token0,) = tradeHelper.sortTokens(routes[i].from, routes[i].to);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = routes[i].from == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < routes.length - 1 ? tradeHelper.pairFor(routes[i+1].from, routes[i+1].to, routes[i+1].stable) : _to;
            IBaseV1Pair(tradeHelper.pairFor(routes[i].from, routes[i].to, routes[i].stable)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
            //emit Swap(msg.sender,amounts[i],routes[i].from, _to, routes[i].stable); 
        }
    }


    /// @notice Swap a Token for a Token given the _type of pools
    /// @param  _type       boolean true := sAMM/vAMM pools, false := algebra v3 
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin, ITradeHelper.Route[] calldata routes,address to,uint deadline, bool _type) external ensure(deadline) returns (uint[] memory amounts){
        
        if(_type == false){
            

        } else {
            amounts = tradeHelper.getAmountsOut(amountIn, routes);
            require(amounts[amounts.length - 1] >= amountOutMin, 'BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
            address _pair = tradeHelper.pairFor(routes[0].from, routes[0].to, routes[0].stable);
            _safeTransferFrom( routes[0].from, msg.sender, _pair, amounts[0] );
            _swap(amounts, routes, to);
        }

    }


    function exactInput(IRouterV3.ExactInputParams memory params)
        external
        payable
        /*checkDeadline(params.deadline)*/
        returns (uint256 amountOut)
    {
        address payer = msg.sender; // msg.sender pays for the first hop

        /*while (true) {
            bool hasMultiplePools = params.path.hasMultiplePools();

            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient, // for intermediate swaps, this contract custodies
                0,
                SwapCallbackData({
                    path: params.path.getFirstPool(), // only the first pool in the path is necessary
                    payer: payer
                })
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this); // at this point, the caller has paid
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        require(amountOut >= params.amountOutMinimum, 'Too little received');*/
    }







    /* ----------------------------
    -------------------------------
            v2 pools helpers
    -------------------------------
    ---------------------------- */
    
    function getAmountOutStable(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount){
        return tradeHelper.getAmountOutStable(amountIn, tokenIn, tokenOut);
    }
    function getAmountOutVolatile(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount){
        return tradeHelper.getAmountOutVolatile(amountIn, tokenIn, tokenOut);
    }
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable){
        return tradeHelper.getAmountOut(amountIn, tokenIn, tokenOut);
    }
    function getAmountsOut(uint amountIn, ITradeHelper.Route[] memory routes) external view returns (uint[] memory amounts){
        return tradeHelper.getAmountsOut(amountIn, routes);
    }
    function getAmountInStable(uint amountOut, address tokenIn, address tokenOut) external view returns (uint amountIn){
        return tradeHelper.getAmountInStable(amountOut, tokenIn, tokenOut);
    }
    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair){
        return tradeHelper.pairFor(tokenA, tokenB, stable);
    }
    function sortTokens(address tokenA, address tokenB) external view returns (address token0, address token1){
        return tradeHelper.sortTokens(tokenA, tokenB);
    }


    /* ----------------------------
    -------------------------------
            transfer helpers
    -------------------------------
    ---------------------------- */
    
    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }


}