pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

library Tick {
    struct Info {
        bool        initialized;
        uint128     liquidity;
    }

    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint128 liquidityData
    ) internal returns (bool flipped) {
        Tick.Info storage tickInfo = self[tick];
        uint128 liquidityBefore = tickInfo.liquidity;
        uint128 liquidityAfter = liquidityBefore + liquidityData;

        if (liquidityBefore == 0) {
            tickInfo.initialized = true;
        }

        tickInfo.liquidity = liquidityAfter;

        // when either liquidity is taken out or liquidity is newly added to the pool.
        // tick flag needs to be flipped
        flipped = (liquidityAfter == 0) != (liquidityBefore == 0);

    }
}