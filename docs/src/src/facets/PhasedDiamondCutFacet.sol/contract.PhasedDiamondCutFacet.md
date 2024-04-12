# PhasedDiamondCutFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/facets/PhasedDiamondCutFacet.sol)

**Inherits:**
IDiamondCut


## Functions
### diamondCut

Add/replace/remove any number of functions and optionally execute
a function with delegatecall


```solidity
function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_diamondCut`|`FacetCut[]`|Contains the facet addresses and function selectors|
|`_init`|`address`|The address of the contract or facet to execute _calldata|
|`_calldata`|`bytes`|A function call, including function selector and arguments _calldata is executed with delegatecall on _init|


