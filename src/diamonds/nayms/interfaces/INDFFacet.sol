// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface INDFFacet {
    function getDiscount(uint256 _amountNayms) external returns (uint256);

    function getNaymsValueRatio() external returns (uint256);

    function buyNayms(uint256 _maxWilling) external;

    function paySubSurplusFund(uint256 _amount) external;

    // function swapTokens(
    //     address _tokenIn,
    //     address _tokenOut,
    //     uint256 _amountIn,
    //     uint24 _poolFee
    // ) external returns (uint256 amountOut);
}
