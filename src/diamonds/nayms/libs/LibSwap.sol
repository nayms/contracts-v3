// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { TransferHelper } from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import { console2 } from "forge-std/console2.sol";

/// @notice contains internal methods for Token Swapping Functionality
library LibSwap {
    address private constant SWAP_ROUTER02 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    event TokensSwapped(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    function _swapTokensExactInput(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint24 _poolFee
    ) internal returns (uint256 amountOut) {
        require(_amountIn > 0, "Amount must be larger than zero");

        ISwapRouter router = ISwapRouter(SWAP_ROUTER02);

        TransferHelper.safeApprove(_tokenIn, address(router), _amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _poolFee,
            recipient: address(msg.sender),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        amountOut = ISwapRouter(address(router)).exactInputSingle(params);

        emit TokensSwapped(_tokenIn, _tokenOut, _amountIn, amountOut);

        return amountOut;
    }
}
