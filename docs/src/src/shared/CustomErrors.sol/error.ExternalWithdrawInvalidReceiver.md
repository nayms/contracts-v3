# ExternalWithdrawInvalidReceiver
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/shared/CustomErrors.sol)

*The receiver of the withdraw must haveGroupPriviledge with the roles entity admin, comptroller combined, or comptroller withdraw.*


```solidity
error ExternalWithdrawInvalidReceiver(address receiver);
```

