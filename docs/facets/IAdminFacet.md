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
### setPolicyCommissionsBasisPoints
Update policy commission basis points configuration.
```solidity
  function setPolicyCommissionsBasisPoints(
    struct PolicyCommissionsBasisPoints _policyCommissions
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_policyCommissions` | struct PolicyCommissionsBasisPoints | policy commissions configuration to set|
<br></br>
### setTradingCommissionsBasisPoints
Update trading commission basis points configuration.
```solidity
  function setTradingCommissionsBasisPoints(
    struct TradingCommissionsBasisPoints _tradingCommissions
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_tradingCommissions` | struct TradingCommissionsBasisPoints | trading commissions configuration to set|
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
