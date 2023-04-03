pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

// for debugging purpose
import "forge-std/console.sol";

import "./lib/Tick.sol";
import "./lib/Position.sol";
import "./lib/TickBitmap.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV3MintCallback.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";

contract UniSwapV3Pool {
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


    struct CallbackData {
        address token0; 
        address token1;
        address payer;
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

        loFlipped = ticks.update(loTick, amount);
        hiFlipped = ticks.update(hiTick, amount);

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


        // those values will be replaced later
        amount0 = 0.998976618347425280 ether;
        amount1 = 5000 ether;

        liquidity += uint128(amount);

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

    function swap(address recipient, bytes calldata data) public returns (int256 amount0, int256 amount1){
        int24 nextTick = 85184;
        uint160 nextPrice = 5604469350942327889444743441197;

        amount0 = -0.008396714242162444 ether;
        amount1 = 42 ether;

        (slot0.tick, slot0.sqrtPriceX96) = (nextTick, nextPrice);

        IERC20(token0).transfer(recipient, uint256(-amount0));
        uint256 balance1Before = balance1();
        IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);

        if (uint256(amount1) > balance1() - balance1Before) {
            revert InsufficientInputAmount();
        }

        emit Swap(msg.sender, recipient, amount0, amount1, nextPrice, nextTick, liquidity);

    }

}