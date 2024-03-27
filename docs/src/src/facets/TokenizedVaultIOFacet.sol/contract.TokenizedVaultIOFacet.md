# TokenizedVaultIOFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/facets/TokenizedVaultIOFacet.sol)

**Inherits:**
[Modifiers](/src/shared/Modifiers.sol/contract.Modifiers.md), [ReentrancyGuard](/src/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md)

External interface to the Token Vault

*Used for external transfers. Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155*


## Functions
### externalDeposit

Deposit funds into msg.sender's Nayms platform entity

*Deposit from msg.sender to their associated entity*


```solidity
function externalDeposit(address _externalTokenAddress, uint256 _amount)
    external
    notLocked(msg.sig)
    nonReentrant
    assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_EXTERNAL_DEPOSIT);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_externalTokenAddress`|`address`|Token address|
|`_amount`|`uint256`|deposit amount|


### externalWithdrawFromEntity

Withdraw funds out of Nayms platform

*Withdraw from entity to an external account*


```solidity
function externalWithdrawFromEntity(
    bytes32 _entityId,
    address _receiver,
    address _externalTokenAddress,
    uint256 _amount
)
    external
    notLocked(msg.sig)
    nonReentrant
    assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`|Internal ID of the entity the user is withdrawing from|
|`_receiver`|`address`|Internal ID of the account receiving the funds|
|`_externalTokenAddress`|`address`|Token address|
|`_amount`|`uint256`|amount to withdraw|


