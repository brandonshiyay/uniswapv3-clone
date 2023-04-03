pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

library Position {
    struct Info {
        uint128     liquidity;
    }

    function update(Info storage self, uint128 amount) internal {
        uint128 liquidityBefore = self.liquidity;
        uint128 liquidityAfter = liquidityBefore + amount;

        self.liquidity = liquidityAfter;

    }

    function get(
        mapping(bytes32 => Position.Info) storage self, 
        address owner,
        int24 loTick,
        int24 hiTick
    ) internal view returns (Position.Info storage position){
        position = self[
            keccak256(abi.encodePacked(owner, loTick, hiTick))
        ];
    }
}

