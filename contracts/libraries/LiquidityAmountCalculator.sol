// SPDX-License-Identifier:MIT

pragma solidity =0.7.6;

import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@uniswap/v3-periphery/contracts/libraries/PositionValue.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import "hardhat/console.sol";

library calculateAmounts{

    function getLiquidityForAmount0(int24 tickLower,int24 tickUpper,uint256 amount1)external view returns(uint128 liquidty){
    return(LiquidityAmounts.getLiquidityForAmount0( TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickUpper), amount1));
    }

    function getLiquidityForAmount0(int24 tickLower,int24 tickUpper,uint256 amount1)external view returns(uint128 liquidty){
    return(LiquidityAmounts.getLiquidityForAmount1( TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickUpper), amount1));
    }

    function getWholeAmountsLiquidity(uint256 amount0, uint256 amount1, int24 tickLowest, int24 tickuppermost, IUniswapV3Pool pool) external view returns(uint128 liquidity){
        (uint160 sqrtPriceX96, , , , , , ,) = pool.slot0();
        return getLiquidityForAmounts(
        sqrtPriceX96,
        TickMath.getSqrtRatioAtTick(tickLowest),
        TickMath.getSqrtRatioAtTick(tickuppermost),
        amount0,
        amount1
    );
    }
}
