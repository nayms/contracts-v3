# LibGovernance
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/libs/LibGovernance.sol)

Contains internal methods for upgrade functionality


## Functions
### _calculateUpgradeId


```solidity
function _calculateUpgradeId(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata)
    internal
    pure
    returns (bytes32);
```

