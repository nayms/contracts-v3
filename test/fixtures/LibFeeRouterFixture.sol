// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibFeeRouter, CalculatedFees, FeeAllocation, FeeReceiver } from "src/diamonds/nayms/libs/LibFeeRouter.sol";

/// Create a fixture to test the library LibFeeRouter

contract LibFeeRouterFixture {
    function helper_getFeeScheduleTotalBP(uint256 _feeScheduleId) public view returns (uint256 totalBP) {
        FeeReceiver[] memory feeReceivers = LibFeeRouter._getFeeSchedule(_feeScheduleId);

        uint256 feeReceiversCount = feeReceivers.length;
        for (uint256 i; i < feeReceiversCount; ++i) {
            totalBP += feeReceivers[i].basisPoints;
        }
    }

    function exposed_calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid) external view returns (CalculatedFees memory cf) {
        cf = LibFeeRouter._calculatePremiumFees(_policyId, _premiumPaid);
    }

    function exposed_payPremiumFees(bytes32 _policyId, uint256 _premiumPaid) external {
        LibFeeRouter._payPremiumFees(_policyId, _premiumPaid);
    }
}
