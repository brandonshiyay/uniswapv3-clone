pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

import "./Math.sol";

library SwapMath {
    function computeSwapStep(
        uint160 sqrtPriceBefore,
        uint160 sqrtPriceTarget,
        uint128 liquidity,
        uint256 amountRemaining
    ) internal pure returns (
        uint160 sqrtPriceAfter,
        uint256 amountIn,
        uint256 amountOut) {
        
        bool zeroForOne = (sqrtPriceBefore >= sqrtPriceTarget);

        sqrtPriceAfter = Math.getNextSqrtPriceFromInput(
            sqrtPriceBefore,
            liquidity,
            amountRemaining,
            zeroForOne
        );

        amountIn = zeroForOne ?
                Math.calcDelta0(sqrtPriceBefore, sqrtPriceTarget, liquidity) :
                Math.calcDelta1(sqrtPriceBefore, sqrtPriceTarget, liquidity);

        if (amountRemaining >= amountIn) {
            sqrtPriceAfter = sqrtPriceTarget;
        } else {
            sqrtPriceAfter = Math.getNextSqrtPriceFromInput(
                sqrtPriceBefore, 
                liquidity, 
                amountRemaining, 
                zeroForOne);
        }

        amountIn = Math.calcDelta0(sqrtPriceBefore, sqrtPriceAfter, liquidity);
        amountOut = Math.calcDelta1(sqrtPriceBefore, sqrtPriceAfter, liquidity);

        if (!zeroForOne) {
            (amountIn, amountOut) = (amountOut, amountIn);
        }

    }
}