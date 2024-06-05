// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { StdStorage, stdStorage, StdStyle, Test, console as c } from "forge-std/Test.sol";
import { BoostCalculator as bc } from "./utils/BoostCalculator.sol";

contract TestBoostCalculator is Test {
    using StdStyle for *;

    uint256 a = 15e16;
    uint256 r = 85e16;
    uint256 intervalDuration = 30 days;
    int256 aInt = 15e16;
    int256 rInt = 85e16;
    int256 intervalDurationInt = 30 days;

    function testCalculateBoost() public {
        printBoost(40 days, 70 days);
        printBoost(40 days, 100 days);
        printBoost(60 days, 90 days);
        printBoost(50 days, 70 days);
    }

    function printBoost(int256 startTime, int256 currentTime) public view {
        c.log("   Start Time %s days", vm.toString(startTime / 1 days));
        c.log(" Current Time %s days", vm.toString(currentTime / 1 days));
        c.log("Next Reward M %s (divided by 1e14)\n", vm.toString(bc.calculateBoost(startTime, currentTime, aInt, rInt, intervalDurationInt) / 1e14));
    }
}
