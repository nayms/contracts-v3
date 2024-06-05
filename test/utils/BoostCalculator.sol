// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { console as c } from "forge-std/Test.sol";

library BoostCalculator {
    int256 constant SCALE_FACTOR = 1e18;

    function calculateBoost(int256 startTime, int256 currentTime, int256 a, int256 r, int256 tn) internal pure returns (int256) {
        int256 startInterval = startTime / tn;
        int256 currentInterval = currentTime / tn;

        int256 timeFromStartIntervalToCurrentInterval = (currentInterval - startInterval) * tn;

        int256 otherTime;
        if (timeFromStartIntervalToCurrentInterval > tn) {
            otherTime = timeFromStartIntervalToCurrentInterval - tn;
        }

        int256 timeAfterStartInterval = startTime - tn * startInterval;

        int256 multiplier;
        int256 multiplier1 = (timeAfterStartInterval * SCALE_FACTOR) / tn;
        int256 multiplier0 = SCALE_FACTOR - multiplier1;

        if (timeFromStartIntervalToCurrentInterval > otherTime) {
            multiplier += (multiplier0 * m(timeFromStartIntervalToCurrentInterval, a, r, tn)) / SCALE_FACTOR;

            if (timeFromStartIntervalToCurrentInterval > tn) {
                multiplier += (multiplier1 * m(otherTime, a, r, tn)) / SCALE_FACTOR;
            }
        }

        return multiplier;
    }

    function m(int256 t, int256 a, int256 r, int256 tn) internal pure returns (int256) {
        int256 k = t / tn;
        int256 m1 = SCALE_FACTOR + ((a * (SCALE_FACTOR - pow(r, k))) / (SCALE_FACTOR - r));
        int256 m2 = SCALE_FACTOR + ((a * (SCALE_FACTOR - pow(r, k + 1))) / (SCALE_FACTOR - r));
        int256 multiplier = m1 + ((m2 - m1) * (t - k * tn)) / tn;
        return multiplier;
    }

    function pow(int256 base, int256 exp) internal pure returns (int256) {
        int256 result = SCALE_FACTOR;
        for (uint256 i; i < uint256(exp); i++) {
            result = (result * base) / SCALE_FACTOR;
        }
        return result;
    }
}
