// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../test/ERC20Mintable.sol";
import "../src/UniSwapV3Pool.sol";
import "../src/UniSwapV3Manager.sol";
import "../src/UniSwapV3Quoter.sol";
import "forge-std/console.sol";
import "../test/TestUtils.sol";


contract DeployDevelopment is Script, TestUtils {
    function run() public {
        uint256 wethBalance = 10 ether;
        uint256 usdcBalance = 100000 ether;
        int24 currentTick = tick(5000);
        uint160 currentSqrtPrice = sqrtP(5000);

        vm.startBroadcast();

        ERC20Mintable token0 = new ERC20Mintable("Ether", "ETH", 18);
        ERC20Mintable token1 = new ERC20Mintable("USDC", "USDC", 18);

        UniSwapV3Pool pool = new UniSwapV3Pool(
            address(token0),
            address(token1),
            currentSqrtPrice,
            currentTick
        );

        UniSwapV3Manager manager = new UniSwapV3Manager();
        UniSwapV3Quoter quoter = new UniSwapV3Quoter();

        token0.mint(msg.sender, wethBalance);
        token1.mint(msg.sender, usdcBalance);

        token0.approve(address(manager), wethBalance);
        token1.approve(address(manager), usdcBalance);

        vm.stopBroadcast();

        console.log("WETH address", address(token0));
        console.log("USDC address", address(token1));
        console.log("Pool address", address(pool));
        console.log("Manager address", address(manager));
        console.log("Quoter address", address(quoter));

    }
}