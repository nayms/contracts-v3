// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { ReentrancyGuard } from "src/utils/ReentrancyGuard.sol";
import { Modifiers } from "../AppStorage.sol";
import { LibSSF } from "../libs/LibSSF.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";

/**
 * @title Sub Surplus Fund
 * @notice Facet for the Sub Surplus Fund
 * @dev SSF facet
 */
contract SSFFacet is Modifiers, ReentrancyGuard {
    /**
     * @notice Pay `_amountIn` tokens of reward to `_to`
     * @dev Uses the _estimateAmountOut function to calculate the given reward for the user and perform the transfer
     * @param _tokenIn is the token the user paid the premium in
     * @param _amountIn is the amount the user paid
     * @param _to is the address of the user recieving the reward
     */
    function payRewardsToUser(
        address _tokenIn,
        uint256 _amountIn,
        address _to
    ) public assertSysAdmin nonReentrant returns (uint256) {
        return LibSSF._payRewardsToUser(_tokenIn, _amountIn, _to);
    }

    /**
     * @notice Estimate conversion rate of `_amountIn` tokens
     * @dev Uses the uniswap V3 library to recieve a conversion between two tokens
     * @param _tokenIn is the address of the token we are qouting from
     * @param _quoteToken is the address of the token we want the quote of
     * @param _amountIn is the amount of the tokenIn that was paid
     * @param _sqrtPriceX96 is the sqrt price needed
     * @return amountOut is the amount of the quote token that equals the inputted token
     */
    function estimateAmountOut(
        address _tokenIn,
        address _quoteToken,
        uint256 _amountIn,
        uint160 _sqrtPriceX96
    ) public assertSysAdmin nonReentrant returns (uint256) {
        return LibSSF._estimateAmountOut(_tokenIn, _quoteToken, _amountIn, _sqrtPriceX96);
    }

    /**
     * @notice uses the _estimateAmountOut return value to calculate the given reward for the user and perform the transfer
     * @param _amountIn is the amount the user paid
     * @param _to is the user recieving the reward
     * @return returning the value of the end reward paid out
     */
    function payReward(uint256 _amountIn, address _to) public returns (uint256) {
        return LibSSF._payReward(_amountIn, _to);
    }
}
