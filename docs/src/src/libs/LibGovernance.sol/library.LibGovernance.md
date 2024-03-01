# LibGovernance
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/libs/LibGovernance.sol)

Contains internal methods for upgrade functionality


## Functions
### _calculateUpgradeId


```solidity
function _calculateUpgradeId(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata)
    internal
    pure
    returns (bytes32);
```

