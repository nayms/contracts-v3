## Functions
### isDiamondInitialized
Check if the diamond has been initialized.
This will get the value from AppStorage.diamondInitialized.
```solidity
  function isDiamondInitialized(
  ) external returns (bool)
```
### createUpgrade
Approve the following upgrade hash: `id`
The diamondCut() has been modified to check if the upgrade has been scheduled. This method needs to be called in order
     for an upgrade to be executed.
```solidity
  function createUpgrade(
    bytes32 id
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`id` | bytes32 | This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].|
<br></br>
### updateUpgradeExpiration
Update the diamond cut upgrade expiration period.
When createUpgrade() is called, it allows a diamondCut() upgrade to be executed. This upgrade must be executed before the
     upgrade expires. The upgrade expires based on when the upgrade was scheduled (when createUpgrade() was called) + AppStorage.upgradeExpiration.
```solidity
  function updateUpgradeExpiration(
    uint256 duration
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`duration` | uint256 | The duration until the upgrade expires.|
<br></br>
### cancelUpgrade
Cancel the following upgrade hash: `id`
This will set the mapping AppStorage.upgradeScheduled back to 0.
```solidity
  function cancelUpgrade(
    bytes32 id
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`id` | bytes32 | This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].|
<br></br>
### getUpgrade
Get the expiry date for provided upgrade hash.
This will get the value from AppStorage.upgradeScheduled  mapping.
```solidity
  function getUpgrade(
    bytes32 id
  ) external returns (uint256 expiry)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`id` | bytes32 | This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].|
<br></br>
### getUpgradeExpiration
Get the upgrade expiration period.
This will get the value from AppStorage.upgradeExpiration. AppStorage.upgradeExpiration is added to the block.timestamp to create the upgrade expiration date.
```solidity
  function getUpgradeExpiration(
  ) external returns (uint256 upgradeExpiration)
```
