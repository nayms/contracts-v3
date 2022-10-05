// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibFeeRouter } from "src/diamonds/nayms/libs/LibFeeRouter.sol";

/// Create a fixture to test the library LibFeeRouter

contract LibFeeRouterFixture {
    function payPremiumCommissions(bytes32 _policyId, uint256 _premiumPaid) public {
        LibFeeRouter._payPremiumCommissions(_policyId, _premiumPaid);
    }

    function payTradingCommissions(
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _requestedBuyAmount
    ) public returns (uint256 commissionPaid_) {
        commissionPaid_ = LibFeeRouter._payTradingCommissions(_makerId, _takerId, _tokenId, _requestedBuyAmount);
    }
}
