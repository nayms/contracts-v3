# SimplePolicyFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/facets/SimplePolicyFacet.sol)

**Inherits:**
[Modifiers](/src/shared/Modifiers.sol/contract.Modifiers.md)

Facet for working with Simple Policies

*Simple Policy facet*


## Functions
### paySimplePremium

*Pay a premium of `_amount` on simple policy*


```solidity
function paySimplePremium(bytes32 _policyId, uint256 _amount)
    external
    notLocked(msg.sig)
    assertPrivilege(_policyId, LC.GROUP_PAY_SIMPLE_PREMIUM);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_policyId`|`bytes32`|Id of the simple policy|
|`_amount`|`uint256`|Amount of the premium|


### paySimpleClaim

*Pay a claim of `_amount` for simple policy*


```solidity
function paySimpleClaim(bytes32 _claimId, bytes32 _policyId, bytes32 _insuredId, uint256 _amount)
    external
    notLocked(msg.sig)
    assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_PAY_SIMPLE_CLAIM);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_claimId`|`bytes32`|Id of the simple policy claim|
|`_policyId`|`bytes32`|Id of the simple policy|
|`_insuredId`|`bytes32`|Id of the insured party|
|`_amount`|`uint256`|Amount of the claim|


### getSimplePolicyInfo

*Get simple policy info*


```solidity
function getSimplePolicyInfo(bytes32 _policyId) external view returns (SimplePolicyInfo memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_policyId`|`bytes32`|Id of the simple policy|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`SimplePolicyInfo`|Simple policy metadata|


### getPolicyCommissionReceivers

*Get the list of commission receivers*


```solidity
function getPolicyCommissionReceivers(bytes32 _id) external view returns (bytes32[] memory commissionReceivers);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_id`|`bytes32`|Id of the simple policy|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`commissionReceivers`|`bytes32[]`|commissionReceivers|


### checkAndUpdateSimplePolicyState

*Check and update simple policy state*


```solidity
function checkAndUpdateSimplePolicyState(bytes32 _policyId) external notLocked(msg.sig);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_policyId`|`bytes32`|Id of the simple policy|


### cancelSimplePolicy

*Cancel a simple policy*


```solidity
function cancelSimplePolicy(bytes32 _policyId)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_UNDERWRITERS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_policyId`|`bytes32`|Id of the simple policy|


### getSigningHash

*Generate a simple policy hash for singing by the stakeholders*


```solidity
function getSigningHash(
    uint256 _startDate,
    uint256 _maturationDate,
    bytes32 _asset,
    uint256 _limit,
    bytes32 _offchainDataHash
) external view returns (bytes32 signingHash_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_startDate`|`uint256`|Date when policy becomes active|
|`_maturationDate`|`uint256`|Date after which policy becomes matured|
|`_asset`|`bytes32`|ID of the underlying asset, used as collateral and to pay out claims|
|`_limit`|`uint256`|Policy coverage limit|
|`_offchainDataHash`|`bytes32`|Hash of all the important policy data stored offchain|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`signingHash_`|`bytes32`|hash for signing|


### calculatePremiumFees

*Calculate the policy premium fees based on a buy amount.*


```solidity
function calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid)
    external
    view
    returns (CalculatedFees memory cf);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_policyId`|`bytes32`||
|`_premiumPaid`|`uint256`|The amount that the fees payments are calculated from.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`cf`|`CalculatedFees`|CalculatedFees struct|


