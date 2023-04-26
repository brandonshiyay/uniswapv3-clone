pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

import "./UniSwapV3Pool.sol";
import "./interfaces/IUniswapV3Manager.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./lib/LiquidityMath.sol";
import "./lib/TickMath.sol";


contract UniSwapV3Manager is IUniswapV3Manager{
    function mint(MintParams calldata params) public returns (uint256 amount0, uint256 amount1) {
        IUniswapV3Pool pool = IUniswapV3Pool(params.poolAddress);
        
        (uint160 sqrtPrice, ) = pool.slot0();
        int24 loTick = params.loTick;
        int24 hiTick = params.hiTick;
        
        uint160 loSqrtPrice = TickMath.getSqrtRatioAtTick(loTick);
        uint160 hiSqrtPrice = TickMath.getSqrtRatioAtTick(hiTick);

        uint128 liquidity = LiquidityMath.getLiquidityForAmounts(
            sqrtPrice, 
            loSqrtPrice, 
            hiSqrtPrice,
            params.amount0Desired,
            params.amount1Desired);

        bytes memory extra = abi.encode(IUniswapV3Pool.CallbackData({
            token0: pool.token0(),
            token1: pool.token1(),
            payer: msg.sender
        }));

        (amount0, amount1) = pool.mint(
            msg.sender, 
            loTick, 
            hiTick, 
            liquidity,
            extra
        );
    }


    function swap(
        address _poolAddress,
        bool zeroForOne,
        uint256 amountSpeficied,
        bytes calldata data
    ) public returns (int256, int256) {
        return UniSwapV3Pool(_poolAddress).swap(msg.sender, zeroForOne, amountSpeficied, data);
    }


    function uniswapV3MintCallback(
        uint256 amount0, 
        uint256 amount1, 
        bytes calldata data
        ) public {

        IUniswapV3Pool.CallbackData memory extraData = abi.decode(
            data, 
            (IUniswapV3Pool.CallbackData)
        );

        IERC20(extraData.token0).transferFrom(extraData.payer, msg.sender, amount0);
        IERC20(extraData.token1).transferFrom(extraData.payer, msg.sender, amount1);
    }


    function uniswapV3SwapCallback(
        int256 amount0, 
        int256 amount1, 
        bytes calldata data) public {

        IUniswapV3Pool.CallbackData memory extraData = abi.decode(
            data, 
            (IUniswapV3Pool.CallbackData)
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