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
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`offerId_` | returns >0 if a limit offer was created on the market because the offer couldn't be totally fulfilled immediately. In this case the return value is the created offer's id.
|`buyTokenCommissionsPaid_` | The amount of the buy token paid as commissions on this particular order.
|`sellTokenCommissionsPaid_` | The amount of the sell token paid as commissions on this particular order.|
<br></br>
### cancelOffer
Cancel offer #`_offerId`. This will cancel the offer so that it's no longer active.
This function can be frontrun: In the scenario where a user wants to cancel an unfavorable market offer, an attacker can potentially monitor and identify
      that the user has called this method, determine that filling this market offer is profitable, and as a result call executeLimitOffer with a higher gas price to have
      their transaction filled before the user can have cancelOffer filled. The most ideal situation for the user is to not have placed the unfavorable market offer
      in the first place since an attacker can always monitor our marketplace and potentially identify profitable market offers. Our UI will aide users in not placing
      market offers that are obviously unfavorable to the user and/or seem like mistake orders. In the event that a user needs to cancel an offer, it is recommended to
      use Flashbots in order to privately send your transaction so an attack cannot be triggered from monitoring the mempool for calls to cancelOffer. A user is recommended
      to change their RPC endpoint to point to https://rpc.flashbots.net when calling cancelOffer. We will add additional documentation to aide our users in this process.
      More information on using Flashbots: https://docs.flashbots.net/flashbots-protect/rpc/quick-start/
```solidity
  function cancelOffer(
    uint256 _offerId
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_offerId` | uint256 | offer ID|
<br></br>
### getBestOfferId
Get current best offer for given token pair.
This means finding the highest sellToken-per-buyToken price, i.e. price = sellToken / buyToken
```solidity
  function getBestOfferId(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`or` | 0 if no current best is available.|
<br></br>
### getLastOfferId
No description
Get last created offer.
```solidity
  function getLastOfferId(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`offer` | id.|
<br></br>
### getOffer
No description
Get the details of the offer #`_offerId`
```solidity
  function getOffer(
    uint256 _offerId
  ) external returns (struct MarketInfo _offerState)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_offerId` | uint256 | ID of a particular offer
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`_offerState` | details of the offer|
<br></br>
### isActiveOffer
No description
Check if the offer #`_offerId` is active or not.
```solidity
  function isActiveOffer(
    uint256 _offerId
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_offerId` | uint256 | ID of a particular offer
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`active` | or not|
<br></br>
### calculateTradingCommissions
No description
Calculate the trading commissions based on a buy amount.
```solidity
  function calculateTradingCommissions(
    uint256 buyAmount
  ) external returns (struct TradingCommissions tc)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`buyAmount` | uint256 | The amount that the commissions payments are calculated from.
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`tc` | TradingCommissions struct with metadata regarding the trade commission payment amounts.|
<br></br>
### getTradingCommissionsBasisPoints
Get the marketplace's trading commissions basis points.
```solidity
  function getTradingCommissionsBasisPoints(
  ) external returns (struct TradingCommissionsBasisPoints bp)
```
#### Returns:
| Type | Description |
| --- | --- |
|`bp` | - TradingCommissionsBasisPoints struct containing the individual basis points set for each marketplace commission receiver.|
<br></br>
