pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

import "./interfaces/IUniswapV3Pool.sol";

contract UniSwapV3Quoter{
    event ErrorData(bytes errorData);
    
    struct QuoteParams {
        address pool;
        uint256 amountIn;
        bool zeroForOne;
    }

    function quote(QuoteParams memory params) public returns (
        uint256 amountOut,
        uint160 sqrtPriceAfter,
        int24 nextTick) {
        
        try IUniswapV3Pool(params.pool).swap(
                address(this), 
                params.zeroForOne,
                params.amountIn,
                abi.encode(params.pool)
            )
        { } catch (bytes memory reason) {
            emit ErrorData(reason);
            return abi.decode(reason, (uint256, uint160, int24));
        }
    }

    function uniswapV3SwapCallback(
        int256 delta0,
        int256 delta1,
        bytes memory data
    ) external view {
        address pool = abi.decode(data, (address));

        uint256 amountOut = delta0 > 0 ?
        uint256(-delta1):
        uint256(-delta0);

        (uint160 sqrtPriceAfter, int24 nextTick) = IUniswapV3Pool(pool).slot0();

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, amountOut)
            mstore(add(ptr, 0x20), sqrtPriceAfter)
            mstore(add(ptr, 0x40), nextTick)
            revert(ptr, 96)
        }
    }
}