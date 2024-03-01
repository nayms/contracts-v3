# ExternalWithdrawInvalidReceiver
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/CustomErrors.sol)

*The receiver of the withdraw must haveGroupPriviledge with the roles entity admin, comptroller combined, or comptroller withdraw.*


```solidity
error ExternalWithdrawInvalidReceiver(address receiver);
```

