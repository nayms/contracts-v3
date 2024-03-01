# MarketFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/facets/MarketFacet.sol)

**Inherits:**
[Modifiers](/src/shared/Modifiers.sol/contract.Modifiers.md), [ReentrancyGuard](/src/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md)

Trade entity tokens

*This should only be called through an entity, never directly by an EOA*


## Functions
### cancelOffer

Cancel offer #`_offerId`. This will cancel the offer so that it's no longer active.

*This function can be frontrun: In the scenario where a user wants to cancel an unfavorable market offer, an attacker can potentially monitor and identify
that the user has called this method, determine that filling this market offer is profitable, and as a result call executeLimitOffer with a higher gas price to have
their transaction filled before the user can have cancelOffer filled. The most ideal situation for the user is to not have placed the unfavorable market offer
in the first place since an attacker can always monitor our marketplace and potentially identify profitable market offers. Our UI will aide users in not placing
market offers that are obviously unfavorable to the user and/or seem like mistake orders. In the event that a user needs to cancel an offer, it is recommended to
use Flashbots in order to privately send your transaction so an attack cannot be triggered from monitoring the mempool for calls to cancelOffer. A user is recommended
to change their RPC endpoint to point to https://rpc.flashbots.net when calling cancelOffer. We will add additional documentation to aide our users in this process.
More information on using Flashbots: https://docs.flashbots.net/flashbots-protect/rpc/quick-start/*


```solidity
function cancelOffer(uint256 _offerId)
    external
    notLocked(msg.sig)
    nonReentrant
    assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_CANCEL_OFFER);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_offerId`|`uint256`|offer ID|


### executeLimitOffer

Execute a limit offer.


```solidity
function executeLimitOffer(bytes32 _sellToken, uint256 _sellAmount, bytes32 _buyToken, uint256 _buyAmount)
    external
    notLocked(msg.sig)
    nonReentrant
    assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_EXECUTE_LIMIT_OFFER)
    returns (uint256 offerId_, uint256 buyTokenCommissionsPaid_, uint256 sellTokenCommissionsPaid_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_sellToken`|`bytes32`|Token to sell.|
|`_sellAmount`|`uint256`|Amount to sell.|
|`_buyToken`|`bytes32`|Token to buy.|
|`_buyAmount`|`uint256`|Amount to buy.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`offerId_`|`uint256`|returns >0 if a limit offer was created on the market because the offer couldn't be totally fulfilled immediately. In this case the return value is the created offer's id.|
|`buyTokenCommissionsPaid_`|`uint256`|The amount of the buy token paid as commissions on this particular order.|
|`sellTokenCommissionsPaid_`|`uint256`|The amount of the sell token paid as commissions on this particular order.|


### getLastOfferId

*Get last created offer.*


```solidity
function getLastOfferId() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|offer id.|


### getBestOfferId

Get current best offer for given token pair.

*This means finding the highest sellToken-per-buyToken price, i.e. price = sellToken / buyToken*


```solidity
function getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_sellToken`|`bytes32`|ID of the token being sold|
|`_buyToken`|`bytes32`|ID of the token being bought|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|offerId, or 0 if no offer exists for given pair|


### getOffer

*Get the details of the offer #`_offerId`*


```solidity
function getOffer(uint256 _offerId) external view returns (MarketInfo memory _offerState);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_offerId`|`uint256`|ID of a particular offer|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_offerState`|`MarketInfo`|details of the offer|


### isActiveOffer

*Check if the offer #`_offerId` is active or not.*


```solidity
function isActiveOffer(uint256 _offerId) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_offerId`|`uint256`|ID of a particular offer|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|active or not|


### calculateTradingFees

*Calculate the trading fees based on a buy amount.*


```solidity
function calculateTradingFees(bytes32 _buyerId, bytes32 _sellToken, bytes32 _buyToken, uint256 _buyAmount)
    external
    view
    returns (uint256 totalFees_, uint256 totalBP_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_buyerId`|`bytes32`|The account buying the asset.|
|`_sellToken`|`bytes32`|The asset being sold.|
|`_buyToken`|`bytes32`|The asset being bought.|
|`_buyAmount`|`uint256`|The amount that the fees payments are calculated from.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalFees_`|`uint256`|total fee to be paid|
|`totalBP_`|`uint256`|total basis points|


### getMakerBP

*Get the maker commission basis points.*


```solidity
function getMakerBP() external view returns (uint16);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint16`|maker fee BP|


### objectMinimumSell

Get the minimum amount of tokens that can be sold on the market.


```solidity
function objectMinimumSell(bytes32 _objectId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_objectId`|`bytes32`|ID of the object (Par token or external token)|


### setMinimumSell

Set the minimum amount of tokens that can be sold on the market.


```solidity
function setMinimumSell(bytes32 _objectId, uint256 _minimumSell)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_objectId`|`bytes32`|ID of the object (Par token or external token)|
|`_minimumSell`|`uint256`|The minimum amount of tokens that can be sold on the market.|


