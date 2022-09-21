// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MarketInfo } from "./FreeStructs.sol";

interface IMarketFacet {
    function executeLimitOffer(
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    ) external returns (uint256);

    function cancelOffer(uint256 _offerId) external;

    function calculateFee(
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    ) external view returns (address feeToken_, uint256 feeAmount_);

    function getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) external view returns (uint256);

    function getLastOfferId() external view returns (uint256);

    function getOffer(uint256 _offerId) external view returns (MarketInfo memory _offerState);
}
