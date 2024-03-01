# LibTokenizedVaultIO
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/libs/LibTokenizedVaultIO.sol)

*Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155*


## Functions
### _externalDeposit


```solidity
function _externalDeposit(bytes32 _receiverId, address _externalTokenAddress, uint256 _amount) internal;
```

### _externalWithdraw


```solidity
function _externalWithdraw(bytes32 _entityId, address _receiver, address _externalTokenAddress, uint256 _amount)
    internal;
```

