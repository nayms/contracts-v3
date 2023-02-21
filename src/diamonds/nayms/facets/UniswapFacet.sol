// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/**
 * @title NDF
 */
contract UniswapFacet {
    function initNdf(
        int24 _baseThreshold,
        int24 _limitThreshold,
        int24 _maxTwapDeviation,
        uint32 _twapInterval
    ) external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        int24 tickSpacing = IUniswapV3Pool(s.lpAddress).tickSpacing();
        s.tickSpacing = tickSpacing;

        s.baseThreshold = _baseThreshold;
        s.limitThreshold = _limitThreshold;
        s.maxTwapDeviation = _maxTwapDeviation;
        s.twapInterval = _twapInterval;

        _checkThreshold(_baseThreshold, tickSpacing);
        _checkThreshold(_limitThreshold, tickSpacing);
        require(_maxTwapDeviation > 0, "maxTwapDeviation");
        require(_twapInterval > 0, "twapInterval");

        (, s.lastTick, , , , , ) = IUniswapV3Pool(s.lpAddress).slot0();
    }

    // todo move to AdminFacet
    function setLiquidityPool(address poolAddress) external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.lpAddress = poolAddress;
    }

    function rebalance() external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        int24 _baseThreshold = s.baseThreshold;
        int24 _limitThreshold = s.limitThreshold;

        // Check price is not too close to min/max allowed by Uniswap. Price
        // shouldn't be this extreme unless something was wrong with the pool.
        int24 tick = getTick();
        int24 maxThreshold = _baseThreshold > _limitThreshold ? _baseThreshold : _limitThreshold;
        require(tick > TickMath.MIN_TICK + maxThreshold + s.tickSpacing, "tick too low");
        require(tick < TickMath.MAX_TICK - maxThreshold - s.tickSpacing, "tick too high");

        // Check price has not moved a lot recently. This mitigates price
        // manipulation during rebalance and also prevents placing orders
        // when it's too volatile.
        int24 twap = getTwap();
        int24 deviation = tick > twap ? tick - twap : twap - tick;
        require(deviation <= s.maxTwapDeviation, "maxTwapDeviation");

        int24 tickFloor = _floor(tick);
        int24 tickCeil = tickFloor + s.tickSpacing;

        // vault.rebalance(0, 0, tickFloor - _baseThreshold, tickCeil + _baseThreshold, tickFloor - _limitThreshold, tickFloor, tickCeil, tickCeil + _limitThreshold);

        s.lastRebalance = block.timestamp;
        s.lastTick = tick;
    }

    /// @dev Fetches current price in ticks from Uniswap pool.
    function getTick() public view returns (int24 tick) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        (, tick, , , , , ) = IUniswapV3Pool(s.lpAddress).slot0();
    }

    /// @dev Fetches time-weighted average price in ticks from Uniswap pool.
    function getTwap() public view returns (int24) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint32 _twapInterval = s.twapInterval;
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = _twapInterval;
        secondsAgo[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(s.lpAddress).observe(secondsAgo);
        return int24((tickCumulatives[1] - tickCumulatives[0]) / int56(uint56(_twapInterval)));
    }

    /// @dev Fetches time-weighted average price from Uniswap pool.
    function getSqrtTwapX96(address uniswapV3Pool, uint32 twapInterval) public view returns (uint160 sqrtPriceX96) {
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(int24((tickCumulatives[1] - tickCumulatives[0]) / int56(uint56(twapInterval))));
        }
    }

    function getPriceX96FromSqrtPriceX96(uint160 sqrtPriceX96) public pure returns (uint256 priceX96) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    /// @dev Rounds tick down towards negative infinity so that it's a multiple
    /// of `tickSpacing`.
    function _floor(int24 tick) internal view returns (int24) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        int24 compressed = tick / s.tickSpacing;
        if (tick < 0 && tick % s.tickSpacing != 0) compressed--;
        return compressed * s.tickSpacing;
    }

    function _checkThreshold(int24 threshold, int24 _tickSpacing) internal pure {
        require(threshold > 0, "threshold > 0");
        require(threshold <= TickMath.MAX_TICK, "threshold too high");
        require(threshold % _tickSpacing == 0, "threshold % tickSpacing");
    }

    function setBaseThreshold(int24 _baseThreshold) external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        _checkThreshold(_baseThreshold, s.tickSpacing);
        s.baseThreshold = _baseThreshold;
    }

    function setLimitThreshold(int24 _limitThreshold) external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        _checkThreshold(_limitThreshold, s.tickSpacing);
        s.limitThreshold = _limitThreshold;
    }

    function setMaxTwapDeviation(int24 _maxTwapDeviation) external {
        require(_maxTwapDeviation > 0, "maxTwapDeviation");
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.maxTwapDeviation = _maxTwapDeviation;
    }

    function settwapInterval(uint32 _twapInterval) external {
        require(_twapInterval > 0, "twapInterval");
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.twapInterval = _twapInterval;
    }

    //// NDF functionality todo move to separate facet
}
