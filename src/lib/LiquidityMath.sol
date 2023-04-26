pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT


import "./FixedPoint96.sol";
import "prb-math/Common.sol";


library LiquidityMath {
    function addLiquidity
    (uint128 currentLiquidity, int128 addedLiquidity) 
    internal pure returns (uint128 newLiquidity){
        if (addedLiquidity < 0) {
            newLiquidity = currentLiquidity - uint128(-addedLiquidity);
        } else {
            newLiquidity = currentLiquidity + uint128(addedLiquidity);
        }
    }



    function getLiquidityForAmount0 (
        uint160 sqrtPrice0,
        uint160 sqrtPrice1,
        uint256 amount0
    ) internal pure returns (uint128 liquidity){
        if (sqrtPrice0 > sqrtPrice1) {
            (sqrtPrice0, sqrtPrice1) = (sqrtPrice1, sqrtPrice0);
        }

        uint256 temp = mulDiv(
            sqrtPrice0, 
            sqrtPrice1, 
            FixedPoint96.Q96
        );

        liquidity = uint128(mulDiv(
            amount0, temp, sqrtPrice1 - sqrtPrice0
        ));

    }


    function getLiquidityForAmount1(
        uint160 sqrtPrice0,
        uint160 sqrtPrice1,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtPrice0 > sqrtPrice1) {
            (sqrtPrice0, sqrtPrice1) = (sqrtPrice1, sqrtPrice0);
        }

        liquidity = uint128(mulDiv(
            amount1,
            FixedPoint96.Q96,
            sqrtPrice1 - sqrtPrice0
        ));
    }


    function getLiquidityForAmounts(
        uint160 sqrtPrice,
        uint160 sqrtPrice0, 
        uint160 sqrtPrice1,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtPrice0 > sqrtPrice1) {
            (sqrtPrice0, sqrtPrice1) = (sqrtPrice1, sqrtPrice0);
        }

        if (sqrtPrice <= sqrtPrice0) {
            liquidity = getLiquidityForAmount0(sqrtPrice0, sqrtPrice1, amount0);
        
        } else if (sqrtPrice <= sqrtPrice1) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtPrice, sqrtPrice1, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtPrice0, sqrtPrice, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        
        } else {
            liquidity = getLiquidityForAmount1(sqrtPrice0, sqrtPrice1, amount1);

        }
    }
}