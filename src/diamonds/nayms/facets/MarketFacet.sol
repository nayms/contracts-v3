// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MarketInfo, Modifiers } from "../AppStorage.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibMarket } from "../libs/LibMarket.sol";
import { LibObject } from "../libs/LibObject.sol";

import { ReentrancyGuard } from "../../../utils/ReentrancyGuard.sol";

/**
 * inspired by https://github.com/nayms/maker-otc/blob/master/contracts/matching_market.sol
 */
contract MarketFacet is Modifiers, ReentrancyGuard {
    function cancelOffer(uint256 _offerId) external nonReentrant {
        require(s.offers[_offerId].state == LibConstants.OFFER_STATE_ACTIVE, "offer not active");
        bytes32 creator = LibMarket._getOffer(_offerId).creator;
        require(LibHelpers._getAddressFromId(LibObject._getParent(creator)) == msg.sender, "only creator can cancel");
        LibMarket._cancelOffer(_offerId);
    }

    function executeLimitOffer(
        bytes32 _from,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    )
        external
        nonReentrant
        returns (
            uint256 offerId_,
            uint256 buyTokenComissionsPaid_,
            uint256 sellTokenComissionsPaid_
        )
    {
        return LibMarket._executeLimitOffer(_from, _sellToken, _sellAmount, _buyToken, _buyAmount, _feeSchedule);
    }

    function executeMarketOffer(
        bytes32 _from,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _feeSchedule
    )
        external
        nonReentrant
        returns (
            uint256 offerId_,
            uint256 buyTokenComissionsPaid_,
            uint256 sellTokenComissionsPaid_
        )
    {
        return LibMarket._executeLimitOffer(_from, _sellToken, _sellAmount, _buyToken, 0, _feeSchedule);
    }

    function getLastOfferId() external view returns (uint256) {
        return LibMarket._getLastOfferId();
    }

    function getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) external view returns (uint256) {
        return LibMarket._getBestOfferId(_sellToken, _buyToken);
    }

    function simulateMarketOffer(
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken
    ) external view returns (uint256) {
        return LibMarket._simulateMarketOffer(_sellToken, _sellAmount, _buyToken);
    }

    function getOffer(uint256 _offerId) external view returns (MarketInfo memory _offerState) {
        return LibMarket._getOffer(_offerId);
    }
}
