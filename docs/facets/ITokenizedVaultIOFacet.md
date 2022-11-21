External interface to the Token Vault
## Functions
### externalDeposit
Deposit funds into msg.sender's Nayms platform entity
Deposit from msg.sender to their associated entity
```solidity
  function externalDeposit(
    address _externalTokenAddress,
    uint256 _amount
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
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
