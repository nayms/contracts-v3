Trade entity tokens
This should only be called through an entity, never directly by an EOA
## Functions
### executeLimitOffer
```solidity
  function executeLimitOffer(
    bytes32 _entityId,
    bytes32 _sellToken,
    uint256 _sellAmount,
    bytes32 _buyToken,
    uint256 _buyAmount,
    uint256 _feeSchedule
  ) external returns (uint256)
```
Execute a limit offer.
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_entityId` | bytes32 | User's entity ID.
|`_sellToken` | bytes32 | Token to sell.
|`_sellAmount` | uint256 | Amount to sell.
|`_buyToken` | bytes32 | Token to buy.
|`_buyAmount` | uint256 | Amount to buy.
|`_feeSchedule` | uint256 | Requested fee schedule, one of the `FEE_SCHEDULE_...` constants.
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`0`| bytes32 | if a limit offer was created on the market, because the offer couldn't be
totally fulfilled immediately. In this case the return value is the created offer's id.
### executeMarketOffer
```solidity
  function executeMarketOffer(
    bytes32 _sellToken,
    uint256 _sellAmount,
    bytes32 _buyToken
  ) external
```
Execute a market offer, ensuring the full amount gets sold.
This will revert if the full amount could not be sold.
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_sellToken` | bytes32 | token to sell.
|`_sellAmount` | uint256 | amount to sell.
|`_buyToken` | bytes32 | token to buy.
### cancelOffer
```solidity
  function cancelOffer(
    uint256 _offerId
  ) external
```
Cancel offer #`_offerId`.
This will revert the offer, so that it's no longer active.
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_offerId` | uint256 | offer ID
### calculateFee
```solidity
  function calculateFee(
    bytes32 _sellToken,
    uint256 _sellAmount,
    bytes32 _buyToken,
    uint256 _buyAmount,
    uint256 _feeSchedule
  ) external returns (address feeToken_, uint256 feeAmount_)
```
Calculate the fee that must be paid for placing the given order.
Assuming that the given order will be matched immediately to existing orders,
this method returns the fee the caller will have to pay as a taker.
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_sellToken` | bytes32 | The sell unit.
|`_sellAmount` | uint256 | The sell amount.
|`_buyToken` | bytes32 | The buy unit.
|`_buyAmount` | uint256 | The buy amount.
|`_feeSchedule` | uint256 | Fee schedule.
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`feeToken_`| bytes32 | The unit in which the fees are denominated.
|`feeAmount_`| uint256 | The fee required to place the order.
### simulateMarketOffer
```solidity
  function simulateMarketOffer(
    bytes32 _sellToken,
    uint256 _sellAmount,
    bytes32 _buyToken
  ) external returns (uint256)
```
Simulate a market offer and calculate the final amount bought.
This complements the `executeMarketOffer` method and is useful for when you want to display the average
trade price to the user prior to executing the transaction. Note that if the requested `_sellAmount` cannot
be sold then the function will throw.
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_sellToken` | bytes32 | The sell unit.
|`_sellAmount` | uint256 | The sell amount.
|`_buyToken` | bytes32 | The buy unit.
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`The`| bytes32 | amount that would get bought.
### getBestOfferId
```solidity
  function getBestOfferId(
  ) external returns (uint256)
```
Get current best offer for given token pair.
This means finding the highest sellToken-per-buyToken price, i.e. price = sellToken / buyToken
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`or`| bytes32 | 0 if no current best is available.
### getLastOfferId
```solidity
  function getLastOfferId(
  ) external returns (uint256)
```
Get last created offer.
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`offer`|  | id.
### getOffer
```solidity
  function getOffer(
    uint256 _offerId
  ) external returns (struct MarketInfo _offerState)
```
Get the details of the offer #`_offerId`
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_offerId` | uint256 | ID of a particular offer
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`_offerState`| uint256 | details of the offer
