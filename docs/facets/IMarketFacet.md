Trade entity tokens
This should only be called through an entity, never directly by an EOA
## Functions
### executeLimitOffer
```solidity
  function executeLimitOffer(
    bytes32 _sellToken,
    uint256 _sellAmount,
    bytes32 _buyToken,
    uint256 _buyAmount
  ) external returns (uint256 offerId_, uint256 buyTokenCommissionsPaid_, uint256 sellTokenCommissionsPaid_)
```
Execute a limit offer.
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_sellToken` | bytes32 | Token to sell.
|`_sellAmount` | uint256 | Amount to sell.
|`_buyToken` | bytes32 | Token to buy.
|`_buyAmount` | uint256 | Amount to buy.
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`offerId_`| bytes32 | returns >0 if a limit offer was created on the market because the offer couldn't be totally fulfilled immediately. In this case the return value is the created offer's id.
|`buyTokenCommissionsPaid_`| uint256 | The amount of the buy token paid as commissions on this particular order.
|`sellTokenCommissionsPaid_`| bytes32 | The amount of the sell token paid as commissions on this particular order.
### cancelOffer
```solidity
  function cancelOffer(
    uint256 _offerId
  ) external
```
Cancel offer #`_offerId`. This will cancel the offer so that it's no longer active.
This function can be frontrun: In the scenario where a user wants to cancel an unfavorable market offer, an attacker can potentially monitor and identify
      that the user has called this method, determine that filling this market offer is profitable, and as a result call executeLimitOffer with a higher gas price to have
      their transaction filled before the user can have cancelOffer filled. The most ideal situation for the user is to not have placed the unfavorable market offer
      in the first place since an attacker can always monitor our marketplace and potentially identify profitable market offers. Our UI will aide users in not placing
      market offers that are obviously unfavorable to the user and/or seem like mistake orders. In the event that a user needs to cancel an offer, it is recommended to
      use Flashbots in order to privately send your transaction so an attack cannot be triggered from monitoring the mempool for calls to cancelOffer. A user is recommended
      to change their RPC endpoint to point to https://rpc.flashbots.net when calling cancelOffer. We will add additional documentation to aide our users in this process.
      More information on using Flashbots: https://docs.flashbots.net/flashbots-protect/rpc/quick-start/
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_offerId` | uint256 | offer ID
### calculateFee
```solidity
  function calculateFee(
  ) external returns (address feeToken_, uint256 feeAmount_)
```
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
### isActiveOffer
```solidity
  function isActiveOffer(
    uint256 _offerId
  ) external returns (bool)
```
Check if the offer #`_offerId` is active or not.
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_offerId` | uint256 | ID of a particular offer
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`active`| uint256 | or not
### calculateTradingCommissions
```solidity
  function calculateTradingCommissions(
    uint256 buyAmount
  ) external returns (struct TradingCommissions tc)
```
Calculate the trading commissions based on a buy amount.
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`buyAmount` | uint256 | The amount that the commissions payments are calculated from.
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`tc`| uint256 | TradingCommissions struct todo
### getTradingCommissionsBasisPoints
```solidity
  function getTradingCommissionsBasisPoints(
  ) external returns (struct TradingCommissionsBasisPoints bp)
```
