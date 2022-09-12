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
    /**
     * @dev This function can be frontrun: In the scenario where a user wants to cancel an unfavorable market offer, an attacker can potentially monitor and identify
     *       that the user has called this method, determine that filling this market offer is profitable, and as a result call executeLimitOffer with a higher gas price to have
     *       their transaction filled before the user can have cancelOffer filled. The most ideal situation for the user is to not have placed the unfavorable market offer
     *       in the first place since an attacker can always monitor our marketplace and potentially identify profitable market offers. Our UI will aide users in not placing
     *       market offers that are obviously unfavorable to the user and/or seem like mistake orders. In the event that a user needs to cancel an offer, it is recommended to
     *       use Flashbots in order to privately send your transaction so an attack cannot be triggered from monitoring the mempool for calls to cancelOffer. A user is recommended
     *       to change their RPC endpoint to point to https://rpc.flashbots.net when calling cancelOffer. We will add additional documentation to aide our users in this process.
     *       More information on using Flashbots: https://docs.flashbots.net/flashbots-protect/rpc/quick-start/
     */
    function cancelOffer(uint256 _offerId) external nonReentrant {
        require(s.offers[_offerId].state == LibConstants.OFFER_STATE_ACTIVE, "offer not active");
        bytes32 creator = LibMarket._getOffer(_offerId).creator;
        require(LibObject._getParent(LibHelpers._getIdForAddress(msg.sender)) == creator, "only creator can cancel");
        LibMarket._cancelOffer(_offerId);
    }

    function executeLimitOffer(
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
        // Get the msg.sender's entityId. The parent is the entityId associated with the child, aka the msg.sender.
        // note: Only the entityId associated with the msg.sender can call executeLimitOffer().
        bytes32 parentId = LibObject._getParentFromAddress(msg.sender);

        return LibMarket._executeLimitOffer(parentId, _sellToken, _sellAmount, _buyToken, _buyAmount, _feeSchedule);
    }

    function getLastOfferId() external view returns (uint256) {
        return LibMarket._getLastOfferId();
    }

    function getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) external view returns (uint256) {
        return LibMarket._getBestOfferId(_sellToken, _buyToken);
    }

    function getOffer(uint256 _offerId) external view returns (MarketInfo memory _offerState) {
        return LibMarket._getOffer(_offerId);
    }
}
