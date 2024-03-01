# AdminFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/facets/AdminFacet.sol)

**Inherits:**
[Modifiers](/src/shared/Modifiers.sol/contract.Modifiers.md)

Exposes methods that require administrative privileges

*Use it to configure various core parameters*


## Functions
### setMaxDividendDenominations

Set `_newMax` as the max dividend denominations value.


```solidity
function setMaxDividendDenominations(uint8 _newMax)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_newMax`|`uint8`|new value to be used.|


### getMaxDividendDenominations

Get the max dividend denominations value


```solidity
function getMaxDividendDenominations() external view returns (uint8);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint8`|max dividend denominations|


### isSupportedExternalToken

Is the specified tokenId an external ERC20 that is supported by the Nayms platform?


```solidity
function isSupportedExternalToken(bytes32 _tokenId) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`bytes32`|token address converted to bytes32|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|whether token is supported or not|


### addSupportedExternalToken

Add another token to the supported tokens list


```solidity
function addSupportedExternalToken(address _tokenAddress, uint256 _minimumSell)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenAddress`|`address`|address of the token to support|
|`_minimumSell`|`uint256`|minimum amount of tokens that can be sold on the marketplace|


### getSupportedExternalTokens

Get the supported tokens list as an array


```solidity
function getSupportedExternalTokens() external view returns (address[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|array containing address of all supported tokens|


### getSystemId

Gets the System context ID.


```solidity
function getSystemId() external pure returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|System Identifier|


### isObjectTokenizable

Check if object can be tokenized


```solidity
function isObjectTokenizable(bytes32 _objectId) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_objectId`|`bytes32`|ID of the object|


### lockFunction

System Admin can lock a function

*This toggles FunctionLockedStorage.lock to true*


```solidity
function lockFunction(bytes4 functionSelector)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`functionSelector`|`bytes4`|the bytes4 function selector|


### unlockFunction

System Admin can unlock a function

*This toggles FunctionLockedStorage.lock to false*


```solidity
function unlockFunction(bytes4 functionSelector)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`functionSelector`|`bytes4`|the bytes4 function selector|


### isFunctionLocked

Check if a function has been locked by a system admin

*This views FunctionLockedStorage.lock*


```solidity
function isFunctionLocked(bytes4 functionSelector) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`functionSelector`|`bytes4`|the bytes4 function selector|


### lockAllFundTransferFunctions

Lock all contract methods involving fund transfers


```solidity
function lockAllFundTransferFunctions() external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```

### unlockAllFundTransferFunctions

Unlock all contract methods involving fund transfers


```solidity
function unlockAllFundTransferFunctions() external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```

### replaceMakerBP

Update market maker fee basis points


```solidity
function replaceMakerBP(uint16 _newMakerBP) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_newMakerBP`|`uint16`|new maker fee value|


### addFeeSchedule

Add or update an existing fee schedule


```solidity
function addFeeSchedule(
    bytes32 _entityId,
    uint256 _feeScheduleType,
    bytes32[] calldata _receiver,
    uint16[] calldata _basisPoints
) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`|object ID for which the fee schedule is being set, use system ID for global fee schedule|
|`_feeScheduleType`|`uint256`|fee schedule type (premiums, trading, inital sale)|
|`_receiver`|`bytes32[]`|array of fee recipient IDs|
|`_basisPoints`|`uint16[]`|array of basis points for each of the fee receivers|


### removeFeeSchedule

remove a fee schedule


```solidity
function removeFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`|object ID for which the fee schedule is being removed|
|`_feeScheduleType`|`uint256`|type of fee schedule|


### approveSelfOnboarding

Approve a user address for self-onboarding


```solidity
function approveSelfOnboarding(address _userAddress, bytes32 _entityId, string calldata _role)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_ONBOARDING_APPROVERS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_userAddress`|`address`|user account address|
|`_entityId`|`bytes32`||
|`_role`|`string`||


### onboard

Create a token holder entity for a user account


```solidity
function onboard() external;
```

### isSelfOnboardingApproved


```solidity
function isSelfOnboardingApproved(address _userAddress, bytes32 _entityId) external view returns (bool);
```

### cancelSelfOnboarding


```solidity
function cancelSelfOnboarding(address _user)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS);
```

