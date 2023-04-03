// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../test/ERC20Mintable.sol";
import "../src/UniSwapV3Pool.sol";
import "../src/UniSwapV3Manager.sol";
import "forge-std/console.sol";


contract DeployDevelopment is Script {
    function run() public {
        uint256 wethBalance = 1 ether;
        uint256 usdcBalance = 5042 ether;
        int24 currentTick = 85176;
        uint160 currentSqrtPrice = 5602277097478614198912276234240;

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

        token0.mint(msg.sender, wethBalance);
        token1.mint(msg.sender, usdcBalance);

        console.log("WETH address", address(token0));
        console.log("USDC address", address(token1));
        console.log("Pool address", address(pool));
        console.log("Manager address", address(manager));


        vm.stopBroadcast();
    }
}