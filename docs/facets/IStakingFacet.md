Stake NAYM tokens
Use this fcet to intreract with the Nayms' staking mechanism
## Functions
### checkpoint
```solidity
  function checkpoint(
  ) external
```
Checkpoint trigger
trigger checkpoint init
### withdraw
```solidity
  function withdraw(
  ) external
```
Withdraw staked funds
Withdraw staked funds to the sender address
### increaseAmount
```solidity
  function increaseAmount(
    uint256 _value
  ) external
```
Increase staked amount by `_value`
Increase staked funds for a given amount
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_value` | uint256 | amount to add to the staking pool
### increaseUnlockTime
```solidity
  function increaseUnlockTime(
    uint256 _secondsIncrease
  ) external
```
Extend staking period for `_value` seconds
Extend staking period for given number of seconds
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_secondsIncrease` | uint256 | seconds to increase staking period for
### createLock
```solidity
  function createLock(
    address _for,
    uint256 _value,
    uint256 _lockDuration
  ) external
```
Lock `_value` on behalf of `_for` for `_lockDuration`
Lock funds belonging to an account for specific amount of time
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_for` | address | account that is locking the funds
|`_value` | uint256 | amount being locked
|`_lockDuration` | uint256 | period for which to lock funds
### depositFor
```solidity
  function depositFor(
    address _user,
    uint256 _value
  ) external
```
Deposit `_value` into staking pool for `_user`
Deposit funds into the staking pool
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_user` | address | account that is depositing the funds
|`_value` | uint256 | amount being locked
### getLastUserSlope
```solidity
  function getLastUserSlope(
    address _user
  ) external returns (int128)
```
Get last slope for `_user`
Gets the last used slope for an account
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_user` | address | account that has staked funds
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`slope`| address | last used
### getUserPointHistoryTimestamp
```solidity
  function getUserPointHistoryTimestamp(
    address _user,
    uint256 _userEpoch
  ) external returns (uint256)
```
Get timestamp for checkpoint
Gets timestamp for a checkpoint corresponding to given epoch
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_user` | address | account address
|`_userEpoch` | uint256 | epoch of the checkopint
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`checkpoint`| address | timestamp
### getUserLockedBalance
```solidity
  function getUserLockedBalance(
    address _user
  ) external returns (struct LockedBalance)
```
Get staked balance for account `_user`
Gets the balance of staked funds
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_user` | address | account that has staked funds
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`amount`| address | of staked funds
### getUserLockedBalanceEndTime
```solidity
  function getUserLockedBalanceEndTime(
    address _user
  ) external returns (uint256)
```
Get the stake expiration period
Gets time when the staking lock expires
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_user` | address | account that has staked funds
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`lock`| address | expiration time
### exchangeRate
```solidity
  function exchangeRate(
  ) external returns (int128)
```
Get the exchange rate for staking
Gets the exchange rate used for staking tokens
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`exchange`|  | rate
### getVENAYMForNAYM
```solidity
  function getVENAYMForNAYM(
    uint256 _value
  ) external returns (uint256)
```
Get the amount of veNAYM received for `_value` NAYM tokens
Converts the amount to staked amount
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_value` | uint256 | amount of NAYM given
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`amount`| uint256 | of veNAYM received
### getNAYMForVENAYM
```solidity
  function getNAYMForVENAYM(
    uint256 _value
  ) external returns (uint256)
```
Get the amount of NAYM received for `_value` veNAYM tokens
Converts the staked amount to amount
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_value` | uint256 | amount of veNAYM given
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`amount`| uint256 | of NAYM received
