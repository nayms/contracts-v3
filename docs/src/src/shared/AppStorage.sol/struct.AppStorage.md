# AppStorage
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/AppStorage.sol)

storage for nayms v3 decentralized insurance platform


```solidity
struct AppStorage {
    bool diamondInitialized;
    uint256 initialChainId;
    bytes32 initialDomainSeparator;
    uint256 reentrancyStatus;
    string name;
    mapping(address account => mapping(address spender => uint256)) allowance;
    uint256 totalSupply;
    mapping(bytes32 objectId => bool isInternalToken) internalToken;
    mapping(address account => uint256) balances;
    mapping(bytes32 objectId => bool isObject) existingObjects;
    mapping(bytes32 objectId => bytes32 objectsParent) objectParent;
    mapping(bytes32 objectId => bytes32 objectsDataHash) objectDataHashes;
    mapping(bytes32 objectId => string tokenSymbol) objectTokenSymbol;
    mapping(bytes32 objectId => string tokenName) objectTokenName;
    mapping(bytes32 objectId => address tokenWrapperAddress) objectTokenWrapper;
    mapping(bytes32 entityId => bool isEntity) existingEntities;
    mapping(bytes32 policyId => bool isPolicy) existingSimplePolicies;
    mapping(bytes32 entityId => Entity) entities;
    mapping(bytes32 policyId => SimplePolicy) simplePolicies;
    mapping(address externalTokenAddress => bool isSupportedExternalToken) externalTokenSupported;
    address[] supportedExternalTokens;
    mapping(bytes32 tokenId => mapping(bytes32 ownerId => uint256)) tokenBalances;
    mapping(bytes32 tokenId => uint256) tokenSupply;
    uint8 maxDividendDenominations;
    mapping(bytes32 objectId => bytes32[]) dividendDenominations;
    mapping(bytes32 entityId => mapping(bytes32 tokenId => uint8 index)) dividendDenominationIndex;
    mapping(bytes32 entityId => mapping(uint8 index => bytes32 tokenId)) dividendDenominationAtIndex;
    mapping(bytes32 tokenId => mapping(bytes32 dividendDenominationId => uint256)) totalDividends;
    mapping(bytes32 entityId => mapping(bytes32 tokenId => mapping(bytes32 ownerId => uint256)))
        withdrawnDividendPerOwner;
    mapping(bytes32 roleId => mapping(bytes32 groupId => bool isRoleInGroup)) groups;
    mapping(bytes32 roleId => bytes32 assignerGroupId) canAssign;
    mapping(bytes32 objectId => mapping(bytes32 contextId => bytes32 roleId)) roles;
    uint256 lastOfferId;
    mapping(uint256 offerId => MarketInfo) offers;
    mapping(bytes32 sellTokenId => mapping(bytes32 buyTokenId => uint256)) bestOfferId;
    mapping(bytes32 sellTokenId => mapping(bytes32 buyTokenId => uint256)) span;
    address naymsToken;
    bytes32 naymsTokenId;
    uint16 tradingCommissionTotalBP;
    uint16 tradingCommissionNaymsLtdBP;
    uint16 tradingCommissionNDFBP;
    uint16 tradingCommissionSTMBP;
    uint16 tradingCommissionMakerBP;
    uint16 premiumCommissionNaymsLtdBP;
    uint16 premiumCommissionNDFBP;
    uint16 premiumCommissionSTMBP;
    mapping(bytes32 ownerId => mapping(bytes32 tokenId => uint256)) lockedBalances;
    mapping(bytes32 upgradeId => uint256 timestamp) upgradeScheduled;
    uint256 upgradeExpiration;
    uint256 sysAdmins;
    mapping(address tokenWrapperAddress => bytes32 tokenId) objectTokenWrapperId;
    mapping(string tokenSymbol => bytes32 objectId) tokenSymbolObjectId;
    mapping(bytes32 entityId => mapping(uint256 feeScheduleTypeId => FeeSchedule)) feeSchedules;
    mapping(bytes32 objectId => uint256 minimumSell) objectMinimumSell;
    mapping(address userAddress => EntityApproval) selfOnboarding;
    mapping(bytes32 entityId => StakingConfig) stakingConfigs;
    mapping(bytes32 vTokenId => mapping(bytes32 _stakerId => uint256 reward)) stakeBalance;
    mapping(bytes32 vTokenId => mapping(bytes32 _stakerId => uint256 boost)) stakeBoost;
    mapping(bytes32 entityId => mapping(bytes32 _stakerId => uint64 interval)) stakeCollected;
    mapping(bytes32 vTokenId => uint256 amount) stakingDistributionAmount;
    mapping(bytes32 vTokenId => bytes32 denomination) stakingDistributionDenomination;
}
```

