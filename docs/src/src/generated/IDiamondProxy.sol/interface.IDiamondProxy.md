# IDiamondProxy
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/generated/IDiamondProxy.sol)

**Inherits:**
[IERC173](/src/interfaces/IERC173.sol/interface.IERC173.md), [IERC165](/src/interfaces/IERC165.sol/interface.IERC165.md), IDiamondCut, IDiamondLoupe

------------------------------------------------------------------------------------------------------------
NOTE: This file is auto-generated by Gemforge.
------------------------------------------------------------------------------------------------------------


## Functions
### assignRole


```solidity
function assignRole(bytes32 _objectId, bytes32 _contextId, string memory _role) external;
```

### unassignRole


```solidity
function unassignRole(bytes32 _objectId, bytes32 _contextId) external;
```

### isInGroup


```solidity
function isInGroup(bytes32 _objectId, bytes32 _contextId, string memory _group) external view returns (bool);
```

### isParentInGroup


```solidity
function isParentInGroup(bytes32 _objectId, bytes32 _contextId, string memory _group) external view returns (bool);
```

### canAssign


```solidity
function canAssign(bytes32 _assignerId, bytes32 _objectId, bytes32 _contextId, string memory _role)
    external
    view
    returns (bool);
```

### hasGroupPrivilege


```solidity
function hasGroupPrivilege(bytes32 _userId, bytes32 _contextId, bytes32 _groupId) external view returns (bool);
```

### getRoleInContext


```solidity
function getRoleInContext(bytes32 objectId, bytes32 contextId) external view returns (bytes32);
```

### isRoleInGroup


```solidity
function isRoleInGroup(string memory role, string memory group) external view returns (bool);
```

### canGroupAssignRole


```solidity
function canGroupAssignRole(string memory role, string memory group) external view returns (bool);
```

### updateRoleAssigner


```solidity
function updateRoleAssigner(string memory _role, string memory _assignerGroup) external;
```

### updateRoleGroup


```solidity
function updateRoleGroup(string memory _role, string memory _group, bool _roleInGroup) external;
```

### setMaxDividendDenominations


```solidity
function setMaxDividendDenominations(uint8 _newMax) external;
```

### getMaxDividendDenominations


```solidity
function getMaxDividendDenominations() external view returns (uint8);
```

### isSupportedExternalToken


```solidity
function isSupportedExternalToken(bytes32 _tokenId) external view returns (bool);
```

### addSupportedExternalToken


```solidity
function addSupportedExternalToken(address _tokenAddress, uint256 _minimumSell) external;
```

### getSupportedExternalTokens


```solidity
function getSupportedExternalTokens() external view returns (address[] memory);
```

### getSystemId


```solidity
function getSystemId() external pure returns (bytes32);
```

### isObjectTokenizable


```solidity
function isObjectTokenizable(bytes32 _objectId) external view returns (bool);
```

### lockFunction


```solidity
function lockFunction(bytes4 functionSelector) external;
```

### unlockFunction


```solidity
function unlockFunction(bytes4 functionSelector) external;
```

### isFunctionLocked


```solidity
function isFunctionLocked(bytes4 functionSelector) external view returns (bool);
```

### lockAllFundTransferFunctions


```solidity
function lockAllFundTransferFunctions() external;
```

### unlockAllFundTransferFunctions


```solidity
function unlockAllFundTransferFunctions() external;
```

### replaceMakerBP


```solidity
function replaceMakerBP(uint16 _newMakerBP) external;
```

### addFeeSchedule


```solidity
function addFeeSchedule(
    bytes32 _entityId,
    uint256 _feeScheduleType,
    bytes32[] calldata _receiver,
    uint16[] calldata _basisPoints
) external;
```

### removeFeeSchedule


```solidity
function removeFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType) external;
```

### domainSeparatorV4


```solidity
function domainSeparatorV4() external view returns (bytes32);
```

### hashTypedDataV4


```solidity
function hashTypedDataV4(bytes32 structHash) external view returns (bytes32);
```

### createSimplePolicy


```solidity
function createSimplePolicy(
    bytes32 _policyId,
    bytes32 _entityId,
    Stakeholders calldata _stakeholders,
    SimplePolicy calldata _simplePolicy,
    bytes32 _dataHash
) external;
```

### enableEntityTokenization


```solidity
function enableEntityTokenization(bytes32 _objectId, string memory _symbol, string memory _name, uint256 _minimumSell)
    external;
```

### updateEntityTokenInfo


```solidity
function updateEntityTokenInfo(bytes32 _entityId, string memory _symbol, string memory _name) external;
```

### startTokenSale


```solidity
function startTokenSale(bytes32 _entityId, uint256 _amount, uint256 _totalPrice) external;
```

### isTokenWrapped


```solidity
function isTokenWrapped(bytes32 _entityId) external view returns (bool);
```

### updateEntity


```solidity
function updateEntity(bytes32 _entityId, Entity calldata _updateEntity) external;
```

### getEntityInfo


```solidity
function getEntityInfo(bytes32 _entityId) external view returns (Entity memory);
```

### getFeeSchedule


```solidity
function getFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType) external view returns (FeeSchedule memory);
```

### getObjectTokenSymbol


```solidity
function getObjectTokenSymbol(bytes32 _objectId) external view returns (string memory);
```

### isDiamondInitialized


```solidity
function isDiamondInitialized() external view returns (bool);
```

### calculateUpgradeId


```solidity
function calculateUpgradeId(IDiamondCut.FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata)
    external
    pure
    returns (bytes32);
```

### createUpgrade


```solidity
function createUpgrade(bytes32 id) external;
```

### updateUpgradeExpiration


```solidity
function updateUpgradeExpiration(uint256 duration) external;
```

### cancelUpgrade


```solidity
function cancelUpgrade(bytes32 id) external;
```

### getUpgrade


```solidity
function getUpgrade(bytes32 id) external view returns (uint256 expiry);
```

### getUpgradeExpiration


```solidity
function getUpgradeExpiration() external view returns (uint256 upgradeExpiration);
```

### cancelOffer


```solidity
function cancelOffer(uint256 _offerId) external;
```

### executeLimitOffer


```solidity
function executeLimitOffer(bytes32 _sellToken, uint256 _sellAmount, bytes32 _buyToken, uint256 _buyAmount)
    external
    returns (uint256 offerId_, uint256 buyTokenCommissionsPaid_, uint256 sellTokenCommissionsPaid_);
```

### getLastOfferId


```solidity
function getLastOfferId() external view returns (uint256);
```

### getBestOfferId


```solidity
function getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) external view returns (uint256);
```

### getOffer


```solidity
function getOffer(uint256 _offerId) external view returns (MarketInfo memory _offerState);
```

### isActiveOffer


```solidity
function isActiveOffer(uint256 _offerId) external view returns (bool);
```

### calculateTradingFees


```solidity
function calculateTradingFees(bytes32 _buyerId, bytes32 _sellToken, bytes32 _buyToken, uint256 _buyAmount)
    external
    view
    returns (uint256 totalFees_, uint256 totalBP_);
```

### getMakerBP


```solidity
function getMakerBP() external view returns (uint16);
```

### objectMinimumSell


```solidity
function objectMinimumSell(bytes32 _objectId) external view returns (uint256);
```

### setMinimumSell


```solidity
function setMinimumSell(bytes32 _objectId, uint256 _minimumSell) external;
```

### transferOwnership


```solidity
function transferOwnership(address _newOwner) external;
```

### owner


```solidity
function owner() external view returns (address owner_);
```

### totalSupply


```solidity
function totalSupply() external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address addr) external view returns (uint256);
```

### diamondCut


```solidity
function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
```

### paySimplePremium


```solidity
function paySimplePremium(bytes32 _policyId, uint256 _amount) external;
```

### paySimpleClaim


```solidity
function paySimpleClaim(bytes32 _claimId, bytes32 _policyId, bytes32 _insuredId, uint256 _amount) external;
```

### getSimplePolicyInfo


```solidity
function getSimplePolicyInfo(bytes32 _policyId) external view returns (SimplePolicyInfo memory);
```

### getPolicyCommissionReceivers


```solidity
function getPolicyCommissionReceivers(bytes32 _id) external view returns (bytes32[] memory commissionReceivers);
```

### checkAndUpdateSimplePolicyState


```solidity
function checkAndUpdateSimplePolicyState(bytes32 _policyId) external;
```

### cancelSimplePolicy


```solidity
function cancelSimplePolicy(bytes32 _policyId) external;
```

### getSigningHash


```solidity
function getSigningHash(
    uint256 _startDate,
    uint256 _maturationDate,
    bytes32 _asset,
    uint256 _limit,
    bytes32 _offchainDataHash
) external view returns (bytes32 signingHash_);
```

### calculatePremiumFees


```solidity
function calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid)
    external
    view
    returns (CalculatedFees memory cf);
```

### createEntity


```solidity
function createEntity(bytes32 _entityId, bytes32 _entityAdmin, Entity calldata _entityData, bytes32 _dataHash)
    external;
```

### stringToBytes32


```solidity
function stringToBytes32(string memory _strIn) external pure returns (bytes32 result);
```

### isObject


```solidity
function isObject(bytes32 _id) external view returns (bool);
```

### getObjectMeta


```solidity
function getObjectMeta(bytes32 _id)
    external
    view
    returns (bytes32 parent, bytes32 dataHash, string memory tokenSymbol, string memory tokenName, address tokenWrapper);
```

### wrapToken


```solidity
function wrapToken(bytes32 _objectId) external;
```

### getObjectType


```solidity
function getObjectType(bytes32 _objectId) external pure returns (bytes12);
```

### isObjectType


```solidity
function isObjectType(bytes32 _objectId, bytes12 _objectType) external pure returns (bool);
```

### internalBalanceOf


```solidity
function internalBalanceOf(bytes32 ownerId, bytes32 tokenId) external view returns (uint256);
```

### internalTokenSupply


```solidity
function internalTokenSupply(bytes32 tokenId) external view returns (uint256);
```

### internalTransferFromEntity


```solidity
function internalTransferFromEntity(bytes32 to, bytes32 tokenId, uint256 amount) external;
```

### wrapperInternalTransferFrom


```solidity
function wrapperInternalTransferFrom(bytes32 from, bytes32 to, bytes32 tokenId, uint256 amount) external;
```

### internalBurn


```solidity
function internalBurn(bytes32 from, bytes32 tokenId, uint256 amount) external;
```

### getWithdrawableDividend


```solidity
function getWithdrawableDividend(bytes32 ownerId, bytes32 tokenId, bytes32 dividendTokenId)
    external
    view
    returns (uint256);
```

### withdrawDividend


```solidity
function withdrawDividend(bytes32 ownerId, bytes32 tokenId, bytes32 dividendTokenId) external;
```

### withdrawAllDividends


```solidity
function withdrawAllDividends(bytes32 ownerId, bytes32 tokenId) external;
```

### payDividendFromEntity


```solidity
function payDividendFromEntity(bytes32 guid, uint256 amount) external;
```

### getLockedBalance


```solidity
function getLockedBalance(bytes32 _entityId, bytes32 _tokenId) external view returns (uint256 amount);
```

### internalTransferBySystemAdmin


```solidity
function internalTransferBySystemAdmin(bytes32 _fromEntityId, bytes32 _toEntityId, bytes32 _tokenId, uint256 _amount)
    external;
```

### totalDividends


```solidity
function totalDividends(bytes32 _tokenId, bytes32 _dividendDenominationId) external view returns (uint256);
```

### externalDeposit


```solidity
function externalDeposit(address _externalTokenAddress, uint256 _amount) external;
```

### externalWithdrawFromEntity


```solidity
function externalWithdrawFromEntity(
    bytes32 _entityId,
    address _receiver,
    address _externalTokenAddress,
    uint256 _amount
) external;
```

### getUserIdFromAddress


```solidity
function getUserIdFromAddress(address addr) external pure returns (bytes32 userId);
```

### getAddressFromExternalTokenId


```solidity
function getAddressFromExternalTokenId(bytes32 _externalTokenId) external pure returns (address tokenAddress);
```

### setEntity


```solidity
function setEntity(bytes32 _userId, bytes32 _entityId) external;
```

### getEntity


```solidity
function getEntity(bytes32 _userId) external view returns (bytes32 entityId);
```

