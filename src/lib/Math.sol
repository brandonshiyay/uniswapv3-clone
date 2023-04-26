pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

import "prb-math/Common.sol";
import "./FixedPoint96.sol";
import "forge-std/console.sol";

library Math {
    function calcDelta0(
        uint160 sqrtX96PriceA,
        uint160 sqrtX96PriceB,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtX96PriceA > sqrtX96PriceB) {
            (sqrtX96PriceA, sqrtX96PriceB) = (sqrtX96PriceB, sqrtX96PriceA);
        }

        require(sqrtX96PriceA > 0);
        amount0 = divRoundUp(
            mulDivRoundUp(
                uint256(liquidity) << FixedPoint96.RESOLUTION, 
                (sqrtX96PriceB - sqrtX96PriceA), 
                sqrtX96PriceB
                ),
            sqrtX96PriceA
            );

    }


    function calcDelta1(
        uint160 sqrtX96PriceA,
        uint160 sqrtX96PriceB,
        uint128 liquidity
        ) internal pure returns (uint256 amount1) {
        if (sqrtX96PriceA > sqrtX96PriceB) {
            (sqrtX96PriceA, sqrtX96PriceB) = (sqrtX96PriceB, sqrtX96PriceA);
        }

        amount1 = mulDivRoundUp(
            uint256(liquidity), 
            (sqrtX96PriceB - sqrtX96PriceA), 
            FixedPoint96.Q96
            );

    }


    function getNextSqrtPriceFromInput(
        uint160 sqrtPriceBefore,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtPriceAfter){
        sqrtPriceAfter = zeroForOne ? 
        getNextSqrtPriceFromAmount0RoundUp(
            sqrtPriceBefore,
            liquidity, 
            amountIn
        ):
        getNextSqrtPriceFromAmount1RoundUp(
            sqrtPriceBefore,
            liquidity, 
            amountIn
        );
    }


    function getNextSqrtPriceFromAmount0RoundUp(
        uint160 sqrtPriceBefore,
        uint128 liquidity,
        uint256 amountIn
    ) internal pure returns (uint160) {

        uint256 numerator = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 product = amountIn * sqrtPriceBefore;

        if (product / amountIn == sqrtPriceBefore) {
            uint256 denominator = numerator + product;
            if (denominator >= numerator) {
                return uint160(mulDivRoundUp(numerator, sqrtPriceBefore, denominator));
            }
        }

        return uint160(divRoundUp(numerator, (numerator / sqrtPriceBefore) + amountIn));
    }


    function getNextSqrtPriceFromAmount1RoundUp(
        uint160 sqrtPriceBefore,
        uint128 liquidity,
        uint256 amountIn
    ) internal pure returns (uint160) {

        return sqrtPriceBefore + uint160((amountIn << FixedPoint96.RESOLUTION) / liquidity);
    }


    function mulDivRoundUp(
        uint256 a, 
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }


    function divRoundUp(
        uint256 a, 
        uint256 b
    ) internal pure returns (uint256 result) {
        assembly {
            result := add(
                div(a, b),
                gt(mod(a, b), 0)
            )
        }
    }
}