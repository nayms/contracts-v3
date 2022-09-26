External interface to the Token Vault
Used for external transfers. Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
     https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
## Functions
### externalDepositToEntity
```solidity
  function externalDepositToEntity(
    bytes32 _receiverId,
    address _externalTokenAddress,
    uint256 _amount
  ) external
```
Deposit funds into Nayms platform entity
Deposit from an external account
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_receiverId` | bytes32 | Internal ID of the account receiving the deposited funds
|`_externalTokenAddress` | address | Token address
|`_amount` | uint256 | deposit amount
### externalDeposit
```solidity
  function externalDeposit(
    bytes32 _receiverId,
    address _externalTokenAddress,
    uint256 _amount
  ) external
```
Deposit funds into Nayms platform
Deposit from an external account
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_receiverId` | bytes32 | Internal ID of the account receiving the deposited funds
|`_externalTokenAddress` | address | Token address
|`_amount` | uint256 | deposit amount
### externalWithdrawFromEntity
```solidity
  function externalWithdrawFromEntity(
    bytes32 _entityId,
    address _receiverId,
    address _externalTokenAddress,
    uint256 _amount
  ) external
```
Withdraw funds out of Nayms platform
Withdraw from entity to an external account
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_entityId` | bytes32 | Internal ID of the entity the user is withdrawing from
|`_receiverId` | address | Internal ID of the account receiving the funds
|`_externalTokenAddress` | address | Token address
|`_amount` | uint256 | amount to withdraw
