// SPDX-License-Identifier: MIT

import { LibFeeRouter } from "src/diamonds/nayms/libs/LibFeeRouter.sol";

/// Create a fixture to test the library LibFeeRouter

contract LibFeeRouterFixture {
    function payPremiumComissions(bytes32 _policyId, uint256 _premiumPaid) public {
        LibFeeRouter._payPremiumComissions(_policyId, _premiumPaid);
    }

    function payTradingComissions(
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _requestedBuyAmount
    ) public returns (uint256 commissionPaid_) {
        commissionPaid_ = LibFeeRouter._payTradingComissions(_makerId, _takerId, _tokenId, _requestedBuyAmount);
    }
}
