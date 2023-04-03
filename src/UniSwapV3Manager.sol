pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

import "./UniSwapV3Pool.sol";

contract UniSwapV3Manager {
    function mint(
        address _poolAddress,
        int24 loTick, 
        int24 hiTick, 
        uint128 liquidity,
        bytes calldata data
    ) public {
        UniSwapV3Pool(_poolAddress).mint(msg.sender, loTick, hiTick, liquidity, data);
    }


    function swap(
        address _poolAddress,
        bytes calldata data
    ) public {
        UniSwapV3Pool(_poolAddress).swap(msg.sender, data);
    }


    function uniswapV3MintCallback(
        uint256 amount0, 
        uint256 amount1, 
        bytes calldata data
        ) public {

        UniSwapV3Pool.CallbackData memory extraData = abi.decode(
            data, 
            (UniSwapV3Pool.CallbackData)
        );

        IERC20(extraData.token0).transferFrom(extraData.payer, msg.sender, amount0);
        IERC20(extraData.token1).transferFrom(extraData.payer, msg.sender, amount1);
    }


    function uniswapV3SwapCallback(
        int256 amount0, 
        int256 amount1, 
        bytes calldata data) public {

        UniSwapV3Pool.CallbackData memory extraData = abi.decode(
            data, 
            (UniSwapV3Pool.CallbackData)
        );

        if (amount0 > 0) {
            IERC20(extraData.token0).transferFrom(
                extraData.payer, 
                msg.sender, 
                uint256(amount0)
            );
        }

        if (amount1 > 0) {
            IERC20(extraData.token1).transferFrom(
                extraData.payer, 
                msg.sender, 
                uint256(amount1)
            );
        }
    }
}