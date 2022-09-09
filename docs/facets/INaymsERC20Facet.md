External facing representation of the NAYM token
ERC20 compliant Nayms' token
## Functions
### name
```solidity
  function name(
  ) external returns (string)
```
Get the token name
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`token`|  | name
### symbol
```solidity
  function symbol(
  ) external returns (string)
```
Get the token symbol
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`token`|  | symbol
### decimals
```solidity
  function decimals(
  ) external returns (uint8)
```
Get the number of decimals for the token
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`number`|  | of decimals
### totalSupply
```solidity
  function totalSupply(
  ) external returns (uint256)
```
Get the total supply of token
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`total`|  | number of tokens in circulation
### balanceOf
```solidity
  function balanceOf(
    address _owner
  ) external returns (uint256 balance)
```
Get token balance for `_owner`
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_owner` | address | token owner
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`balance`| address | holding balance
### transfer
```solidity
  function transfer(
    address _to,
    uint256 _value
  ) external returns (bool success)
```
Transfer `_value` of tokens to `_to`
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_to` | address | address to transfer to
|`_value` | uint256 | amount to transfer
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`success`| address | true if transfer was successful, false otherwise
### transferFrom
```solidity
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool success)
```
Transfer `_value` of tokens from `_from` to `_to`
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_from` | address | address to transfer tokens from
|`_to` | address | address to transfer tokens to
|`_value` | uint256 | amount to transfer
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`success`| address | true if transfer was successful, false otherwise
### approve
```solidity
  function approve(
    address _spender,
    uint256 _value
  ) external returns (bool success)
```
Approve spending of `_value` to `_spender`
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_spender` | address | address to approve spending
|`_value` | uint256 | amount to approve
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`success`| address | true if approval was successful, false otherwise
### increaseAllowance
```solidity
  function increaseAllowance(
    address _spender,
    uint256 _value
  ) external returns (bool success)
```
Increase allowance for `_value` to `_spender`
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_spender` | address | address to approve spending
|`_value` | uint256 | amount to approve
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`success`| address | true if approval was successful, false otherwise
### decreaseAllowance
```solidity
  function decreaseAllowance(
    address _spender,
    uint256 _value
  ) external returns (bool success)
```
Decrease allowance for `_value` to `_spender`
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_spender` | address | address to approve spending
|`_value` | uint256 | amount to approve
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`success`| address | true if approval was successful, false otherwise
### allowance
```solidity
  function allowance(
    address _owner,
    address _spender
  ) external returns (uint256 remaining_)
```
Remaining allowance from `_owner` to `_spender`
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_owner` | address | address that approved spending
|`_spender` | address | address that is approved for spending
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`remaining_`| address | remaining unspent allowance
### permit
```solidity
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 _s
  ) external
```
Gasless allowance approval
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`owner` | address | address that approves spending
|`spender` | address | address that is approved for spending
|`value` | uint256 | approved amount
|`deadline` | uint256 | permit deadline
|`v` | uint8 | v value
|`r` | bytes32 | r value
|`_s` | bytes32 | s value
### DOMAIN_SEPARATOR
```solidity
  function DOMAIN_SEPARATOR(
  ) external returns (bytes32)
```
Domain separator
     @return domain separator
### mint
```solidity
  function mint(
  ) external
```
Mint tokens
### mintTo
```solidity
  function mintTo(
    address _user
  ) external
```
Mint tokens to `_user`
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_user` | address | addres to mint tokens to
