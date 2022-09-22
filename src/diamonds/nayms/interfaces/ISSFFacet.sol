// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface ISSFFacet {
    function payRewardsToUser(
        address _tokenIn,
        uint256 _amountIn,
        address _to
    ) external;

    function estimateAmountOut(
        address _tokenIn,
        address _quoteToken,
        uint256 _amountIn,
        uint160 _sqrtPriceX96
    ) external returns (uint256 amountOut);

    function payReward(uint256 _amountIn, address _to) external returns (uint256);
}
