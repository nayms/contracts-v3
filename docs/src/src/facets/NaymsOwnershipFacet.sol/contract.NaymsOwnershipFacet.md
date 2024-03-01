# NaymsOwnershipFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/facets/NaymsOwnershipFacet.sol)

**Inherits:**
[IERC173](/src/interfaces/IERC173.sol/interface.IERC173.md), [Modifiers](/src/shared/Modifiers.sol/contract.Modifiers.md)


## Functions
### transferOwnership


```solidity
function transferOwnership(address _newOwner)
    external
    override
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```

### owner


```solidity
function owner() external view override returns (address owner_);
```

