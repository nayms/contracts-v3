# TokenizedVaultFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/facets/TokenizedVaultFacet.sol)

**Inherits:**
[Modifiers](/src/shared/Modifiers.sol/contract.Modifiers.md), [ReentrancyGuard](/src/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md)

Vault for keeping track of platform tokens

*Used for internal platform token transfers*

*Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155*


## Functions
### internalBalanceOf

Gets balance of an account within platform

*Internal balance for given account*


```solidity
function internalBalanceOf(bytes32 ownerId, bytes32 tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ownerId`|`bytes32`|Internal ID of the account|
|`tokenId`|`bytes32`|Internal ID of the asset|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|current balance|


### internalTokenSupply

Current supply for the asset

*Total supply of platform asset*


```solidity
function internalTokenSupply(bytes32 tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`bytes32`|Internal ID of the asset|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|total supply|


### internalTransferFromEntity

Internal transfer of `amount` tokens from the entity associated with the sender

*Transfer tokens internally*


```solidity
function internalTransferFromEntity(bytes32 to, bytes32 tokenId, uint256 amount)
    external
    notLocked(msg.sig)
    nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`bytes32`|token receiver|
|`tokenId`|`bytes32`|Internal ID of the token|
|`amount`|`uint256`|being transferred|


### wrapperInternalTransferFrom

Internal transfer of `amount` tokens `from` -> `to`

*Transfer tokens internally between two IDs*


```solidity
function wrapperInternalTransferFrom(bytes32 from, bytes32 to, bytes32 tokenId, uint256 amount)
    external
    notLocked(msg.sig)
    nonReentrant
    assertERC20Wrapper(tokenId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`bytes32`|token sender|
|`to`|`bytes32`|token receiver|
|`tokenId`|`bytes32`|Internal ID of the token|
|`amount`|`uint256`|being transferred|


### internalBurn


```solidity
function internalBurn(bytes32 from, bytes32 tokenId, uint256 amount)
    external
    notLocked(msg.sig)
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`bytes32`|@notice Internal burn of `amount` of `tokenId` tokens of `from` userId|
|`tokenId`|`bytes32`|tokenID to be burned internally|
|`amount`|`uint256`|to be burned|


### getWithdrawableDividend

Get withdrawable dividend amount

*Dividend available for an entity to withdraw*


```solidity
function getWithdrawableDividend(bytes32 ownerId, bytes32 tokenId, bytes32 dividendTokenId)
    external
    view
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ownerId`|`bytes32`|Unique ID of the entity|
|`tokenId`|`bytes32`|Unique ID of token|
|`dividendTokenId`|`bytes32`|Unique ID of dividend token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|_entityPayout accumulated dividend|


### withdrawDividend

Withdraw available dividend

*Transfer dividends to the entity*


```solidity
function withdrawDividend(bytes32 ownerId, bytes32 tokenId, bytes32 dividendTokenId) external notLocked(msg.sig);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ownerId`|`bytes32`|Unique ID of the dividend receiver|
|`tokenId`|`bytes32`|Unique ID of token|
|`dividendTokenId`|`bytes32`|Unique ID of dividend token|


### withdrawAllDividends

Withdraws a user's available dividends.

*Dividends can be available in more than one dividend denomination. This method will withdraw all available dividends in the different dividend denominations.*


```solidity
function withdrawAllDividends(bytes32 ownerId, bytes32 tokenId) external notLocked(msg.sig);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ownerId`|`bytes32`|Unique ID of the dividend receiver|
|`tokenId`|`bytes32`|Unique ID of token|


### payDividendFromEntity

Pay `amount` of dividends

*Transfer dividends to the entity*


```solidity
function payDividendFromEntity(bytes32 guid, uint256 amount)
    external
    notLocked(msg.sig)
    assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_PAY_DIVIDEND_FROM_ENTITY);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`guid`|`bytes32`|Globally unique identifier of a dividend distribution.|
|`amount`|`uint256`|the amount of the dividend token to be distributed to NAYMS token holders.|


### getLockedBalance

Get the amount of tokens that an entity has for sale in the marketplace.


```solidity
function getLockedBalance(bytes32 _entityId, bytes32 _tokenId) external view returns (uint256 amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`| Unique platform ID of the entity.|
|`_tokenId`|`bytes32`|The ID assigned to an external token.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|of tokens that the entity has for sale in the marketplace.|


### internalTransferBySystemAdmin

A system admin can transfer funds from an entity to another entity.


```solidity
function internalTransferBySystemAdmin(bytes32 _fromEntityId, bytes32 _toEntityId, bytes32 _tokenId, uint256 _amount)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fromEntityId`|`bytes32`|Unique platform ID of the entity. Caller must be an entity admin of this entity.|
|`_toEntityId`|`bytes32`|The entity to transfer funds to.|
|`_tokenId`|`bytes32`|The ID assigned to an external token.|
|`_amount`|`uint256`|The amount of internal tokens to transfer.|


### totalDividends

Get the total amount of dividends paid to a cell.


```solidity
function totalDividends(bytes32 _tokenId, bytes32 _dividendDenominationId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`bytes32`|The entity ID of the cell. In otherwords, the participation token ID.|
|`_dividendDenominationId`|`bytes32`|The ID of the dividend token that the dividends were paid in.|


