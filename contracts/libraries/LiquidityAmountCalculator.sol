// SPDX-License-Identifier:MIT

pragma solidity >=0.6.8 <=0.8.18;

import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@uniswap/v3-periphery/contracts/libraries/PositionValue.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import "hardhat/console.sol";

library calculateAmounts{

    function getWholeAmountsLiquidity(uint256 amount0, uint256 amount1, int24 tickLowest, int24 tickuppermost, IUniswapV3Pool pool) external view returns(uint128 liquidity){
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        return LiquidityAmounts.getLiquidityForAmounts(
        sqrtPriceX96,
        TickMath.getSqrtRatioAtTick(tickLowest),
        TickMath.getSqrtRatioAtTick(tickuppermost),
        amount0,
        amount1
    );
    }
}
