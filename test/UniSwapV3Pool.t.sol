// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./ERC20Mintable.sol";
import "../src/UniSwapV3Pool.sol";
import "forge-std/console.sol";


contract UniSwapV3PoolTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniSwapV3Pool pool;
    bool shouldTransferInMintCallback = true;
    bool shouldTransferInSwapCallback = false;


    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);
    }


    struct TestCaseParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        int24   currentTick;
        int24 loTick;
        int24 hiTick;
        uint128 liquidity;
        uint160 currentSqrtP;
        bool shouldTransferInMintCallback;
        bool shouldTransferInSwapCallback;
        bool mintLiquidity;
    }


    // success test
    function testMintSuccess() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            loTick: 84222, 
            hiTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInMintCallback: true,
            shouldTransferInSwapCallback: false,
            mintLiquidity: true
        });

        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        uint256 expectedAmount0 = 0.998976618347425280 ether;
        uint256 expectedAmount1 = 5000 ether;

        assertEq(poolBalance0, expectedAmount0, "incorrect token0 amount");
        assertEq(poolBalance1, expectedAmount1, "incorrect token1 amount");

        console.log("amount0: %s; balance0: %s", expectedAmount0, token0.balanceOf(address(pool)));
        console.log("amount1: %s; balance1: %s", expectedAmount1, token1.balanceOf(address(pool)));

        assertEq(token0.balanceOf(address(pool)), expectedAmount0);
        assertEq(token1.balanceOf(address(pool)), expectedAmount1);

        bytes32 positionKey = keccak256(
            abi.encodePacked(address(this), params.loTick, params.hiTick)
        );

        uint128 positionLiquidity = pool.positions(positionKey);

        console.log("position liquidity: %s; expected liquidity: %s", positionLiquidity, params.liquidity);

        assertEq(params.liquidity, positionLiquidity);


        // test results for ticks and liquidity, initially, the liquidity at both
        // loTick and hiTick should be the same as currentTick.
        (bool loTickInitialized, uint128 loTickLiquidity) = pool.ticks(params.loTick);
        (bool hiTickInitialized, uint128 hiTickLiquidity) = pool.ticks(params.loTick);

        console.log("low tick initialized: %s; lower tick liquidity: %s", loTickInitialized, loTickLiquidity);
        console.log("high tick initialized: %s; high tick liquidity: %s", loTickInitialized, loTickLiquidity);

        assertTrue(loTickInitialized);
        assertTrue(hiTickInitialized);

        assertEq(loTickLiquidity, params.liquidity);
        assertEq(hiTickLiquidity, params.liquidity);

        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        assertEq(sqrtPriceX96, params.currentSqrtP, "invalid sqrtP");
        assertEq(tick, params.currentTick, "invalid tick");
        assertEq(pool.liquidity(), params.liquidity, "invalid liquidity");

    } 


    // failure testing
    // 1. Upper and lower ticks are too big or too small.
    // 2. Zero liquidity is provided.
    // 3. Liquidity provider doesn’t have enough of tokens.

    function testTickRange() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            loTick: 84222, 
            hiTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInMintCallback: true,
            shouldTransferInSwapCallback: false,
            mintLiquidity: false
        });


        pool = new UniSwapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            0
        );

        setupTestCase(params);

        vm.expectRevert(abi.encodeWithSignature("InvalidTickRange()"));

        pool.mint(address(this), 0, 1111111, params.liquidity, "");
    }


    function testZeroLiquidity() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            loTick: 84222, 
            hiTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInMintCallback: true,
            shouldTransferInSwapCallback: false,
            mintLiquidity: false
        });

        pool = new UniSwapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        setupTestCase(params);

        vm.expectRevert(abi.encodeWithSignature("ZeroLiquidity()"));

        pool.mint(address(this), params.loTick, params.hiTick, 0, "");
    }


    function testMintInsufficientInput() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 0,
            usdcBalance: 0,
            currentTick: 85176,
            loTick: 84222, 
            hiTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInMintCallback: false,
            shouldTransferInSwapCallback: false,
            mintLiquidity: false
        });

        pool = new UniSwapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        setupTestCase(params);

        vm.expectRevert(abi.encodeWithSignature("InsufficientInputAmount()"));

        pool.mint(address(this), params.loTick, params.hiTick, params.liquidity, "");
    }


    function testSwapBuyETH() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            loTick: 84222, 
            hiTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInMintCallback: true,
            shouldTransferInSwapCallback: true,
            mintLiquidity: true
        });

        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        token1.mint(address(this), 42 ether);

        int256 balance0Before = int256(token0.balanceOf(address(this)));
        int256 balance1Before = int256(token1.balanceOf(address(this)));

        (int256 delta0, int256 delta1) = pool.swap(address(this), "");

        assertEq(delta0, -0.008396714242162444 ether, "invalid ETH out");
        assertEq(delta1, 42 ether, "invalid USDC in");

        assertEq(
            token0.balanceOf(address(this)),
            uint256(balance0Before - delta0),
            "invalid user eth balance"
        );

        assertEq(
            token1.balanceOf(address(this)),
            uint256(balance1Before - delta1),
            "invalid user usdc balance"
        );

        assertEq(
            token0.balanceOf(address(pool)),
            uint256(int256(poolBalance0) + delta0),
            "invalid pool eth balance"
        );

        assertEq(
            token1.balanceOf(address(pool)),
            uint256(int256(poolBalance1) + delta1),
            "invalid pool eth balance"
        );

        (uint160 sqrtX96Price, int24 tick) = pool.slot0();

        assertEq(
            sqrtX96Price,
            5604469350942327889444743441197,
            "invalid sqrt price"
        );

        assertEq(
            tick,
            85184,
            "invalid tick"
        );

        assertEq(
            params.liquidity,
            pool.liquidity(),
            "invalid liquidity"
        );

    }


    function testSwapInsufficientInput() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            loTick: 84222, 
            hiTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInMintCallback: true,
            shouldTransferInSwapCallback: false,
            mintLiquidity: true
        });

        pool = new UniSwapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        setupTestCase(params);

        vm.expectRevert(abi.encodeWithSignature("InsufficientInputAmount()"));

        pool.swap(address(this), "");

    }


    function setupTestCase(TestCaseParams memory params) 
        internal returns (
            uint256 poolBalance0, 
            uint256 poolBalance1
            )
    {
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
            params.currentSqrtP,
            params.currentTick
        );

        shouldTransferInMintCallback = params.shouldTransferInMintCallback;
        shouldTransferInSwapCallback = params.shouldTransferInSwapCallback;

        if (params.mintLiquidity) {
            (poolBalance0, poolBalance1) = pool.mint(
                address(this),
                params.loTick,
                params.hiTick,
                params.liquidity,
                ""
            );
        }
    }


    function uniswapV3SwapCallback(
        int256 amount0, 
        int256 amount1, 
        bytes calldata data) public {

        if (shouldTransferInSwapCallback){
            if (amount0 > 0) {
                token0.transfer(msg.sender, uint256(amount0));
            }

            if (amount1 > 0) {
                token1.transfer(msg.sender, uint256(amount1));
            }
        }
    }


    function uniswapV3MintCallback(
        uint256 amount0, 
        uint256 amount1, 
        bytes calldata data
        ) public {

        if (shouldTransferInMintCallback) {
            UniSwapV3Pool.CallbackData memory extraData = abi.decode(
                data, 
                (UniSwapV3Pool.CallbackData)
            );

            IERC20(extraData.token0).transferFrom(extraData.payer, msg.sender, amount0);
            IERC20(extraData.token1).transferFrom(extraData.payer, msg.sender, amount1);
        }
    }
}
