// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibConstants } from "src/diamonds/nayms/libs/LibConstants.sol";
import { LibFeeRouter, CalculatedFees, FeeAllocation, FeeSchedule } from "src/diamonds/nayms/libs/LibFeeRouter.sol";

/// Create a fixture to test the library LibFeeRouter

contract LibFeeRouterFixture {
    function exposed_calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid) external view returns (CalculatedFees memory cf) {
        cf = LibFeeRouter._calculatePremiumFees(_policyId, _premiumPaid);
    }

    function exposed_payPremiumFees(bytes32 _policyId, uint256 _premiumPaid) external {
        LibFeeRouter._payPremiumFees(_policyId, _premiumPaid);
    }

    function exposed_calculateTradingFees(
        bytes32 _buyerId,
        bytes32 _sellToken,
        bytes32 _buyToken,
        uint256 _buyAmount
    ) external view returns (uint256 totalFees_, uint256 totalBP_) {
        return LibFeeRouter._calculateTradingFees(_buyerId, _sellToken, _buyToken, _buyAmount);
    }

    function exposed_payTradingFees(
        bytes32 _buyer,
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _buyAmount
    ) external returns (uint256 totalFees_) {
        return LibFeeRouter._payTradingFees(LibConstants.FEE_TYPE_TRADING, _buyer, _makerId, _takerId, _tokenId, _buyAmount);
    }
}
