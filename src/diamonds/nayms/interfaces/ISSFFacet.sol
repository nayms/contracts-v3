// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/**
 * @title Sub Surplus Fund
 * @notice Facet for the Sub Surplus Fund
 * @dev SSF facet
 */
interface ISSFFacet {
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
    ) external;

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
    ) external returns (uint256 amountOut);

    /**
    @notice uses the _estimateAmountOut return value to calculate the given reward for the user and perform the transfer
    @param _amountIn is the amount the user paid
    @param _to is the user recieving the reward
    @return returning the value of the end reward paid out
     */
    function payReward(uint256 _amountIn, address _to) external returns (uint256);
}
