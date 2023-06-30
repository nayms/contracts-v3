// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibFeeRouter, CalculatedFees, FeeAllocation, FeeSchedule } from "src/diamonds/nayms/libs/LibFeeRouter.sol";

/// Create a fixture to test the library LibFeeRouter

contract LibFeeRouterFixture {
    function exposed_calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid) external view returns (CalculatedFees memory cf) {
        cf = LibFeeRouter._calculatePremiumFees(_policyId, _premiumPaid);
    }

    function exposed_payPremiumFees(bytes32 _policyId, uint256 _premiumPaid) external {
        LibFeeRouter._payPremiumFees(_policyId, _premiumPaid);
    }
}
