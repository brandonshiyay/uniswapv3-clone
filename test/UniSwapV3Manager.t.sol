// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./ERC20Mintable.sol";
import "forge-std/console.sol";
import "../src/UniSwapV3Manager.sol";
import "../src/interfaces/IUniswapV3Pool.sol";
import "./TestUtils.sol";

contract UniSwapManagerTest is Test, TestUtils {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniSwapV3Pool pool;
    UniSwapV3Manager manager;

    bool transferInMintCallback = true;
    bool transferInSwapCallback = true;

    bytes extraData;

    struct TestCaseParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        uint256 currentPrice;
        IUniswapV3Manager.MintParams[] mints;
        bool transferInMintCallback;
        bool transferInSwapCallback;
        bool mintLiqudity;
    }

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);
        manager = new UniSwapV3Manager();
        extraData = abi.encode(IUniswapV3Pool.CallbackData({
            token0: address(token0),
            token1: address(token1),
            payer: address(this)
            }));
    }

    function testManagerMintInRange() public {
        IUniswapV3Manager.MintParams[]
            memory mints = new IUniswapV3Manager.MintParams[](1);
        mints[0] = mintParams(4545, 5500, 1 ether, 5000 ether);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            mints: mints,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            0.998995580131581600 ether,
            4999.999999999999999999 ether
        );

        int24 loTick = mints[0].loTick;
        int24 hiTick = mints[0].hiTick;
        uint128 _liquidity = liquidity(mints[0], 5000);


        assertEq(
            poolBalance0,
            expectedAmount0,
            "incorrect token0 deposited amount"
        );
        assertEq(
            poolBalance1,
            expectedAmount1,
            "incorrect token1 deposited amount"
        );

        assertMintState(
            ExpectedStateAfterMint({
                pool: pool,
                token0: token0,
                token1: token1,
                amount0: expectedAmount0,
                amount1: expectedAmount1,
                lowerTick: loTick,
                upperTick: hiTick,
                positionLiquidity: _liquidity,
                currentLiquidity: _liquidity,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000)
            })
        );
    }

    function testManagerMintBelowRange() public {
        IUniswapV3Manager.MintParams[]
            memory mints = new IUniswapV3Manager.MintParams[](1);
        mints[0] = mintParams(4000, 4999, 1 ether, 5000 ether);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            mints: mints,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });

        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            0 ether,
            4999.999999999999999997 ether
        );

        int24 loTick = mints[0].loTick;
        int24 hiTick = mints[0].hiTick;
        uint128 _liquidity = liquidity(mints[0], 5000);


        assertEq(
            poolBalance0,
            expectedAmount0,
            "incorrect token0 deposited amount"
        );
        assertEq(
            poolBalance1,
            expectedAmount1,
            "incorrect token1 deposited amount"
        );

        assertMintState(
            ExpectedStateAfterMint({
                pool: pool,
                token0: token0,
                token1: token1,
                amount0: expectedAmount0,
                amount1: expectedAmount1,
                lowerTick: loTick,
                upperTick: hiTick,
                positionLiquidity: _liquidity,
                currentLiquidity: 0,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000)
            })
        );
    }


    function testManagerMintAboveRange() public {
        IUniswapV3Manager.MintParams[]
            memory mints = new IUniswapV3Manager.MintParams[](1);
        mints[0] = mintParams(5001, 6250, 1 ether, 5000 ether);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 10 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            mints: mints,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });

        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            1 ether,
            0 ether
        );

        int24 loTick = mints[0].loTick;
        int24 hiTick = mints[0].hiTick;
        uint128 _liquidity = liquidity(mints[0], 5000);


        assertEq(
            poolBalance0,
            expectedAmount0,
            "incorrect token0 deposited amount"
        );
        assertEq(
            poolBalance1,
            expectedAmount1,
            "incorrect token1 deposited amount"
        );

        assertMintState(
            ExpectedStateAfterMint({
                pool: pool,
                token0: token0,
                token1: token1,
                amount0: expectedAmount0,
                amount1: expectedAmount1,
                lowerTick: loTick,
                upperTick: hiTick,
                positionLiquidity: _liquidity,
                currentLiquidity: 0,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000)
            })
        );
    }


    function testManagerSwapUSDCForEth() public {
        IUniswapV3Manager.MintParams[]
            memory mints = new IUniswapV3Manager.MintParams[](1);
        mints[0] = mintParams(4545, 5500, 1 ether, 5000 ether);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            mints: mints,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        uint256 swapAmount = 42 ether; // 42 USDC
        token1.mint(address(this), swapAmount);
        token1.approve(address(manager), swapAmount);

        (int256 balance0Before, int256 balance1Before) = (
            int256(token0.balanceOf(address(this))),
            int256(token1.balanceOf(address(this)))
        );

        (int256 delta0, int256 delta1) = manager.swap(
            address(pool),
            false,
            swapAmount,
            extraData
        );

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (
            -0.008396874645169943 ether,
            42 ether
        );

        assertEq(delta0, expectedAmount0Delta, "invalid ETH out");
        assertEq(delta1, expectedAmount1Delta, "invalid USDC in");

        assertSwapState(
            ExpectedStateAfterSwap({
                pool: pool,
                token0: token0,
                token1: token1,
                userBalance0: uint256(balance0Before - delta0),
                userBalance1: uint256(balance1Before - delta1),
                poolBalance0: uint256(int256(poolBalance0) + delta0),
                poolBalance1: uint256(int256(poolBalance1) + delta1),
                sqrtPriceX96: 5604415652688968742392013927525, // 5003.8180249710795
                tick: 85183,
                currentLiquidity: liquidity(mints[0], 5000)
            })
        );
    }


    function mintParams(
        uint256 lowerPrice,
        uint256 upperPrice,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (IUniswapV3Manager.MintParams memory params) {
        params = IUniswapV3Manager.MintParams({
            poolAddress: address(0x0), // set in setupTestCase
            loTick: TestUtils.tick(lowerPrice),
            hiTick: TestUtils.tick(upperPrice),
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0
        });
    }


    function liquidity(
        IUniswapV3Manager.MintParams memory params,
        uint256 currentPrice
    ) internal pure returns (uint128 liquidity_) {
        liquidity_ = LiquidityMath.getLiquidityForAmounts(
            TestUtils.sqrtP(currentPrice),
            TickMath.getSqrtRatioAtTick(params.loTick),
            TickMath.getSqrtRatioAtTick(params.hiTick),
            params.amount0Desired,
            params.amount1Desired
        );
    }


    function setupTestCase(TestCaseParams memory params)
        internal
        returns (uint256 poolBalance0, uint256 poolBalance1)
    {
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        pool = new UniSwapV3Pool(
            address(token0),
            address(token1),
            TestUtils.sqrtP(params.currentPrice),
            TestUtils.tick(params.currentPrice)
        );

        if (params.mintLiqudity) {
            token0.approve(address(manager), params.wethBalance);
            token1.approve(address(manager), params.usdcBalance);

            uint256 poolBalance0Tmp;
            uint256 poolBalance1Tmp;
            for (uint256 i = 0; i < params.mints.length; i++) {
                params.mints[i].poolAddress = address(pool);
                (poolBalance0Tmp, poolBalance1Tmp) = manager.mint(
                    params.mints[i]
                );

                poolBalance0 += poolBalance0Tmp;
                poolBalance1 += poolBalance1Tmp;
            }
        }

        transferInMintCallback = params.transferInMintCallback;
        transferInSwapCallback = params.transferInSwapCallback;
    }

    
}