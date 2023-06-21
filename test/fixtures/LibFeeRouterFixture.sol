// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibFeeRouter, CalculatedFees, FeeAllocation, FeeReceiver } from "src/diamonds/nayms/libs/LibFeeRouter.sol";

/// Create a fixture to test the library LibFeeRouter

contract LibFeeRouterFixture {
    function helper_getMakerBP() public view returns (uint16 makerBP) {
        makerBP = LibFeeRouter._getMakerBP();
    }

    function helper_getFeeScheduleTotalBP(uint256 _feeScheduleId) public view returns (uint256 totalBP) {
        FeeReceiver[] memory feeReceivers = LibFeeRouter._getFeeSchedule(_feeScheduleId);

        uint256 feeReceiversCount = feeReceivers.length;
        for (uint i; i < feeReceiversCount; ++i) {
            totalBP += feeReceivers[i].basisPoints;
        }
    }
}
