Exposes methods that require administrative priviledges
## Functions
### setMaxDividendDenominations
Set `_newMax` as the max dividend denominations value.
```solidity
  function setMaxDividendDenominations(
    uint8 _newMax
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newMax` | uint8 | new value to be used.|
<br></br>
### getMaxDividendDenominations
Get the max dividend denominations value
```solidity
  function getMaxDividendDenominations(
  ) external returns (uint8)
```
#### Returns:
| Type | Description |
| --- | --- |
|`max` | dividend denominations|
<br></br>
### isSupportedExternalToken
Is the specified tokenId an external ERC20 that is supported by the Nayms platform?
```solidity
  function isSupportedExternalToken(
    bytes32 _tokenId
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_tokenId` | bytes32 | token address converted to bytes32
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`whether` | token issupported or not|
<br></br>
### addSupportedExternalToken
Add another token to the supported tokens list
```solidity
  function addSupportedExternalToken(
    address _tokenAddress
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_tokenAddress` | address | address of the token to support|
<br></br>
### getSupportedExternalTokens
Get the supported tokens list as an array
```solidity
  function getSupportedExternalTokens(
  ) external returns (address[])
```
#### Returns:
| Type | Description |
| --- | --- |
|`array` | containing address of all supported tokens|
<br></br>
### getSystemId
Gets the System context ID.
```solidity
  function getSystemId(
  ) external returns (bytes32)
```
#### Returns:
| Type | Description |
| --- | --- |
|`System` | Identifier|
<br></br>
### isObjectTokenizable
Check if object can be tokenized
```solidity
  function isObjectTokenizable(
    bytes32 _objectId
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_objectId` | bytes32 | ID of the object|
<br></br>
### lockFunction
System Admin can lock a function
This toggles FunctionLockedStorage.lock to true
```solidity
  function lockFunction(
    bytes4 functionSelector
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`functionSelector` | bytes4 | the bytes4 function selector|
<br></br>
### unlockFunction
System Admin can unlock a function
This toggles FunctionLockedStorage.lock to false
```solidity
  function unlockFunction(
    bytes4 functionSelector
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`functionSelector` | bytes4 | the bytes4 function selector|
<br></br>
### isFunctionLocked
Check if a function has been locked by a system admin
This views FunctionLockedStorage.lock
```solidity
  function isFunctionLocked(
    bytes4 functionSelector
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`functionSelector` | bytes4 | the bytes4 function selector|
<br></br>
### lockAllFundTransferFunctions
Lock all contract methods involving fund transfers
```solidity
  function lockAllFundTransferFunctions(
  ) external
```
### unlockAllFundTransferFunctions
Unlock all contract methods involving fund transfers
```solidity
  function unlockAllFundTransferFunctions(
  ) external
```
### replaceMakerBP
Update market maker fee basis points
```solidity
  function replaceMakerBP(
    uint16 _newMakerBP
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newMakerBP` | uint16 | new maker fee value|
<br></br>
### addFeeSchedule
No description
```solidity
  function addFeeSchedule(
  ) external
```
### removeFeeSchedule
No description
```solidity
  function removeFeeSchedule(
  ) external
```
