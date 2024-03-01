# LibMarket
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/libs/LibMarket.sol)


## Functions
### _getBestOfferId


```solidity
function _getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) internal view returns (uint256);
```

### _insertOfferIntoSortedList


```solidity
function _insertOfferIntoSortedList(uint256 _offerId) internal;
```

### _removeOfferFromSortedList


```solidity
function _removeOfferFromSortedList(uint256 _offerId) internal;
```

### _isOfferPricedLtOrEq

*If the relative price of the sell token for offer1 ("low offer") is more expensive than the relative price of of the sell token for offer2 ("high offer"), then this returns true.
If the sell token for offer1 is "more expensive", this means that one will need more sell token to buy the same amount of buy token when comparing relative prices of offer1 to offer2.*


```solidity
function _isOfferPricedLtOrEq(uint256 _lowOfferId, uint256 _highOfferId) internal view returns (bool);
```

### _isOfferInSortedList


```solidity
function _isOfferInSortedList(uint256 _offerId) internal view returns (bool);
```

### _matchToExistingOffers


```solidity
function _matchToExistingOffers(
    uint256 _offerId,
    bytes32 _takerId,
    bytes32 _sellToken,
    uint256 _sellAmount,
    bytes32 _buyToken,
    uint256 _buyAmount,
    uint256 _feeScheduleType
) internal returns (MatchingOfferResult memory result);
```

### _createOffer


```solidity
function _createOffer(
    uint256 _offerId,
    bytes32 _creator,
    bytes32 _sellToken,
    uint256 _sellAmount,
    uint256 _sellAmountInitial,
    bytes32 _buyToken,
    uint256 _buyAmount,
    uint256 _buyAmountInitial,
    uint256 _feeScheduleType
) internal;
```

### _takeOffer


```solidity
function _takeOffer(
    uint256 _feeScheduleType,
    uint256 _offerId,
    bytes32 _takerId,
    uint256 _buyAmount,
    uint256 _sellAmount,
    bool _takeExternalToken
) internal returns (uint256 commissionsPaid_);
```

### _checkBoundsAndUpdateBalances

Check to see if the fee schedule from the new order (`startTokenSale()`) is the initial offer fee schedule or not
Use the initial offer fee schedule if it is, otherwise use the fee schedule from the original order placed


```solidity
function _checkBoundsAndUpdateBalances(uint256 _offerId, uint256 _sellAmount, uint256 _buyAmount) internal;
```

### _cancelOffer


```solidity
function _cancelOffer(uint256 _offerId) internal;
```

### _validateAmounts

*Burn the par tokens if this was an initial token sale (selling par tokens through startTokenSale())*


```solidity
function _validateAmounts(uint256 _sellAmount, uint256 _buyAmount) internal pure;
```

### _validateOffer


```solidity
function _validateOffer(
    bytes32 _entityId,
    bytes32 _sellToken,
    uint256 _sellAmount,
    bytes32 _buyToken,
    uint256 _buyAmount,
    uint256 _feeScheduleType
) internal view;
```

### _getOfferTokenAmounts


```solidity
function _getOfferTokenAmounts(uint256 _offerId)
    internal
    view
    returns (TokenAmount memory sell_, TokenAmount memory buy_);
```

### _executeLimitOffer


```solidity
function _executeLimitOffer(
    bytes32 _creator,
    bytes32 _sellToken,
    uint256 _sellAmount,
    bytes32 _buyToken,
    uint256 _buyAmount,
    uint256 _feeScheduleType
) internal returns (uint256 offerId_, uint256 buyTokenCommissionsPaid_, uint256 sellTokenCommissionsPaid_);
```

### _getOffer


```solidity
function _getOffer(uint256 _offerId) internal view returns (MarketInfo memory _offerState);
```

### _getLastOfferId


```solidity
function _getLastOfferId() internal view returns (uint256);
```

### _isActiveOffer


```solidity
function _isActiveOffer(uint256 _offerId) internal view returns (bool);
```

### _objectMinimumSell


```solidity
function _objectMinimumSell(bytes32 _objectId) internal view returns (uint256);
```

### _setMinimumSell


```solidity
function _setMinimumSell(bytes32 _objectId, uint256 _minimumSell) internal;
```

## Events
### OrderAdded
order has been added


```solidity
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
```

### OrderExecuted
order has been executed


```solidity
event OrderExecuted(
    uint256 indexed orderId,
    bytes32 indexed taker,
    bytes32 indexed sellToken,
    uint256 sellAmount,
    bytes32 buyToken,
    uint256 buyAmount,
    uint256 state
);
```

### OrderMatched
order has been matched
new event has been added not to change the existing ones, for preserving the backward compatibility


```solidity
event OrderMatched(uint256 indexed orderId, uint256 matchedWithId, uint256 sellAmountMatched, uint256 buyAmountMatched);
```

### OrderCancelled
order has been cancelled


```solidity
event OrderCancelled(uint256 indexed orderId, bytes32 indexed taker, bytes32 sellToken);
```

### MinimumSellUpdated
The minimum amount of an object (par token, external token) that can be sold on the market


```solidity
event MinimumSellUpdated(bytes32 objectId, uint256 minimumSell);
```

## Structs
### MatchingOfferResult

```solidity
struct MatchingOfferResult {
    uint256 remainingBuyAmount;
    uint256 remainingSellAmount;
    uint256 buyTokenCommissionsPaid;
    uint256 sellTokenCommissionsPaid;
}
```

