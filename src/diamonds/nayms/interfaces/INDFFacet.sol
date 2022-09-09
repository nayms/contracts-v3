// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/**
 * @title Nayms Discretionary Fund
 * @notice Facet for the Nayms Discretionary Fund
 * @dev NDF facet
 */
interface INDFFacet {
    function getDiscount(uint256 _amountNayms) external returns (uint256);

    function getNaymsValueRatio() external returns (uint256);

    /**
     * @notice Buy `_maxWilling` from NDF
     * @dev Buy discounted tokens from NDF
     * @param _maxWilling Max amount of tokens willing to spend
     */
    function buyNayms(uint256 _maxWilling) external;

    /**
     * @notice Pay `_amount` to the SubSurplus Fund
     * @dev Pay the amount to the SSF
     * @param _amount Amount to pay to the SSF
     */
    function paySubSurplusFund(uint256 _amount) external;

    /**
     * @notice Swap `_amountIn` of `_tokenIn` for `_tokenOut` tokens with fee of `_poolFee`
     * @dev Swap tokens on Uniswap
     * @param _tokenIn Token to swap
     * @param _tokenOut Token to get
     * @param _amountIn Amount to swap
     * @param _poolFee Fee payed to the pool
     * @return amountOut Tokens received
     */
    function swapTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint24 _poolFee
    ) external returns (uint256 amountOut);
}
