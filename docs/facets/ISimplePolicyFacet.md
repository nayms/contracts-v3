Facet for working with Simple Policies
## Functions
### paySimplePremium
No description
Pay a premium of `_amount` on simple policy
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
|`_amount` | uint256 | Amount of the premium|
<br></br>
### paySimpleClaim
No description
Pay a claim of `_amount` for simple policy
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
|`_amount` | uint256 | Amount of the claim|
<br></br>
### getSimplePolicyInfo
No description
Get simple policy info
```solidity
  function getSimplePolicyInfo(
    bytes32 _id
  ) external returns (struct SimplePolicyInfo)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_id` | bytes32 | Id of the simple policy
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`Simple` | policy metadata|
<br></br>
### getPremiumCommissionBasisPoints
Get the policy premium commissions basis points.
```solidity
  function getPremiumCommissionBasisPoints(
  ) external returns (struct PolicyCommissionsBasisPoints)
```
#### Returns:
| Type | Description |
| --- | --- |
|`PolicyCommissionsBasisPoints` | struct containing the individual basis points set for each policy commission receiver.|
<br></br>
### checkAndUpdateSimplePolicyState
No description
Check and update simple policy state
```solidity
  function checkAndUpdateSimplePolicyState(
    bytes32 _id
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_id` | bytes32 | Id of the simple policy|
<br></br>
### cancelSimplePolicy
No description
Cancel a simple policy
```solidity
  function cancelSimplePolicy(
    bytes32 _policyId
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_policyId` | bytes32 | Id of the simple policy|
<br></br>
### getSigningHash
No description
Generate a simple policy hash for singing by the stakeholders
```solidity
  function getSigningHash(
    uint256 _startDate,
    uint256 _maturationDate,
    bytes32 _asset,
    uint256 _limit,
    bytes32 _dataHash
  ) external returns (bytes32)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_startDate` | uint256 | Date when policy becomes active
|`_maturationDate` | uint256 | Date after which policy becomes matured
|`_asset` | bytes32 | ID of the underlying asset, used as collateral and to pay out claims
|`_limit` | uint256 | Policy coverage limit
|`_dataHash` | bytes32 | Hash of all the important policy data stored offchain|
<br></br>
