External interface to the Token Vault
## Functions
### externalDepositToEntity
Deposit funds into Nayms platform entity
Deposit from an external account
```solidity
  function externalDepositToEntity(
    bytes32 _receiverId,
    address _externalTokenAddress,
    uint256 _amount
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_receiverId` | bytes32 | Internal ID of the account receiving the deposited funds
|`_externalTokenAddress` | address | Token address
|`_amount` | uint256 | deposit amount|
<br></br>
### externalDeposit
Deposit funds into Nayms platform
Deposit from an external account
```solidity
  function externalDeposit(
    bytes32 _receiverId,
    address _externalTokenAddress,
    uint256 _amount
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_receiverId` | bytes32 | Internal ID of the account receiving the deposited funds
|`_externalTokenAddress` | address | Token address
|`_amount` | uint256 | deposit amount|
<br></br>
### externalWithdrawFromEntity
Withdraw funds out of Nayms platform
Withdraw from entity to an external account
```solidity
  function externalWithdrawFromEntity(
    bytes32 _entityId,
    address _receiverId,
    address _externalTokenAddress,
    uint256 _amount
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_entityId` | bytes32 | Internal ID of the entity the user is withdrawing from
|`_receiverId` | address | Internal ID of the account receiving the funds
|`_externalTokenAddress` | address | Token address
|`_amount` | uint256 | amount to withdraw|
<br></br>
