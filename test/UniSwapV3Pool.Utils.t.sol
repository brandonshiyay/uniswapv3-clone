// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./TestUtils.sol";
import "../src/lib/LiquidityMath.sol";

abstract contract UniSwapV3PoolUtils is Test, TestUtils{
    struct LiquidityRange {
        int24   loTick;
        int24   hiTick;
        uint128 amount;
    }

    struct TestCaseParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        uint256 currentPrice;
        LiquidityRange[] liquidity;
        bool transferInMintCallback;
        bool transferInSwapCallback;
        bool mintLiquidity;
    }

    function liquidityRange(
        uint256 loPrice,
        uint256 hiPrice,
        uint256 amount0,
        uint256 amount1,
        uint256 currentPrice
    ) internal pure returns (LiquidityRange memory range) {
        range = LiquidityRange({
            loTick: TestUtils.tick(loPrice),
            hiTick: TestUtils.tick(hiPrice),
            amount: LiquidityMath.getLiquidityForAmounts(
                TestUtils.sqrtP(currentPrice),
                TestUtils.sqrtP(loPrice),
                TestUtils.sqrtP(hiPrice),
                amount0, 
                amount1
            )
        });
    }
}