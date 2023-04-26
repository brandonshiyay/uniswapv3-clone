pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

interface IUniswapV3Pool {
    struct CallbackData {
        address token0;
        address token1;
        address payer;
    }

    function slot0() external view returns (uint160 sqrtPrice, int24 tick);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function mint(
        address owner,
        int24 loTick, 
        int24 hiTick,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        address recipient,
        bool zeroForOne,
        uint256 amountSpeficied,
        bytes calldata data
    ) external returns (int256, int256);
}