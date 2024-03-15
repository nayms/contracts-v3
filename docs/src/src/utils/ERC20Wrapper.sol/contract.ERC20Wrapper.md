# ERC20Wrapper
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/utils/ERC20Wrapper.sol)

**Inherits:**
[IERC20](/src/interfaces/IERC20.sol/interface.IERC20.md), [ReentrancyGuard](/src/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md)


## State Variables
### tokenId

```solidity
bytes32 internal immutable tokenId;
```


### nayms

```solidity
IDiamondProxy internal immutable nayms;
```


### allowances

```solidity
mapping(address => mapping(address => uint256)) public allowances;
```


### INITIAL_CHAIN_ID

```solidity
uint256 internal immutable INITIAL_CHAIN_ID;
```


### INITIAL_DOMAIN_SEPARATOR

```solidity
bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
```


### nonces

```solidity
mapping(address => uint256) public nonces;
```


## Functions
### constructor


```solidity
constructor(bytes32 _tokenId);
```

### name


```solidity
function name() external view returns (string memory);
```

### symbol


```solidity
function symbol() external view returns (string memory);
```

### decimals


```solidity
function decimals() external pure returns (uint8);
```

### totalSupply


```solidity
function totalSupply() external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address who) external view returns (uint256);
```

### allowance


```solidity
function allowance(address owner, address spender) external view returns (uint256);
```

### transfer


```solidity
function transfer(address to, uint256 value) external nonReentrant returns (bool);
```

### approve


```solidity
function approve(address spender, uint256 value) external returns (bool);
```

### increaseAllowance


```solidity
function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
```

### decreaseAllowance


```solidity
function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
```

### transferFrom


```solidity
function transferFrom(address from, address to, uint256 value) external nonReentrant returns (bool);
```

### permit


```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
    external;
```

### DOMAIN_SEPARATOR


```solidity
function DOMAIN_SEPARATOR() public view virtual returns (bytes32);
```

### computeDomainSeparator


```solidity
function computeDomainSeparator() internal view virtual returns (bytes32);
```

