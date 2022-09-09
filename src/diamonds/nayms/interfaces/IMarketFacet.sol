// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MarketInfo } from "./FreeStructs.sol";

/**
 * @title Matching Market (inspired by MakerOTC)
 * @notice Trade entity tokens
 * @dev This should only be called through an entity, never directly by an EOA
 */
interface IMarketFacet {
    /**
     * @notice Execute a limit offer.
     *
     * @param _sellToken Token to sell.
     * @param _sellAmount Amount to sell.
     * @param _buyToken Token to buy.
     * @param _buyAmount Amount to buy.
     * @param _feeSchedule Requested fee schedule, one of the `FEE_SCHEDULE_...` constants.
     *
     * @return >0 if a limit offer was created on the market, because the offer couldn't be
     * totally fulfilled immediately. In this case the return value is the created offer's id.
     */
    function executeLimitOffer(
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    ) external returns (uint256);

    /**
     * @notice Cancel offer #`_offerId`.
     * @dev This will revert the offer, so that it's no longer active.
     * @param _offerId offer ID
     */
    function cancelOffer(uint256 _offerId) external;

    /**
     * @notice Calculate the fee that must be paid for placing the given order.
     *
     * @dev Assuming that the given order will be matched immediately to existing orders,
     * this method returns the fee the caller will have to pay as a taker.
     *
     * @param _sellToken The sell unit.
     * @param _sellAmount The sell amount.
     * @param _buyToken The buy unit.
     * @param _buyAmount The buy amount.
     * @param _feeSchedule Fee schedule.
     *
     * @return feeToken_ The unit in which the fees are denominated.
     * @return feeAmount_ The fee required to place the order.
     */
    function calculateFee(
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    ) external view returns (address feeToken_, uint256 feeAmount_);

    /**
     * @notice Get current best offer for given token pair.
     *
     * @dev This means finding the highest sellToken-per-buyToken price, i.e. price = sellToken / buyToken
     *
     * @return offerId, or 0 if no current best is available.
     */
    function getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) external view returns (uint256);

    /**
     * @dev Get last created offer.
     *
     * @return offer id.
     */
    function getLastOfferId() external view returns (uint256);

    /**
     * @dev Get the details of the offer #`_offerId`
     * @param _offerId ID of a particular offer
     * @return _offerState details of the offer
     */
    function getOffer(uint256 _offerId) external view returns (MarketInfo memory _offerState);
}
