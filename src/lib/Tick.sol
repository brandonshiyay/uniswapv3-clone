pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

import "./LiquidityMath.sol";

library Tick {
    struct Info {
        bool        initialized;
        uint128     grossLiquidity;
        int128      netLiqiudityChange;
    }

    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int128 liquidityDelta,
        bool upper
    ) internal returns (bool flipped) {
        Tick.Info storage tickInfo = self[tick];
        uint128 liquidityBefore = tickInfo.grossLiquidity;
        uint128 liquidityAfter = LiquidityMath.addLiquidity(liquidityBefore, liquidityDelta);

        // when either liquidity is taken out or liquidity is newly added to the pool.
        // tick flag needs to be flipped
        flipped = (liquidityAfter == 0) != (liquidityBefore == 0);

        if (liquidityBefore == 0) {
            tickInfo.initialized = true;
        }

        tickInfo.grossLiquidity = liquidityAfter;
        tickInfo.netLiqiudityChange = upper ?
            int128(int256(tickInfo.netLiqiudityChange) - liquidityDelta) : 
            int128(int256(tickInfo.netLiqiudityChange) + liquidityDelta);
    }

    function cross(
        mapping(int24 => Tick.Info) storage self,
        int24 tick) internal view returns (int128 liquidityDelta){
        Tick.Info storage info = self[tick];
        liquidityDelta = info.netLiqiudityChange;
    }
}