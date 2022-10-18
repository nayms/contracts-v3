// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { MarketInfo, TokenAmount, TradingCommissions } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibFeeRouter } from "./LibFeeRouter.sol";

library LibMarket {
    /// @notice order has been added
    event OrderAdded(
        uint256 indexed orderId,
        bytes32 indexed maker,
        bytes32 indexed sellToken,
        uint256 sellAmount,
        uint256 sellAmountInitial,
        bytes32 buyToken,
        uint256 buyAmount,
        uint256 buyAmountInitial,
        uint256 state
    );

    /// @notice order has been executed
    event OrderExecuted(uint256 indexed orderId, bytes32 indexed taker, bytes32 indexed sellToken, uint256 sellAmount, bytes32 buyToken, uint256 buyAmount, uint256 state);

    /// @notice order has been canceled
    event OrderCancelled(uint256 indexed orderId, bytes32 indexed taker, bytes32 sellToken);

    struct MatchingOfferResult {
        uint256 remainingBuyAmount;
        uint256 remainingSellAmount;
        uint256 buyTokenCommissionsPaid;
        uint256 sellTokenCommissionsPaid;
    }

    function _getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return s.bestOfferId[_sellToken][_buyToken];
    }

    function _insertOfferIntoSortedList(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check that offer is NOT in the sorted list
        require(!_isOfferInSortedList(_offerId), "offer already in sorted list");

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        uint256 prevId;

        // find position of next highest offer
        uint256 top = s.bestOfferId[sellToken][buyToken];
        uint256 oldTop;

        while (top != 0 && _isOfferPricedLtOrEq(_offerId, top)) {
            oldTop = top;
            top = s.offers[top].rankPrev;
        }

        uint256 pos = oldTop;

        // insert offer at position
        if (pos != 0) {
            prevId = s.offers[pos].rankPrev;
            s.offers[pos].rankPrev = _offerId;
            s.offers[_offerId].rankNext = pos;
        }
        // else this is the new best offer, so insert at top
        else {
            prevId = s.bestOfferId[sellToken][buyToken];
            s.bestOfferId[sellToken][buyToken] = _offerId;
        }

        if (prevId != 0) {
            // requirement below is satisfied by statements above
            // require(!_isOfferPricedLtOrEq(_offerId, prevId));
            s.offers[prevId].rankNext = _offerId;
            s.offers[_offerId].rankPrev = prevId;
        }

        s.span[sellToken][buyToken]++;
    }

    function _removeOfferFromSortedList(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check that offer is in the sorted list
        require(_isOfferInSortedList(_offerId), "offer not in sorted list");

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        require(s.span[sellToken][buyToken] > 0, "token pair list does not exist");

        // if offer is not the highest offer
        if (_offerId != s.bestOfferId[sellToken][buyToken]) {
            uint256 nextId = s.offers[_offerId].rankNext;
            require(s.offers[nextId].rankPrev == _offerId, "sort check failed");
            s.offers[nextId].rankPrev = s.offers[_offerId].rankPrev;
        }
        // if offer is the highest offer
        else {
            s.bestOfferId[sellToken][buyToken] = s.offers[_offerId].rankPrev;
        }

        // if offer is not the lowest offer
        if (s.offers[_offerId].rankPrev != 0) {
            uint256 prevId = s.offers[_offerId].rankPrev;
            require(s.offers[prevId].rankNext == _offerId, "sort check failed");
            s.offers[prevId].rankNext = s.offers[_offerId].rankNext;
        }

        // nullify
        delete s.offers[_offerId].rankNext;
        delete s.offers[_offerId].rankPrev;

        s.span[sellToken][buyToken]--;
    }

    function _isOfferPricedLtOrEq(uint256 _lowOfferId, uint256 _highOfferId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lowSellAmount = s.offers[_lowOfferId].sellAmount;
        uint256 lowBuyAmount = s.offers[_lowOfferId].buyAmount;

        uint256 highSellAmount = s.offers[_highOfferId].sellAmount;
        uint256 highBuyAmount = s.offers[_highOfferId].buyAmount;

        return lowBuyAmount * highSellAmount >= highBuyAmount * lowSellAmount;
    }

    function _isOfferInSortedList(uint256 _offerId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        return _offerId != 0 && (s.offers[_offerId].rankNext != 0 || s.offers[_offerId].rankPrev != 0 || s.bestOfferId[sellToken][buyToken] == _offerId);
    }

    function _matchToExistingOffers(
        bytes32 _takerId,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount
    ) internal returns (MatchingOfferResult memory result) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        result.remainingBuyAmount = _buyAmount;
        result.remainingSellAmount = _sellAmount;

        // sell: p100 buy: $100 => YES! buy more
        // sell: $100 buy: p100 =>  NO! DON'T buy more

        // If the buyToken is entity   => limit both buy and sell amounts
        // If the buyToken is external => limit only sell amount

        bool buyExternalToken = s.externalTokenSupported[LibHelpers._getAddressFromId(_buyToken)];
        while (result.remainingSellAmount != 0 && (buyExternalToken || result.remainingBuyAmount != 0)) {
            // there is at least one offer stored for token pair
            uint256 bestOfferId = s.bestOfferId[_buyToken][_sellToken];
            if (bestOfferId == 0) {
                break; // no market liquidity, bail out
            }

            uint256 makerBuyAmount = s.offers[bestOfferId].buyAmount;
            uint256 makerSellAmount = s.offers[bestOfferId].sellAmount;

            // Check if best available price in the market is better or same as the one taker is willing to pay, within error margin.
            // Ugly hack to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has `sellAmount` and `makerSellAmount` at +1 away from
            // their "correct" values and `makerBuyAmount` and `buyAmount` at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d
            // (For detailed breakdown see https://hiddentao.com/archives/2019/09/08/maker-otc-on-chain-orderbook-deep-dive)
            // having:
            // a => result.remainingSellAmount
            // b => makerSellAmount
            // c => makerBuyAmount
            // d => result.remainingBuyAmount

            if (
                makerBuyAmount * result.remainingBuyAmount >
                result.remainingSellAmount * makerSellAmount + result.remainingSellAmount + makerSellAmount + makerBuyAmount + result.remainingBuyAmount
            ) {
                break; // no matching price, bail out
            }

            // ^ The `rounding` parameter is a compromise borne of a couple days of discussion.

            // avoid stack-too-deep
            {
                // do the buy
                uint256 nextBuyTokenCommissionsPaid;
                uint256 nextSellTokenCommissionsPaid;

                if (buyExternalToken) {
                    uint256 finalSellAmount = makerBuyAmount < result.remainingSellAmount ? makerBuyAmount : result.remainingSellAmount;
                    nextSellTokenCommissionsPaid = _sell(bestOfferId, _takerId, finalSellAmount);

                    // calculate how much is left to buy/sell
                    uint256 sellAmountOld = result.remainingSellAmount;
                    result.remainingSellAmount -= finalSellAmount;
                    result.remainingBuyAmount = (result.remainingSellAmount * result.remainingBuyAmount) / sellAmountOld;
                } else {
                    uint256 finalBuyAmount = makerSellAmount < result.remainingBuyAmount ? makerSellAmount : result.remainingBuyAmount;
                    nextBuyTokenCommissionsPaid = _buy(bestOfferId, _takerId, finalBuyAmount);

                    // calculate how much is left to buy/sell
                    uint256 buyAmountOld = result.remainingBuyAmount;
                    result.remainingBuyAmount -= finalBuyAmount;
                    result.remainingSellAmount = (result.remainingBuyAmount * result.remainingSellAmount) / buyAmountOld;
                }

                // Keep track of total commissions
                result.buyTokenCommissionsPaid += nextBuyTokenCommissionsPaid;
                result.sellTokenCommissionsPaid += nextSellTokenCommissionsPaid;
            }
        }
    }

    function _createOffer(
        bytes32 _creator,
        bytes32 _sellToken,
        uint256 _sellAmount,
        uint256 _sellAmountInitial,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _buyAmountInitial,
        uint256 _feeSchedule
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lastOfferId = ++s.lastOfferId;

        MarketInfo memory marketInfo = s.offers[lastOfferId];
        marketInfo.creator = _creator;
        marketInfo.sellToken = _sellToken;
        marketInfo.sellAmount = _sellAmount;
        marketInfo.sellAmountInitial = _sellAmountInitial;
        marketInfo.buyToken = _buyToken;
        marketInfo.buyAmount = _buyAmount;
        marketInfo.buyAmountInitial = _buyAmountInitial;
        marketInfo.feeSchedule = _feeSchedule;

        if (_sellAmount <= LibConstants.DUST) {
            marketInfo.state = LibConstants.OFFER_STATE_FULFILLED;
        } else {
            marketInfo.state = LibConstants.OFFER_STATE_ACTIVE;

            // lock tokens!
            s.marketLockedBalances[_creator][_sellToken] += _sellAmount;
        }

        s.offers[lastOfferId] = marketInfo;
        emit OrderAdded(lastOfferId, marketInfo.creator, _sellToken, _sellAmount, _sellAmountInitial, _buyToken, _buyAmount, _buyAmountInitial, marketInfo.state);

        return lastOfferId;
    }

    function _sell(
        uint256 _offerId,
        bytes32 _takerId,
        uint256 _sellAmount
    ) internal returns (uint256 sellTokenCommissionsPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // (a / b) * c = c * a / b  -> multiply first, to avoid underflow
        uint256 actualBuyAmount = (_sellAmount * s.offers[_offerId].sellAmount) / s.offers[_offerId].buyAmount;

        // check bounds and update balances
        _checkBoundsAndUpdateBalances(_offerId, actualBuyAmount, _sellAmount);

        // Check fee schedule, before paying commissions
        if (s.offers[_offerId].feeSchedule == LibConstants.FEE_SCHEDULE_STANDARD) {
            // Fees are paid by the taker, maker pays no fees, only in external token
            // If the _buyToken is external, commissions are paid from _buyAmount in _buyToken.
            // If the _buyToken is internal and the _sellToken is external, commissions are paid from _sellAmount in _sellToken.

            // buyToken is always internal here, commissions are paid from _sellAmount in _sellToken
            sellTokenCommissionsPaid_ = LibFeeRouter._payTradingCommissions(s.offers[_offerId].creator, _takerId, s.offers[_offerId].sellToken, actualBuyAmount);
        }

        s.marketLockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= actualBuyAmount;

        LibTokenizedVault._internalTransfer(s.offers[_offerId].creator, _takerId, s.offers[_offerId].sellToken, actualBuyAmount);
        LibTokenizedVault._internalTransfer(_takerId, s.offers[_offerId].creator, s.offers[_offerId].buyToken, _sellAmount);

        // close offer, it's filled
        if (s.offers[_offerId].sellAmount < LibConstants.DUST) {
            s.offers[_offerId].state = LibConstants.OFFER_STATE_FULFILLED;
            _cancelOffer(_offerId);
        }

        emit OrderExecuted(
            _offerId,
            _takerId,
            s.offers[_offerId].sellToken,
            s.offers[_offerId].sellAmount,
            s.offers[_offerId].buyToken,
            s.offers[_offerId].buyAmount,
            s.offers[_offerId].state
        );
    }

    function _buy(
        uint256 _offerId,
        bytes32 _takerId,
        uint256 _buyAmount
    ) internal returns (uint256 buyTokenCommissionsPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // (a / b) * c = c * a / b  -> multiply first, to avoid underflow
        uint256 actualSellAmount = (_buyAmount * s.offers[_offerId].buyAmount) / s.offers[_offerId].sellAmount;

        // check bounds and update balances
        _checkBoundsAndUpdateBalances(_offerId, _buyAmount, actualSellAmount);

        // Check fee schedule, before paying commissions
        if (s.offers[_offerId].feeSchedule == LibConstants.FEE_SCHEDULE_STANDARD) {
            // Fees are paid by the taker, maker pays no fees, only in external token
            // If the _buyToken is external, commissions are paid from _buyAmount in _buyToken.
            // If the _buyToken is internal and the _sellToken is external, commissions are paid from _sellAmount in _sellToken.

            // buyToken is always external here, commissions are paid from _buyAmount in _buyToken
            buyTokenCommissionsPaid_ = LibFeeRouter._payTradingCommissions(s.offers[_offerId].creator, _takerId, s.offers[_offerId].buyToken, actualSellAmount);
        }

        s.marketLockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= _buyAmount;

        LibTokenizedVault._internalTransfer(s.offers[_offerId].creator, _takerId, s.offers[_offerId].sellToken, _buyAmount);
        LibTokenizedVault._internalTransfer(_takerId, s.offers[_offerId].creator, s.offers[_offerId].buyToken, actualSellAmount);

        // close offer if it has become dust
        if (s.offers[_offerId].sellAmount < LibConstants.DUST) {
            s.offers[_offerId].state = LibConstants.OFFER_STATE_FULFILLED;
            _cancelOffer(_offerId);
        }

        emit OrderExecuted(
            _offerId,
            _takerId,
            s.offers[_offerId].sellToken,
            s.offers[_offerId].sellAmount,
            s.offers[_offerId].buyToken,
            s.offers[_offerId].buyAmount,
            s.offers[_offerId].state
        );
    }

    function _checkBoundsAndUpdateBalances(
        uint256 _offerId,
        uint256 _sellAmount,
        uint256 _buyAmount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        (TokenAmount memory offerSell, TokenAmount memory offerBuy) = _getOfferTokenAmounts(_offerId);

        _assertAmounts(_sellAmount, _buyAmount);
        require(_buyAmount <= offerBuy.amount, "requested buy amount too large");
        require(_sellAmount <= offerSell.amount, "calculated sell amount too large");

        // update balances
        s.offers[_offerId].sellAmount = offerSell.amount - _sellAmount;
        s.offers[_offerId].buyAmount = offerBuy.amount - _buyAmount;
    }

    function _cancelOffer(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (_isOfferInSortedList(_offerId)) {
            _removeOfferFromSortedList(_offerId);
        }

        MarketInfo memory marketInfo = s.offers[_offerId];

        // unlock the remaining sell amount back to creator
        if (marketInfo.sellAmount > 0) {
            // note nothing is transferred since tokens for sale are UN-escrowed. Just unlock!
            s.marketLockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= marketInfo.sellAmount;
        }

        // don't emit event stating market order is canceled if the market order was executed and fulfilled
        if (marketInfo.state != LibConstants.OFFER_STATE_FULFILLED) {
            s.offers[_offerId].state = LibConstants.OFFER_STATE_CANCELLED;
            emit OrderCancelled(_offerId, marketInfo.creator, marketInfo.sellToken);
        }
    }

    function _assertAmounts(uint256 _sellAmount, uint256 _buyAmount) internal pure {
        require(uint128(_sellAmount) == _sellAmount, "sell amount exceeds uint128 limit");
        require(uint128(_buyAmount) == _buyAmount, "buy amount exceeds uint128 limit");
        require(_sellAmount > 0, "sell amount must be >0");
        require(_buyAmount > 0, "buy amount must be >0");
    }

    function _assertValidOffer(
        bytes32 _entityId,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    ) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_entityId != 0 && s.existingEntities[_entityId], "must belong to entity to make an offer");

        bool sellTokenIsEntity = s.existingEntities[_sellToken];
        bool sellTokenIsSupported = s.externalTokenSupported[LibHelpers._getAddressFromId(_sellToken)];
        bool buyTokenIsEntity = s.existingEntities[_buyToken];
        bool buyTokenIsSupported = s.externalTokenSupported[LibHelpers._getAddressFromId(_buyToken)];

        _assertAmounts(_sellAmount, _buyAmount);

        require(sellTokenIsEntity || sellTokenIsSupported, "sell token must be valid");
        require(buyTokenIsEntity || buyTokenIsSupported, "buy token must be valid");
        require(_sellToken != _buyToken, "cannot sell and buy same token");
        require((sellTokenIsEntity && buyTokenIsSupported) || (sellTokenIsSupported && buyTokenIsEntity), "must be one platform token");

        // note: add restriction to not be able to sell tokens that are already for sale
        // maker must own sell amount and it must not be locked
        require(s.tokenBalances[_sellToken][_entityId] - s.marketLockedBalances[_entityId][_sellToken] >= _sellAmount, "tokens locked in market");

        // must have a valid fee schedule
        require(_feeSchedule == LibConstants.FEE_SCHEDULE_PLATFORM_ACTION || _feeSchedule == LibConstants.FEE_SCHEDULE_STANDARD, "fee schedule invalid");
    }

    function _getOfferTokenAmounts(uint256 _offerId) internal view returns (TokenAmount memory sell_, TokenAmount memory buy_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        sell_.token = s.offers[_offerId].sellToken;
        sell_.amount = s.offers[_offerId].sellAmount;
        buy_.token = s.offers[_offerId].buyToken;
        buy_.amount = s.offers[_offerId].buyAmount;
    }

    function _executeLimitOffer(
        bytes32 _creator,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    )
        internal
        returns (
            uint256 offerId_,
            uint256 buyTokenCommissionsPaid_,
            uint256 sellTokenCommissionsPaid_
        )
    {
        _assertValidOffer(_creator, _sellToken, _sellAmount, _buyToken, _buyAmount, _feeSchedule);

        MatchingOfferResult memory result = _matchToExistingOffers(_creator, _sellToken, _sellAmount, _buyToken, _buyAmount);
        buyTokenCommissionsPaid_ = result.buyTokenCommissionsPaid;
        sellTokenCommissionsPaid_ = result.sellTokenCommissionsPaid;

        offerId_ = _createOffer(_creator, _sellToken, result.remainingSellAmount, _sellAmount, _buyToken, result.remainingBuyAmount, _buyAmount, _feeSchedule);

        // if still some left
        if (result.remainingBuyAmount > 0 && result.remainingSellAmount > 0 && result.remainingSellAmount >= LibConstants.DUST) {
            // ensure it's in the right position in the list
            _insertOfferIntoSortedList(offerId_);
        }
    }

    function _getOffer(uint256 _offerId) internal view returns (MarketInfo memory _offerState) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.offers[_offerId];
    }

    function _getLastOfferId() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.lastOfferId;
    }

    function _isActiveOffer(uint256 _offerId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.offers[_offerId].state == LibConstants.OFFER_STATE_ACTIVE;
    }

    function _getBalanceOfTokensForSale(bytes32 _entityId, bytes32 _tokenId) internal view returns (uint256 amount) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.marketLockedBalances[_entityId][_tokenId];
    }
}
