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
|`_newLevel` | uint256 | new value for the equilibrium level
### setMaxDiscount
Set the maximum discount `_newDiscount` in the NDF
TODO explain
```solidity
  function setMaxDiscount(
    uint256 _newDiscount
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newDiscount` | uint256 | new value for the max discount
### setTargetNaymsAllocation
Set the targeted NAYM allocation to `_newTarget` in the NDF
TODO explain
```solidity
  function setTargetNaymsAllocation(
    uint256 _newTarget
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newTarget` | uint256 | new value for the target allocation
### setDiscountToken
Set the `_newToken` as a token for dicounts
TODO explain
```solidity
  function setDiscountToken(
    address _newToken
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newToken` | address | token to be used for discounts
### setPoolFee
Set `_newFee` as NDF pool fee
TODO explain
```solidity
  function setPoolFee(
    uint24 _newFee
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newFee` | uint24 | new value to be used as transaction fee in the NDF pool
### setCoefficient
Set `_newCoefficient` as the coefficient
TODO explain
```solidity
  function setCoefficient(
    uint256 _newCoefficient
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newCoefficient` | uint256 | new value to be used as coefficient
### setMaxDividendDenominations
Set `_newMax` as the max dividend denominations value.
TODO explain
```solidity
  function setMaxDividendDenominations(
    uint8 _newMax
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_newMax` | uint8 | new value to be used.
### getDiscountToken
Get the discount token
TODO explain
```solidity
  function getDiscountToken(
  ) external returns (address)
```
#### Returns:
| Type | Description |
| --- | --- |
|`address` | of the token used for discounts
### getEquilibriumLevel
Get the equilibrium level
TODO explain
```solidity
  function getEquilibriumLevel(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`equilibrium` | level value
### getActualNaymsAllocation
Get current NAYM allocation
TODO explain
```solidity
  function getActualNaymsAllocation(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`total` | number of NAYM tokens
### getTargetNaymsAllocation
Get the target NAYM allocation
TODO explain
```solidity
  function getTargetNaymsAllocation(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`desired` | supply of NAYM tokens
### getMaxDiscount
Get the maximum discount
TODO explain
```solidity
  function getMaxDiscount(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`max` | discount value
### getPoolFee
Get the pool fee
TODO explain
```solidity
  function getPoolFee(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`current` | pool fee
### getRewardsCoefficient
Get the rewards coeficient
TODO explain
```solidity
  function getRewardsCoefficient(
  ) external returns (uint256)
```
#### Returns:
| Type | Description |
| --- | --- |
|`coefficient` | for rewards
### getMaxDividendDenominations
Get the max dividend denominations value
TODO explain
```solidity
  function getMaxDividendDenominations(
  ) external returns (uint8)
```
#### Returns:
| Type | Description |
| --- | --- |
|`max` | dividend denominations
### isSupportedExternalToken
is the specified token an external ERC20?
TODO explain
```solidity
  function isSupportedExternalToken(
    bytes32 _tokenId
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_tokenId` | bytes32 | token address converted to bytes32
#### Returns:
| Type | Description |
| --- | --- |
|`whether` | token issupported or not
### addSupportedExternalToken
Add another token to the supported tokens list
TODO explain
```solidity
  function addSupportedExternalToken(
    address _tokenAddress
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_tokenAddress` | address | address of the token to support
### getSupportedExternalTokens
Get the supported tokens list as an array
TODO explain
```solidity
  function getSupportedExternalTokens(
  ) external returns (address[])
```
#### Returns:
| Type | Description |
| --- | --- |
|`array` | containing address of all supported tokens
### updateRoleAssigner
Update who can assign `_role` role
Update who has permission to assign this role
```solidity
  function updateRoleAssigner(
    string _role,
    string _assignerGroup
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_role` | string | name of the role
|`_assignerGroup` | string | Group who can assign members to this role
### updateRoleGroup
Update role group memebership for `_role` role and `_group` group
Update role group memebership
```solidity
  function updateRoleGroup(
    string _role,
    string _group,
    bool _roleInGroup
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_role` | string | name of the role
|`_group` | string | name of the group
|`_roleInGroup` | bool | is member of
### getSystemId
Gets the System context ID.
```solidity
  function getSystemId(
  ) external returns (bytes32)
```
#### Returns:
| Type | Description |
| --- | --- |
|`System` | Identifier
