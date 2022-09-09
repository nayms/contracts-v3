Exposes methods that require administrative priviledges
Use it to configure various core parameters
## Functions
### setEquilibriumLevel
```solidity
  function setEquilibriumLevel(
    uint256 _newLevel
  ) external
```
Set the equilibrium level to `_newLevel` in the NDF
Desired amount of NAYM tokens in NDF
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_newLevel` | uint256 | new value for the equilibrium level
### setMaxDiscount
```solidity
  function setMaxDiscount(
    uint256 _newDiscount
  ) external
```
Set the maximum discount `_newDiscount` in the NDF
TODO explain
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_newDiscount` | uint256 | new value for the max discount
### setTargetNaymsAllocation
```solidity
  function setTargetNaymsAllocation(
    uint256 _newTarget
  ) external
```
Set the targeted NAYM allocation to `_newTarget` in the NDF
TODO explain
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_newTarget` | uint256 | new value for the target allocation
### setDiscountToken
```solidity
  function setDiscountToken(
    address _newToken
  ) external
```
Set the `_newToken` as a token for dicounts
TODO explain
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_newToken` | address | token to be used for discounts
### setPoolFee
```solidity
  function setPoolFee(
    uint24 _newFee
  ) external
```
Set `_newFee` as NDF pool fee
TODO explain
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_newFee` | uint24 | new value to be used as transaction fee in the NDF pool
### setCoefficient
```solidity
  function setCoefficient(
    uint256 _newCoefficient
  ) external
```
Set `_newCoefficient` as the coefficient
TODO explain
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_newCoefficient` | uint256 | new value to be used as coefficient
### getDiscountToken
```solidity
  function getDiscountToken(
  ) external returns (address)
```
Get the discount token
TODO explain
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`address`|  | of the token used for discounts
### getEquilibriumLevel
```solidity
  function getEquilibriumLevel(
  ) external returns (uint256)
```
Get the equilibrium level
TODO explain
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`equilibrium`|  | level value
### getActualNaymsAllocation
```solidity
  function getActualNaymsAllocation(
  ) external returns (uint256)
```
Get current NAYM allocation
TODO explain
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`total`|  | number of NAYM tokens
### getTargetNaymsAllocation
```solidity
  function getTargetNaymsAllocation(
  ) external returns (uint256)
```
Get the target NAYM allocation
TODO explain
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`desired`|  | supply of NAYM tokens
### getMaxDiscount
```solidity
  function getMaxDiscount(
  ) external returns (uint256)
```
Get the maximum discount
TODO explain
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`max`|  | discount value
### getPoolFee
```solidity
  function getPoolFee(
  ) external returns (uint256)
```
Get the pool fee
TODO explain
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`current`|  | pool fee
### getRewardsCoefficient
```solidity
  function getRewardsCoefficient(
  ) external returns (uint256)
```
Get the rewards coeficient
TODO explain
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`coefficient`|  | for rewards
### isSupportedExternalToken
```solidity
  function isSupportedExternalToken(
    bytes32 _tokenId
  ) external returns (bool)
```
is the specified token an external ERC20?
TODO explain
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_tokenId` | bytes32 | token address converted to bytes32
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`whether`| bytes32 | token issupported or not
### addSupportedExternalToken
```solidity
  function addSupportedExternalToken(
    address _tokenAddress
  ) external
```
Add another token to the supported tokens list
TODO explain
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_tokenAddress` | address | address of the token to support
### getSupportedExternalTokens
```solidity
  function getSupportedExternalTokens(
  ) external returns (address[])
```
Get the supported tokens list as an array
TODO explain
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`array`|  | containing address of all supported tokens
### updateRoleAssigner
```solidity
  function updateRoleAssigner(
    string _role,
    string _assignerGroup
  ) external
```
Update who can assign `_role` role
Update who has permission to assign this role
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_role` | string | name of the role
|`_assignerGroup` | string | Group who can assign members to this role
### updateRoleGroup
```solidity
  function updateRoleGroup(
    string _role,
    string _group,
    bool _roleInGroup
  ) external
```
Update role group memebership for `_role` role and `_group` group
Update role group memebership
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_role` | string | name of the role
|`_group` | string | name of the group
|`_roleInGroup` | bool | is member of
### getSystemId
```solidity
  function getSystemId(
  ) external returns (bytes32)
```
gets the System context ID.
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`System`|  | Identifier
