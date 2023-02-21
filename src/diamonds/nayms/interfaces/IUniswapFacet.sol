// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IUniswapFacet {
    function setLiquidityPool(address poolAddress) external;

    function initNdf(
        int24 _baseThreshold,
        int24 _limitThreshold,
        int24 _maxTwapDeviation,
        uint32 _twapInterval
    ) external;

    function getTick() external view returns (int24 tick);

    function getTwap() external view returns (int24);

    function getSqrtTwapX96(address uniswapV3Pool, uint32 twapInterval) external view returns (uint160 sqrtPriceX96);
}
