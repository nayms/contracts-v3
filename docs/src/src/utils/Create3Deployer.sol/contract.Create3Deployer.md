# Create3Deployer
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/utils/Create3Deployer.sol)


## Functions
### deployContract


```solidity
function deployContract(bytes32 salt, bytes memory creationCode, uint256 value) external returns (address deployed);
```

### getDeployed


```solidity
function getDeployed(bytes32 salt) external view returns (address deployed);
```

