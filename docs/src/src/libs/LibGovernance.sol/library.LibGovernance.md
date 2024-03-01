# LibGovernance
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/libs/LibGovernance.sol)

Contains internal methods for upgrade functionality


## Functions
### _calculateUpgradeId


```solidity
function _calculateUpgradeId(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata)
    internal
    pure
    returns (bytes32);
```

