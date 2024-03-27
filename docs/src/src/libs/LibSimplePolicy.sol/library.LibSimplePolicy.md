# LibSimplePolicy
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/libs/LibSimplePolicy.sol)


## Functions
### _getSimplePolicyInfo


```solidity
function _getSimplePolicyInfo(bytes32 _policyId) internal view returns (SimplePolicy memory simplePolicyInfo);
```

### _checkAndUpdateState


```solidity
function _checkAndUpdateState(bytes32 _policyId) internal;
```

### _payPremium


```solidity
function _payPremium(bytes32 _payerEntityId, bytes32 _policyId, uint256 _amount) internal;
```

### _payClaim


```solidity
function _payClaim(bytes32 _claimId, bytes32 _policyId, bytes32 _insuredEntityId, uint256 _amount) internal;
```

### _cancel


```solidity
function _cancel(bytes32 _policyId) internal;
```

### releaseFunds


```solidity
function releaseFunds(bytes32 _policyId) private;
```

### _getSigningHash


```solidity
function _getSigningHash(
    uint256 _startDate,
    uint256 _maturationDate,
    bytes32 _asset,
    uint256 _limit,
    bytes32 _offchainDataHash
) internal view returns (bytes32);
```

## Events
### SimplePolicyMatured

```solidity
event SimplePolicyMatured(bytes32 indexed id);
```

### SimplePolicyCancelled

```solidity
event SimplePolicyCancelled(bytes32 indexed id);
```

### SimplePolicyPremiumPaid

```solidity
event SimplePolicyPremiumPaid(bytes32 indexed id, uint256 amount);
```

### SimplePolicyClaimPaid

```solidity
event SimplePolicyClaimPaid(
    bytes32 indexed claimId, bytes32 indexed policyId, bytes32 indexed insuredId, uint256 amount
);
```

