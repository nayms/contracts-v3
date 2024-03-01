# NaymsOwnershipFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/facets/NaymsOwnershipFacet.sol)

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

