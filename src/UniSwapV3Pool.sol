pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

// for debugging purpose
import "forge-std/console.sol";

import "./lib/Tick.sol";
import "./lib/TickMath.sol";
import "./lib/SwapMath.sol";
import "./lib/Position.sol";
import "./lib/TickBitmap.sol";
import "./lib/LiquidityMath.sol";
import "./lib/Math.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV3MintCallback.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";

contract UniSwapV3Pool is IUniswapV3Pool{
    using TickBitmap for mapping(int16 => uint256);
    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping (bytes32 => Position.Info);
    using Position for Position.Info;

    event Mint(
        address sender, 
        address owner, 
        int24 loTick, 
        int24 hiTick, 
        uint128 amount, 
        uint256 amount0, 
        uint256 amount1
    );

    event Swap(
        address sender,
        address recipient,
        int256 amount0, 
        int256 amount1,
        uint160 sqrtX96Price,
        int24 tick,
        uint128 liquidity
    );

    error InvalidTickRange();
    error ZeroLiquidity();
    error InsufficientInputAmount();
    error NotEnoughLiquidity();

    // https://uniswap.org/blog/uniswap-v3-math-primer
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    address public immutable token0;
    address public immutable token1;

    struct Slot0 {
        // current sqrt(P)
        uint160     sqrtPriceX96;
        // current tick
        int24       tick;
    }

    struct SwapState {
        uint256 amountRemaining;
        uint256 amountCalculated;
        int24 tick;
        uint160 sqrtPrice;
        uint128 liquidity;
    }

    struct StepState {
        uint160 sqrtPriceBefore;
        uint160 sqrtPriceAfter;
        int24 nextTick;
        uint256 amountIn;
        uint256 amountOut;
    }


    Slot0 public slot0;

    // amount of liquidity
    uint128 public liquidity;

    // tick info
    mapping(int24 => Tick.Info) public ticks;
    // position info
    mapping(bytes32 => Position.Info) public positions;

    mapping(int16 => uint256) public tickBitmap;

    constructor(
        address _token0,
        address _token1,
        uint160 _sqrtPriceX96,
        int24 _tick
    ) {

        token0 = _token0;
        token1 = _token1;

        slot0 = Slot0({
            sqrtPriceX96: _sqrtPriceX96,
            tick: _tick
        });

    }

    function mint(
        address owner,
        int24 loTick,
        int24 hiTick,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1){

        if (loTick >= hiTick || loTick < MIN_TICK || hiTick > MAX_TICK){
            revert InvalidTickRange();
        }
        if (amount == 0) {
            revert ZeroLiquidity();
        }

        bool loFlipped = ticks.update(loTick, int128(amount), false);
        bool hiFlipped = ticks.update(hiTick, int128(amount), true);

        if (loFlipped) {
            tickBitmap.flipTick(loTick, 1);
        }

        if (hiFlipped) {
            tickBitmap.flipTick(hiTick, 1);
        }

        Position.Info storage position = positions.get(
            owner, 
            loTick, 
            hiTick
        );

        position.update(amount);

        Slot0 memory _slot0 = slot0;

        console.log("sqrtPriceX96: %s", _slot0.sqrtPriceX96);
        console.log("liquidity: %s", amount);
        console.log("hiSqrtPriceX96: %s", TickMath.getSqrtRatioAtTick(hiTick));
        console.log("loSqrtPriceX96: %s", TickMath.getSqrtRatioAtTick(loTick));

        if (_slot0.tick < loTick) {
            amount0 = Math.calcDelta0(
                TickMath.getSqrtRatioAtTick(loTick),
                TickMath.getSqrtRatioAtTick(hiTick),
                amount
            );

        } else if (_slot0.tick < hiTick) {
            amount0 = Math.calcDelta0(
                _slot0.sqrtPriceX96, 
                TickMath.getSqrtRatioAtTick(hiTick),
                amount);

            amount1 = Math.calcDelta1(
                _slot0.sqrtPriceX96, 
                TickMath.getSqrtRatioAtTick(loTick),
                amount);

            liquidity = LiquidityMath.addLiquidity(liquidity, int128(amount));

        } else {
            amount1 = Math.calcDelta1(
                TickMath.getSqrtRatioAtTick(loTick),
                TickMath.getSqrtRatioAtTick(hiTick),
                amount
            );
        }

        uint256 balance0Before;
        uint256 balance1Before;


        if (amount0 > 0) {
            balance0Before = balance0();
        }

        if (amount1 > 0) {
            balance1Before = balance1();
        }

        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);
        console.log("amount0: %s; balance0: %s; balance0(): %s", amount0, balance0Before, balance0());
        console.log("amount1: %s; balance1: %s; balance1(): %s", amount1, balance1Before, balance1());
        
        if (amount0 > 0 && balance0Before + amount0 > balance0()){
            revert InsufficientInputAmount();
        }

        if (amount1 > 0 && balance1Before + amount1 > balance1()) {
            revert InsufficientInputAmount();
        }

        emit Mint(msg.sender, owner, loTick, hiTick, amount, amount0, amount1);

    }

    function balance0() internal returns (uint256 balance){
        balance = IERC20(token0).balanceOf(address(this));
    }

    function balance1() internal returns (uint256 balance){
        balance = IERC20(token1).balanceOf(address(this));
    }

    function swap(
        address recipient, 
        bool zeroForOne,
        uint256 amountSpecified,
        bytes calldata data
        ) public returns (int256 amount0, int256 amount1){

        Slot0 memory _slot0 = slot0;
        uint128 _liquidity = liquidity;

        SwapState memory state = SwapState({
            amountRemaining: amountSpecified,
            amountCalculated: 0,
            sqrtPrice: _slot0.sqrtPriceX96,
            tick: _slot0.tick,
            liquidity: _liquidity
        });

        while (state.amountRemaining > 0) {
            StepState memory step;

            step.sqrtPriceBefore = state.sqrtPrice;
            (step.nextTick, ) = tickBitmap.nextInitializedTickWithinOneWord(
                state.tick,
                1,
                zeroForOne
            );

            step.sqrtPriceAfter = TickMath.getSqrtRatioAtTick(step.nextTick);

            (state.sqrtPrice, step.amountIn, step.amountOut) = SwapMath.computeSwapStep(
                step.sqrtPriceBefore, 
                step.sqrtPriceAfter,
                liquidity,
                state.amountRemaining
            );

            state.amountRemaining -= step.amountIn;
            state.amountCalculated += step.amountOut;
            state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPrice);

            console.log(
                "amountRemained: %s , amountCalculated: %s", 
                state.amountRemaining,
                state.amountCalculated);

            if (state.sqrtPrice == step.sqrtPriceAfter) {
                int128 liquidityDelta = ticks.cross(step.nextTick);

                if (zeroForOne) {
                    liquidityDelta = -liquidityDelta;
                }

                state.liquidity = LiquidityMath.addLiquidity(
                    state.liquidity,
                    liquidityDelta
                );

                if (state.liquidity == 0) {
                    revert NotEnoughLiquidity();
                }

                state.tick = zeroForOne ? step.nextTick - 1 : step.nextTick;
            } else {
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPrice);

            }
                
        }

        if (state.tick != _slot0.tick) {
            (slot0.tick, slot0.sqrtPriceX96) = (state.tick, state.sqrtPrice);
        }
        
        (amount0, amount1) = zeroForOne? 
        (int256(amountSpecified - state.amountRemaining), -int256(state.amountCalculated)):
        (-int256(state.amountCalculated), int256(amountSpecified - state.amountRemaining));

        if (zeroForOne) {
            IERC20(token1).transfer(recipient, uint256(-amount1));

            uint256 balance0Before = balance0();
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);

            if (uint256(amount0) > balance0() - balance0Before) {
                revert InsufficientInputAmount();
            }
        } else {
            IERC20(token0).transfer(recipient, uint256(-amount0));

            uint256 balance1Before = balance1();
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);

            if (uint256(amount1) > balance1() - balance1Before) {
                revert InsufficientInputAmount();
            }
        }

        emit Swap(msg.sender, recipient, amount0, amount1, _slot0.sqrtPriceX96, _slot0.tick, liquidity);

    }

}
