# ExternalWithdrawInvalidReceiver
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/CustomErrors.sol)

*The receiver of the withdraw must haveGroupPriviledge with the roles entity admin, comptroller combined, or comptroller withdraw.*


```solidity
error ExternalWithdrawInvalidReceiver(address receiver);
```

