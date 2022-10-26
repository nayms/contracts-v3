Facet for working with Simple Policies
## Functions
### paySimplePremium
No description
```solidity
  function paySimplePremium(
    bytes32 _policyId,
    uint256 _amount
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_policyId` | bytes32 | Id of the simple policy
|`_amount` | uint256 | Amount of the premium
### paySimpleClaim
No description
```solidity
  function paySimpleClaim(
    bytes32 _claimId,
    bytes32 _policyId,
    bytes32 _insuredId,
    uint256 _amount
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_claimId` | bytes32 | Id of the simple policy claim
|`_policyId` | bytes32 | Id of the simple policy
|`_insuredId` | bytes32 | Id of the insured party
|`_amount` | uint256 | Amount of the claim
### getSimplePolicyInfo
No description
```solidity
  function getSimplePolicyInfo(
    bytes32 _id
  ) external returns (struct SimplePolicy)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_id` | bytes32 | Id of the simple policy
#### Returns:
| Type | Description |
| --- | --- |
|`Simple` | policy metadata
### getPremiumCommissionBasisPoints
No description
```solidity
  function getPremiumCommissionBasisPoints(
  ) external returns (struct PolicyCommissionsBasisPoints)
```
### checkAndUpdateSimplePolicyState
No description
```solidity
  function checkAndUpdateSimplePolicyState(
    bytes32 _id
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_id` | bytes32 | Id of the simple policy
