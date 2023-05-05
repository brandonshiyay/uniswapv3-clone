pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

import "./interfaces/IUniswapV3Pool.sol";
import "forge-std/console.sol";

contract UniSwapV3Quoter{

    event ErrorData(bytes errorData);
    event QuoteSwapResult(uint256 amountOut, uint160 sqrtPriceAfter, int24 nextTick); 


    struct QuoteParams {
        address pool;
        uint256 amountIn;
        bool zeroForOne;
        uint160 sqrtPriceLimit;
    }

    function quote(QuoteParams memory params) public returns (
        uint256 amountOut,
        uint160 sqrtPriceAfter,
        int24 nextTick) {
        console.log("--- quote called ---");
        console.logUint(params.amountIn);
        console.logUint(params.sqrtPriceLimit);
        console.log("--------------------");
        try IUniswapV3Pool(params.pool).swap(
                address(this), 
                params.zeroForOne,
                params.amountIn,
                abi.encode(params.pool),
                params.sqrtPriceLimit
            )
        { } catch Error(string memory reason) {
            console.log(reason);
        } catch (bytes memory reason) {
            emit ErrorData(reason);
            return abi.decode(reason, (uint256, uint160, int24));
        } 
    }

    function uniswapV3SwapCallback(
        int256 delta0,
        int256 delta1,
        bytes memory data
    ) external {
        address pool = abi.decode(data, (address));
        console.log("quoter swap callback called, pool@%s", pool);
        uint256 amountOut = delta0 > 0 ?
        uint256(-delta1):
        uint256(-delta0);

        (uint160 sqrtPriceAfter, int24 nextTick) = IUniswapV3Pool(pool).slot0();
        emit QuoteSwapResult(amountOut, sqrtPriceAfter, nextTick);
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, amountOut)
            mstore(add(ptr, 0x20), sqrtPriceAfter)
            mstore(add(ptr, 0x40), nextTick)
            revert(ptr, 96)
        }
    }
}