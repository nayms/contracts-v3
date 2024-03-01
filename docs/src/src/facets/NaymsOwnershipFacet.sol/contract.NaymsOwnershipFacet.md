# NaymsOwnershipFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/facets/NaymsOwnershipFacet.sol)

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

