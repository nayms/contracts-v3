Facet for the Sub Surplus Fund
SSF facet
## Functions
### payRewardsToUser
```solidity
  function payRewardsToUser(
    address _tokenIn,
    uint256 _amountIn,
    address _to
  ) external
```
Pay `_amountIn` tokens of reward to `_to`
Uses the _estimateAmountOut function to calculate the given reward for the user and perform the transfer
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_tokenIn` | address | is the token the user paid the premium in
|`_amountIn` | uint256 | is the amount the user paid
|`_to` | address | is the address of the user recieving the reward
### estimateAmountOut
```solidity
  function estimateAmountOut(
    address _tokenIn,
    address _quoteToken,
    uint256 _amountIn,
    uint160 _sqrtPriceX96
  ) external returns (uint256 amountOut)
```
Estimate conversion rate of `_amountIn` tokens
Uses the uniswap V3 library to recieve a conversion between two tokens
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_tokenIn` | address | is the address of the token we are qouting from
|`_quoteToken` | address | is the address of the token we want the quote of
|`_amountIn` | uint256 | is the amount of the tokenIn that was paid
|`_sqrtPriceX96` | uint160 | is the sqrt price needed
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`amountOut`| address | is the amount of the quote token that equals the inputted token
### payReward
```solidity
  function payReward(
  ) external returns (uint256)
```
uses the _estimateAmountOut return value to calculate the given reward for the user and perform the transfer
    @param _amountIn is the amount the user paid
    @param _to is the user recieving the reward
    @return returning the value of the end reward paid out
