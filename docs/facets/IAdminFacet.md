Exposes methods that require administrative priviledges
## Functions
### setEquilibriumLevel
Set the equilibrium level to `_newLevel` in the NDF
Desired amount of NAYM tokens in NDF
```solidity
  function setEquilibriumLevel(
    uint256 _newLevel
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newLevel` | uint256 | new value for the equilibrium level|
<br></br>
### setMaxDiscount
Set the maximum discount `_newDiscount` in the NDF
```solidity
  function setMaxDiscount(
    uint256 _newDiscount
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newDiscount` | uint256 | new value for the max discount|
<br></br>
### setTargetNaymsAllocation
Set the targeted NAYM allocation to `_newTarget` in the NDF
```solidity
  function setTargetNaymsAllocation(
    uint256 _newTarget
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newTarget` | uint256 | new value for the target allocation|
<br></br>
### setDiscountToken
Set the `_newToken` as a token for discounts
```solidity
  function setDiscountToken(
    address _newToken
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newToken` | address | token to be used for discounts|
<br></br>
### setPoolFee
Set `_newFee` as NDF pool fee
```solidity
  function setPoolFee(
    uint24 _newFee
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newFee` | uint24 | new value to be used as transaction fee in the NDF pool|
<br></br>
### setCoefficient
Set `_newCoefficient` as the coefficient
```solidity
  function setCoefficient(
    uint256 _newCoefficient
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newCoefficient` | uint256 | new value to be used as coefficient|
<br></br>
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
### getDiscountToken
Get the discount token
```solidity
  function getDiscountToken(
  ) external returns (address)
```
#### Returns:
| Type | Description |
| --- | --- |
|`address` | of the token used for discounts|
<br></br>
### getEquilibriumLevel
Get the equilibrium level
```solidity
  function getEquilibriumLevel(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`equilibrium` | level value|
<br></br>
### getActualNaymsAllocation
Get current NAYM allocation
```solidity
  function getActualNaymsAllocation(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`total` | number of NAYM tokens|
<br></br>
### getTargetNaymsAllocation
Get the target NAYM allocation
```solidity
  function getTargetNaymsAllocation(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`desired` | supply of NAYM tokens|
<br></br>
### getMaxDiscount
Get the maximum discount
```solidity
  function getMaxDiscount(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`max` | discount value|
<br></br>
### getPoolFee
Get the pool fee
```solidity
  function getPoolFee(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`current` | pool fee|
<br></br>
### getRewardsCoefficient
Get the rewards coeficient
```solidity
  function getRewardsCoefficient(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`coefficient` | for rewards|
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
is the specified token an external ERC20?
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
