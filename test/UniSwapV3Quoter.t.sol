// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "./ERC20Mintable.sol";
import "../src/UniSwapV3Manager.sol";
import "../src/interfaces/IUniswapV3Pool.sol";
import "../src/UniSwapV3Quoter.sol";
import "./TestUtils.sol";

contract UniSwapQuoterTest is Test, TestUtils   {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniSwapV3Pool pool;
    UniSwapV3Manager manager;
    UniSwapV3Quoter quoter;

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);

        uint256 wethBalance = 100 ether;
        uint256 usdcBalance = 100000 ether;

        token0.mint(address(this), wethBalance);
        token1.mint(address(this), usdcBalance);

        pool = new UniSwapV3Pool(
            address(token0),
            address(token1),
            5602277097478614198912276234240,
            85176
        );

        manager = new UniSwapV3Manager();

        token0.approve(address(manager), wethBalance);
        token1.approve(address(manager), usdcBalance);

        int24 loTick = 84222;
        int24 hiTick = 86129;
        uint128 liquidity = 1517882343751509868544;

        bytes memory extra = abi.encode(IUniswapV3Pool.CallbackData({
            token0: address(token0),
            token1: address(token1),
            payer: address(this)
        }));

        manager.mint(IUniswapV3Manager.MintParams({
                poolAddress: address(pool),
                loTick: TestUtils.tick(4545),
                hiTick: TestUtils.tick(5500),
                amount0Desired: 1 ether,
                amount1Desired: 5000 ether,
                amount0Min: 0,
                amount1Min: 0
            }));

        quoter = new UniSwapV3Quoter();

    }

    function testQuoterETHForUSDC() public {
        (uint256 amountOut, 
        uint160 sqrtPriceAfter, 
        int24 nextTick) = quoter.quote(UniSwapV3Quoter.QuoteParams({
            pool: address(pool),
            zeroForOne: true,
            amountIn: 0.01337 ether
        }));
        assertEq(amountOut, 66.808387150349832078 ether);
        assertEq(sqrtPriceAfter, 5598789786864463348083797021659);
        assertEq(nextTick, 85163);
    }

}