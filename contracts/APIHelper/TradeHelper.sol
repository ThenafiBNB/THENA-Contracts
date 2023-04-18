// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../Pair.sol";
import "../factories/PairFactory.sol";
import "../PairFees.sol";

contract TradeHelper {
    address public immutable factory;
    bytes32 public immutable pairCodeHash;

    struct route {
        address from;
        address to;
        bool stable;
    }

    constructor(address _factory) {
        factory = _factory;
        pairCodeHash = PairFactory(_factory).pairCodeHash();
    }

    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'TradeHelper: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TradeHelper: ZERO_ADDRESS');
    }

    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1) {
        return _sortTokens(tokenA, tokenB);
    }


    function _pairFor(address tokenA, address tokenB, bool stable) internal view returns (address pair) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1, stable)),
            pairCodeHash // init code hash
        )))));
    }

    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair) {
        return _pairFor(tokenA, tokenB, stable);
    }

    function _calculate_k(uint x, uint y) internal pure returns (uint){
        return x*(y*y/1e18*y/1e18)/1e18+(x*x/1e18*x/1e18)*y/1e18;
    }

    function _calculate_deriv(uint x, uint y) internal pure returns (uint) {
        return 3*y*(x*x/1e18)/1e18+(y*y/1e18*y/1e18);
    }

    function getAmountOutStable(uint amountIn, address tokenIn, address tokenOut) public view returns (uint amount) {
        address pair = _pairFor(tokenIn, tokenOut, true);
        return (PairFactory(factory).isPair(pair)) ? Pair(pair).getAmountOut(amountIn, tokenIn) : 0;
    }

    function getAmountOutVolatile(uint amountIn, address tokenIn, address tokenOut) public view returns (uint amount) {
        address pair = _pairFor(tokenIn, tokenOut, false);
        return (PairFactory(factory).isPair(pair)) ? Pair(pair).getAmountOut(amountIn, tokenIn) : 0;
    }

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) public view returns (uint amount, bool stable) {
        uint amountStable = getAmountOutStable(amountIn, tokenIn, tokenOut);
        uint amountVolatile = getAmountOutVolatile(amountIn, tokenIn, tokenOut);
        return amountStable > amountVolatile ? (amountStable, true) : (amountVolatile, false);
    }

    function getAmountsOut(uint amountIn, route[] memory routes) public view returns (uint[] memory amounts) {
        require(routes.length >= 1, 'TradeHelper: INVALID_PATH');
        amounts = new uint[](routes.length+1);
        amounts[0] = amountIn;
        for (uint i = 0; i < routes.length; i++) {
            (amounts[i+1],) = getAmountOut(amounts[i], routes[i].from, routes[i].to);
        }
    }
    
    function getAmountInStable(uint amountOut, address tokenIn, address tokenOut) public view returns (uint amountIn) {
        address pair = _pairFor(tokenIn, tokenOut, true);

        amountIn = type(uint256).max;
        if(PairFactory(factory).isPair(pair)) {
            Pair p = Pair(pair);

            uint decimalsIn = 10**IERC20(tokenIn).decimals();
            uint decimalsOut = 10**IERC20(tokenOut).decimals();

            uint reserveIn = ((tokenIn == p.token0()) ? p.reserve0() : p.reserve1()) * 1e18 / decimalsIn;
            uint reserveOut = ((tokenOut == p.token0()) ? p.reserve0() : p.reserve1()) * 1e18 / decimalsOut;
            uint output = amountOut * 1e18 / decimalsOut;

            uint y_1 = reserveOut + output;

            uint old_k = _calculate_k(reserveIn, reserveOut);
            uint x_1 = reserveIn;

            for (uint i = 0; i < 255; i++) {
                uint prev_x = x_1;
                uint new_k = _calculate_k(x_1, y_1);

                if (new_k < old_k) {
                    uint dx = (old_k - new_k)*1e18/_calculate_deriv(x_1, y_1);

                    x_1 = x_1 + dx;
                } else {
                    uint dx = (new_k - old_k)*1e18/_calculate_deriv(x_1, y_1);

                    x_1 = x_1 - dx;
                }

                //Check if we have found the result
                if (x_1 > prev_x) {
                    if (x_1 - prev_x <= 1) {
                        break;
                    }
                } else {
                    if (prev_x - x_1 <= 1) {
                        break;
                    }
                }
            } 
            //amountIn = (new_x_amount - old_x_amount) * (1+fees)
            uint amountInNoFees =  ((reserveIn - x_1) * decimalsOut / 1e18);
            amountIn = amountInNoFees * (10000 + PairFactory(factory).getFee(true)) / 10000;
        }
    }

    function getAmountInVolatile(uint amountOut, address tokenIn, address tokenOut) public view returns (uint amountIn) {
        address pair = _pairFor(tokenIn, tokenOut, false);
        amountIn = type(uint256).max;

        if(PairFactory(factory).isPair(pair)) {
            Pair p = Pair(pair);

            uint reserveIn = (tokenIn == p.token0()) ? p.reserve0() : p.reserve1();
            uint reserveOut = (tokenOut == p.token0()) ? p.reserve0() : p.reserve1();
                
            amountIn = (amountOut * reserveIn / (reserveOut - amountOut)) * (10000 + PairFactory(factory).getFee(false)) / 10000;
        }
    }

    function getAmountIn(uint amountOut, address tokenIn, address tokenOut) public view returns (uint amount, bool stable) {
        uint amountStable = getAmountInStable(amountOut, tokenIn, tokenOut);
        uint amountVolatile = getAmountInVolatile(amountOut, tokenIn, tokenOut);
        return amountStable < amountVolatile ? (amountStable, true) : (amountVolatile, false);
    }

    function getAmountsIn(uint amountOut, route[] memory routes) public view returns (uint[] memory amounts) {
        require(routes.length >= 1, 'TradeHelper: INVALID_PATH');
        amounts = new uint[](routes.length + 1);
        amounts[routes.length] = amountOut;
        for (uint i = routes.length-1; i >= 0; i--) {
            (amounts[i],) = getAmountIn(amounts[i+1], routes[i].from, routes[i].to); 
        }
    }


}