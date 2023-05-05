// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./UniSwapV3Pool.Utils.t.sol";
import "./TestUtils.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./ERC20Mintable.sol";
import "../src/UniSwapV3Pool.sol";
import "../src/interfaces/IUniswapV3Pool.sol";
import "../src/interfaces/IUniswapV3Manager.sol";


contract UniSwapV3PoolSwap is Test, UniSwapV3PoolUtils {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniSwapV3Pool pool;
    bool transferInMintCallback = true;
    bool transferInSwapCallback = true;
    bytes extraData;

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);

        extraData = abi.encode(IUniswapV3Pool.CallbackData({
                token0: address(token0),
                token1: address(token1),
                payer: address(this)
            }));
    }

    function testBuyETHOnePriceRange() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiquidity: true
        });

        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        uint256 swapAmount = 42 ether;
        token1.mint(address(this), swapAmount);
        token1.approve(address(this), swapAmount);

        (int256 balance0Before, int256 balance1Before) = (
            int256(token0.balanceOf(address(this))),
            int256(token1.balanceOf(address(this)))
        );

        (int256 delta0, int256 delta1) = pool.swap(
            address(this),
            false, 
            swapAmount, 
            extraData,
            sqrtP(5004)
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
                currentLiquidity: liquidity[0].amount
            })
        );

    }


    function testBuyETHTwoEqualPriceRanges() public {
        LiquidityRange memory range = liquidityRange(
            4545,
            5500,
            1 ether,
            5000 ether,
            5000
        );
        LiquidityRange[] memory liquidity = new LiquidityRange[](2);
        liquidity[0] = range;
        liquidity[1] = range;
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 2 ether,
            usdcBalance: 10000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiquidity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        uint256 swapAmount = 42 ether; // 42 USDC
        token1.mint(address(this), swapAmount);
        token1.approve(address(this), swapAmount);

        (int256 userBalance0Before, int256 userBalance1Before) = (
            int256(token0.balanceOf(address(this))),
            int256(token1.balanceOf(address(this)))
        );

        (int256 amount0Delta, int256 amount1Delta) = pool.swap(
            address(this),
            false,
            swapAmount,
            extraData,
            sqrtP(5002)
        );

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (
            -0.008398516982770993 ether,
            42 ether
        );

        assertEq(amount0Delta, expectedAmount0Delta, "invalid ETH out");
        assertEq(amount1Delta, expectedAmount1Delta, "invalid USDC in");

        assertSwapState(
            ExpectedStateAfterSwap({
                pool: pool,
                token0: token0,
                token1: token1,
                userBalance0: uint256(userBalance0Before - amount0Delta),
                userBalance1: uint256(userBalance1Before - amount1Delta),
                poolBalance0: uint256(int256(poolBalance0) + amount0Delta),
                poolBalance1: uint256(int256(poolBalance1) + amount1Delta),
                sqrtPriceX96: 5603319704133145322707074461607, // 5001.861214026131
                tick: 85179,
                currentLiquidity: liquidity[0].amount + liquidity[1].amount
            })
        );
    }


    function testSwapBuyUSDCNotEnoughLiquidity() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiquidity: true
        });
        setupTestCase(params);

        uint256 swapAmount = 1.1 ether;
        token0.mint(address(this), swapAmount);
        token0.approve(address(this), swapAmount);

        vm.expectRevert(abi.encodeWithSignature("NotEnoughLiquidity()"));
        pool.swap(address(this), true, swapAmount, extraData, sqrtP(4000));
    }


    function testSwapInsufficientInputAmount() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: false,
            mintLiquidity: true
        });
        setupTestCase(params);

        vm.expectRevert(abi.encodeWithSignature("InsufficientInputAmount()"));
        pool.swap(address(this), false, 42 ether, "", sqrtP(5004));
    }


    function setupTestCase(
        TestCaseParams memory params
        ) internal returns (uint256 poolBalance0, uint256 poolBalance1) {
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        pool = new UniSwapV3Pool(
            address(token0),
            address(token1),
            TestUtils.sqrtP(params.currentPrice),
            TestUtils.tick(params.currentPrice)
        );

        if (params.mintLiquidity) {
            token0.approve(address(this), params.wethBalance);
            token1.approve(address(this), params.usdcBalance);

            uint256 poolBalance0Tmp;
            uint256 poolBalance1Tmp;

            for (uint256 i = 0; i < params.liquidity.length; i++) {
                (poolBalance0Tmp, poolBalance1Tmp) = pool.mint(
                    address(this),
                    params.liquidity[i].loTick,
                    params.liquidity[i].hiTick,
                    params.liquidity[i].amount,
                    extraData
                );

                poolBalance0 += poolBalance0Tmp;
                poolBalance1 += poolBalance1Tmp;
            }
        }

        transferInMintCallback = params.transferInMintCallback;
        transferInSwapCallback = params.transferInSwapCallback;

    }


    function uniswapV3SwapCallback(
        int256 amount0, 
        int256 amount1, 
        bytes calldata data) public {

        if (transferInSwapCallback){
            IUniswapV3Pool.CallbackData memory _extraData = abi.decode(
                data, 
                (IUniswapV3Pool.CallbackData)
            );

            if (amount0 > 0) {
                token0.transferFrom(_extraData.payer, msg.sender, uint256(amount0));
            }

            if (amount1 > 0) {
                token1.transferFrom(_extraData.payer, msg.sender, uint256(amount1));
            }
        }
    }


    function uniswapV3MintCallback(
        uint256 amount0, 
        uint256 amount1, 
        bytes calldata data
        ) public {

        if (transferInMintCallback) {
            IUniswapV3Pool.CallbackData memory extraData = abi.decode(
                data, 
                (IUniswapV3Pool.CallbackData)
            );

            uint256 balance0 = IERC20(extraData.token0).balanceOf(extraData.payer);
            uint256 balance1 = IERC20(extraData.token1).balanceOf(extraData.payer);

            console.log("payer balance0: %s, transfer amount0: %s", balance0, amount0);
            console.log("payer balance1: %s, transfer amount1: %s", balance1, amount1);

            IERC20(extraData.token0).transferFrom(extraData.payer, msg.sender, amount0);
            IERC20(extraData.token1).transferFrom(extraData.payer, msg.sender, amount1);
        }
    }
}

