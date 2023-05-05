// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./ERC20Mintable.sol";
import "forge-std/console.sol";
import "../src/UniSwapV3Manager.sol";
import "../src/UniSwapV3Quoter.sol";
import "../src/interfaces/IUniswapV3Pool.sol";
import "../src/interfaces/IUniswapV3Manager.sol";
import "./TestUtils.sol";

contract DeploymentTest is Test, TestUtils {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniSwapV3Pool pool;
    UniSwapV3Manager manager;
    UniSwapV3Quoter quoter;

    function setUp() public {
        uint256 wethBalance = 10 ether;
        uint256 usdcBalance = 100000 ether;
        int24 currentTick = tick(5000);
        uint160 currentSqrtPrice = sqrtP(5000);
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);

        pool = new UniSwapV3Pool(
            address(token0),
            address(token1),
            currentSqrtPrice,
            currentTick
        );

        manager = new UniSwapV3Manager();
        quoter = new UniSwapV3Quoter();

        token0.mint(address(this), wethBalance);
        token1.mint(address(this), usdcBalance);

        token0.approve(address(manager), wethBalance);
        token1.approve(address(manager), usdcBalance);

        console.log("WETH address", address(token0));
        console.log("USDC address", address(token1));
        console.log("Pool address", address(pool));
        console.log("Manager address", address(manager));
        console.log("Quoter address", address(quoter));
    }


    function testAddLiquidity() public {
        console.log("liquidity before: %s", pool.liquidity());
        IUniswapV3Manager.MintParams memory params = mintParams(4545, 5500, 1 ether, 5000 ether);
        manager.mint(params);
        console.log("liquidity after %s", pool.liquidity());
    }


    function testQuoterZeroForOne() public {
        UniSwapV3Quoter.QuoteParams memory params = UniSwapV3Quoter.QuoteParams({
            pool: address(pool),
            amountIn: 0.1 ether,
            zeroForOne: true,
            sqrtPriceLimit: sqrtP(4000)
        });

        (uint256 amountOut, uint160 sqrtPriceAfter, int24 nextTick) = quoter.quote(params);
        console.log("amount out %s", amountOut);
        console.log("sqrt price after %s", sqrtPriceAfter);
        console.logInt(nextTick);
    }


    function mintParams(
        uint256 lowerPrice,
        uint256 upperPrice,
        uint256 amount0,
        uint256 amount1
    ) internal returns (IUniswapV3Manager.MintParams memory params) {
        params = IUniswapV3Manager.MintParams({
            poolAddress: address(pool), // set in setupTestCase
            loTick: tick(lowerPrice),
            hiTick: tick(upperPrice),
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0
        });
    }
}