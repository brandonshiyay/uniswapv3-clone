// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./ERC20Mintable.sol";
import "../src/UniSwapV3Pool.sol";
import "forge-std/console.sol";
import "./UniSwapV3Pool.Utils.t.sol";
import "./TestUtils.sol";


contract UniSwapV3PoolTest is Test, UniSwapV3PoolUtils {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniSwapV3Pool pool;
    bool transferInMintCallback = true;
    bool transferInSwapCallback = false;


    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);
    }


    // success test
    function testMintInRange() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000.3 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiquidity: true
        });

        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            0.998995580131581600 ether,
            4999.999999999999999999 ether
        );

        int24 loTick = liquidity[0].loTick;
        int24 hiTick = liquidity[0].hiTick;
        uint128 _liquidity = liquidity[0].amount;


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


    function testTickBelowRange() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4000, 4999, 1 ether, 5000 ether, 5000);
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

        uint256 expectedAmount0 = 0 ether;
        uint256 expectedAmount1 = 4999.999999999999999997 ether;

        int24 loTick = liquidity[0].loTick;
        int24 hiTick = liquidity[0].hiTick;
        uint128 _liquidity = liquidity[0].amount;


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
                positionLiquidity: liquidity[0].amount,
                currentLiquidity: 0,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000)
            })
        );
    }


    function testTickAboveRange() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(5001, 6250, 1 ether, 5000 ether, 5000);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 10 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiquidity: true
        });


        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        uint256 expectedAmount0 = 1 ether;
        uint256 expectedAmount1 = 0 ether;

        int24 loTick = liquidity[0].loTick;
        int24 hiTick = liquidity[0].hiTick;
        uint128 _liquidity = liquidity[0].amount;


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

    function testZeroLiquidity() public {
        pool = new UniSwapV3Pool(
            address(token0),
            address(token1),
            uint160(1),
            0
        );


        vm.expectRevert(abi.encodeWithSignature("ZeroLiquidity()"));

        pool.mint(address(this), 0, 1, 0, "");
    }


    function testMintInsufficientInput() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 0,
            usdcBalance: 0,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: false,
            transferInSwapCallback: false,
            mintLiquidity: false
        });

        setupTestCase(params);
        vm.expectRevert(abi.encodeWithSignature("InsufficientInputAmount()"));

        pool.mint(
            address(this),
            params.liquidity[0].loTick,
            params.liquidity[0].hiTick,
            params.liquidity[0].amount,
            ""
        );
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


    function setupTestCase(TestCaseParams memory params) 
        internal returns (
            uint256 poolBalance0, 
            uint256 poolBalance1
            )
    {
        console.log("test case runner address: %s", address(this));

        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        console.log(
            "token0 initial balance: %s; actual balance: %s", 
            params.wethBalance, 
            IERC20(address(token0)).balanceOf(address(this))
        );

        console.log(
            "token1 initial balance: %s; actual balance: %s", 
            params.usdcBalance, 
            IERC20(address(token1)).balanceOf(address(this))
        );

        pool = new UniSwapV3Pool(
            address(token0),
            address(token1),
            sqrtP(params.currentPrice),
            tick(params.currentPrice)
        );

        transferInMintCallback = params.transferInMintCallback;
        transferInSwapCallback = params.transferInSwapCallback;

        if (params.mintLiquidity) {
            token0.approve(address(this), params.wethBalance);
            token1.approve(address(this), params.usdcBalance);

            bytes memory extra = abi.encode(IUniswapV3Pool.CallbackData({
                token0: address(token0),
                token1: address(token1),
                payer: address(this)
            }));

            uint256 poolBalance0Tmp;
            uint256 poolBalance1Tmp;

            for (uint256 i = 0; i < params.liquidity.length; i++) {

                (poolBalance0Tmp, poolBalance1Tmp) = pool.mint(
                    address(this),
                    params.liquidity[i].loTick,
                    params.liquidity[i].hiTick,
                    params.liquidity[i].amount,
                    extra
                );

                poolBalance0 += poolBalance0Tmp;
                poolBalance1 += poolBalance1Tmp;
            }

        }
    }
}
