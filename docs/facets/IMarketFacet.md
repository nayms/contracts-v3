Trade entity tokens
## Functions
### executeLimitOffer
Execute a limit offer.
```solidity
  function executeLimitOffer(
    bytes32 _sellToken,
    uint256 _sellAmount,
    bytes32 _buyToken,
    uint256 _buyAmount
  ) external returns (uint256 offerId_, uint256 buyTokenCommissionsPaid_, uint256 sellTokenCommissionsPaid_)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_sellToken` | bytes32 | Token to sell.
|`_sellAmount` | uint256 | Amount to sell.
|`_buyToken` | bytes32 | Token to buy.
|`_buyAmount` | uint256 | Amount to buy.
#### Returns:
| Type | Description |
| --- | --- |
|`offerId_` | returns >0 if a limit offer was created on the market because the offer couldn't be totally fulfilled immediately. In this case the return value is the created offer's id.
|`buyTokenCommissionsPaid_` | The amount of the buy token paid as commissions on this particular order.
|`sellTokenCommissionsPaid_` | The amount of the sell token paid as commissions on this particular order.
### cancelOffer
Cancel offer #`_offerId`. This will cancel the offer so that it's no longer active.
```solidity
  function cancelOffer(
    uint256 _offerId
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_offerId` | uint256 | offer ID
### calculateFee
No description
```solidity
  function calculateFee(
  ) external returns (address feeToken_, uint256 feeAmount_)
```
### getBestOfferId
Get current best offer for given token pair.
```solidity
  function getBestOfferId(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`or` | 0 if no current best is available.
### getLastOfferId
No description
```solidity
  function getLastOfferId(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`offer` | id.
### getOffer
No description
```solidity
  function getOffer(
    uint256 _offerId
  ) external returns (struct MarketInfo _offerState)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_offerId` | uint256 | ID of a particular offer
#### Returns:
| Type | Description |
| --- | --- |
|`_offerState` | details of the offer
### isActiveOffer
No description
```solidity
  function isActiveOffer(
    uint256 _offerId
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_offerId` | uint256 | ID of a particular offer
#### Returns:
| Type | Description |
| --- | --- |
|`active` | or not
### calculateTradingCommissions
No description
```solidity
  function calculateTradingCommissions(
    uint256 buyAmount
  ) external returns (struct TradingCommissions tc)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`buyAmount` | uint256 | The amount that the commissions payments are calculated from.
#### Returns:
| Type | Description |
| --- | --- |
|`tc` | TradingCommissions struct todo
### getTradingCommissionsBasisPoints
No description
```solidity
  function getTradingCommissionsBasisPoints(
  ) external returns (struct TradingCommissionsBasisPoints bp)
```
