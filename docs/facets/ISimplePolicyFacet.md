Facet for working with Simple Policies
Simple Policy facet
## Functions
### paySimplePremium
```solidity
  function paySimplePremium(
    bytes32 _policyId,
    uint256 _amount
  ) external
```
Pay a premium of `_amount` on simple policy
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_policyId` | bytes32 | Id of the simple policy
|`_amount` | uint256 | Amount of the premium
### paySimpleClaim
```solidity
  function paySimpleClaim(
    bytes32 _claimId,
    bytes32 _policyId,
    bytes32 _insuredId,
    uint256 _amount
  ) external
```
Pay a claim of `_amount` for simple policy
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_claimId` | bytes32 | Id of the simple policy claim
|`_policyId` | bytes32 | Id of the simple policy
|`_insuredId` | bytes32 | Id of the insured party
|`_amount` | uint256 | Amount of the claim
### getSimplePolicyInfo
```solidity
  function getSimplePolicyInfo(
    bytes32 _id
  ) external returns (struct SimplePolicy)
```
Get simple policy info
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_id` | bytes32 | Id of the simple policy
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`Simple`| bytes32 | policy metadata
### getPremiumCommissionBasisPoints
```solidity
  function getPremiumCommissionBasisPoints(
  ) external returns (struct PolicyCommissionsBasisPoints)
```
### checkAndUpdateSimplePolicyState
```solidity
  function checkAndUpdateSimplePolicyState(
    bytes32 _id
  ) external
```
Check and update simple policy state
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_id` | bytes32 | Id of the simple policy
