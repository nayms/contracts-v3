// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC20 } from "../interfaces/IERC20.sol";

import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

// import { TransferHelper } from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import { TransferHelper } from "src/utils/TransferHelper.sol";

library LibUniswap {
    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    event TokensSwapped(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    // uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    // uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    function _swapTokensExactInput(address _tokenIn, address _tokenOut, uint256 _amountIn, uint24 _poolFee) internal returns (uint256 amountOut) {
        require(_amountIn > 0, "Amount must be larger than zero");

        TransferHelper.safeApprove(_tokenIn, address(router), _amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        amountOut = router.exactInputSingle(params);

        emit TokensSwapped(_tokenIn, _tokenOut, _amountIn, amountOut);

        return amountOut;
    }
}
