# GovernanceFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/facets/GovernanceFacet.sol)

**Inherits:**
[Modifiers](/src/shared/Modifiers.sol/contract.Modifiers.md)


## Functions
### isDiamondInitialized

Check if the diamond has been initialized.

*This will get the value from AppStorage.diamondInitialized.*


```solidity
function isDiamondInitialized() external view returns (bool);
```

### calculateUpgradeId

Calcuate upgrade hash: `id`

*calucate the upgrade hash by hashing all the inputs*


```solidity
function calculateUpgradeId(IDiamondCut.FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata)
    external
    pure
    returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_diamondCut`|`IDiamondCut.FacetCut[]`|the array of FacetCut struct, IDiamondCut.FacetCut[] to be used for upgrade|
|`_init`|`address`|address of the init diamond to be used for upgrade|
|`_calldata`|`bytes`|bytes to be passed as call data for upgrade|


### createUpgrade

Approve the following upgrade hash: `id`

*The diamondCut() has been modified to check if the upgrade has been scheduled. This method needs to be called in order
for an upgrade to be executed.*


```solidity
function createUpgrade(bytes32 id) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].|


### updateUpgradeExpiration

Update the diamond cut upgrade expiration period.

*When createUpgrade() is called, it allows a diamondCut() upgrade to be executed. This upgrade must be executed before the
upgrade expires. The upgrade expires based on when the upgrade was scheduled (when createUpgrade() was called) + AppStorage.upgradeExpiration.*


```solidity
function updateUpgradeExpiration(uint256 duration)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`duration`|`uint256`|The duration until the upgrade expires.|


### cancelUpgrade

Cancel the following upgrade hash: `id`

*This will set the mapping AppStorage.upgradeScheduled back to 0.*


```solidity
function cancelUpgrade(bytes32 id) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].|


### getUpgrade

Get the expiry date for provided upgrade hash.

*This will get the value from AppStorage.upgradeScheduled  mapping.*


```solidity
function getUpgrade(bytes32 id) external view returns (uint256 expiry);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].|


### getUpgradeExpiration

Get the upgrade expiration period.

*This will get the value from AppStorage.upgradeExpiration. AppStorage.upgradeExpiration is added to the block.timestamp to create the upgrade expiration date.*


```solidity
function getUpgradeExpiration() external view returns (uint256 upgradeExpiration);
```

## Events
### CreateUpgrade

```solidity
event CreateUpgrade(bytes32 id, address indexed who);
```

### UpdateUpgradeExpiration

```solidity
event UpdateUpgradeExpiration(uint256 duration);
```

### UpgradeCancelled

```solidity
event UpgradeCancelled(bytes32 id, address indexed who);
```

