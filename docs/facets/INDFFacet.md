Facet for the Nayms Discretionary Fund
NDF facet
## Functions
### getDiscount
```solidity
  function getDiscount(
  ) external returns (uint256)
```
### getNaymsValueRatio
```solidity
  function getNaymsValueRatio(
  ) external returns (uint256)
```
### buyNayms
```solidity
  function buyNayms(
    uint256 _maxWilling
  ) external
```
Buy `_maxWilling` from NDF
Buy discounted tokens from NDF
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_maxWilling` | uint256 | Max amount of tokens willing to spend
### paySubSurplusFund
```solidity
  function paySubSurplusFund(
    uint256 _amount
  ) external
```
Pay `_amount` to the SubSurplus Fund
Pay the amount to the SSF
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_amount` | uint256 | Amount to pay to the SSF
### swapTokens
```solidity
  function swapTokens(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint24 _poolFee
  ) external returns (uint256 amountOut)
```
Swap `_amountIn` of `_tokenIn` for `_tokenOut` tokens with fee of `_poolFee`
Swap tokens on Uniswap
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_tokenIn` | address | Token to swap
|`_tokenOut` | address | Token to get
|`_amountIn` | uint256 | Amount to swap
|`_poolFee` | uint24 | Fee payed to the pool
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`amountOut`| address | Tokens received
