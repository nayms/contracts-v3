// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @dev The Nayms Diamond (proxy contract) owner (address) must be mutually exclusive with the system admin role.
error OwnerCannotBeSystemAdmin();

/// @dev Passing in a missing role when trying to assign a role.
error RoleIsMissing();

/// @dev Passing in a missing group when trying to assign a role to a group.
error AssignerGroupIsMissing();

/// @dev Role assigner (msg.sender) must be in the assigners group to unassign a role.
/// @param assigner Id of the role assigner, LibHelpers._getIdForAddress(msg sender)
/// @param assignee ObjectId that the role is being assigned to
/// @param context Context that the role is being assigned in
/// @param roleInContext Role that is being assigned
error AssignerCannotUnassignRole(bytes32 assigner, bytes32 assignee, bytes32 context, string roleInContext);

/// @notice Error message for when a sender is not authorized to perform an action with their assigned role in a given context of a group
/// @dev In the assertPrivilege modifier, this error message returns the context and the role in the context, not the user's role in the system context.
/// @param msgSenderId Id of the sender
/// @param context Context in which the sender is trying to perform an action
/// @param roleInContext Role of the sender in the context
/// @param group Group to check the sender's role in
error InvalidGroupPrivilege(bytes32 msgSenderId, bytes32 context, string roleInContext, string group);

/// @notice only Token Holder or Capital Provider should be approved for self-onboarding
/// @param role The name of the rle which should not be approaved for self-onboarding
error InvalidSelfOnboardRoleApproval(bytes32 role);

/// @dev Cannot add a ERC20 token to the supported external token list that has more than 18 decimal places.
error CannotSupportExternalTokenWithMoreThan18Decimals();

/// @dev Object exsists when it should not.
error ObjectExistsAlready(bytes32 objectId);

/// @dev Object does not exsit when it should.
error ObjectDoesNotExist(bytes32 objectId);

/// @dev The entity does not exist when it should.
error EntityDoesNotExist(bytes32 objectId);

/// @dev The entity self onboarding not approved
error EntityOnboardingNotApproved(address userAddress);

/// @dev Cannot create an entity that already exists.
error EntityExistsAlready(bytes32 entityId);

/// @dev The object type is not supported in this function call.
error InvalidObjectType(bytes32 objectId, bytes12 objectType);

/// @dev The object ID being passed in is expected to be an address type, but the bottom (least significant) 12 bytes are not empty.
error InvalidObjectIdForAddress(bytes32 objectId);

/// @dev (non specific) the object is not enabled to be tokenized.
error ObjectCannotBeTokenized(bytes32 objectId);

/// @dev Provided token symbol is not valid.
error ObjectTokenSymbolInvalid(bytes32 objectId, string symbol);

/// @dev Provided token symbol is already being used.
error ObjectTokenSymbolAlreadyInUse(bytes32 objectId, string symbol);

/// @dev Provided token name is not valid.
error ObjectTokenNameInvalid(bytes32 objectId, string symbol);

/// @dev Passing in 0 amount for deposits is not allowed.
error ExternalDepositAmountCannotBeZero();

/// @dev Passing in 0 amount for withdraws is not allowed.
error ExternalWithdrawAmountCannotBeZero();

/// @dev The receiver of the withdraw must haveGroupPriviledge with the roles entity admin, comptroller combined, or comptroller withdraw.
error ExternalWithdrawInvalidReceiver(address receiver);

/// @dev Cannot create a simple policy with policyId of 0
error PolicyIdCannotBeZero();

/// @dev Policy commissions among commission receivers cannot sum to be greater than 10_000 basis points.
error PolicyCommissionsBasisPointsCannotBeGreaterThan10000(uint256 calculatedTotalBp);

/// @dev The total basis points for a fee schedule, policy fee receivers at policy creation, or maker bp cannot be greater than half of LibConstants.BP_FACTOR.
///     This is to prevent the total basis points of a fee schedule with additional fee receivers (policy fee receivers for fee payments on premiums) from being greater than 100%.
error FeeBasisPointsExceedHalfMax(uint256 actual, uint256 expected);

/// @dev The total fees can never exceed the premium payment or the marketplace trade.
error FeeBasisPointsExceedMax(uint256 actual, uint256 expected);

/// @dev When validating an entity, the utilized capacity cannot be greater than the max capacity.
error UtilizedCapacityGreaterThanMaxCapacity(uint256 utilizedCapacity, uint256 maxCapacity);

/// @dev Policy stakeholder signature validation failed
error SimplePolicyStakeholderSignatureInvalid(bytes32 signingHash, bytes signature, bytes32 signerId, bytes32 signersParent, bytes32 entityId);

/// @dev When creating a simple policy, the total claims paid should start at 0.
error SimplePolicyClaimsPaidShouldStartAtZero();

/// @dev When creating a simple policy, the total premiums paid should start at 0.
error SimplePolicyPremiumsPaidShouldStartAtZero();

/// @dev The cancel bool should not be set to true when creating a new simple policy.
error CancelCannotBeTrueWhenCreatingSimplePolicy();

/// @dev (non specific) The policyId must exist.
error PolicyDoesNotExist(bytes32 policyId);

/// @dev It is not possible to cancel policyId after maturation date has passed
error PolicyCannotCancelAfterMaturation(bytes32 policyId);

/// @dev There is a duplicate address in the list of signers (the previous signer in the list is not < the next signer in the list).
error DuplicateSignerCreatingSimplePolicy(address previousSigner, address nextSigner);

/// @dev The minimum sell amount on the marketplace cannot be zero.
error MinimumSellCannotBeZero();

/// @dev Rebasing interest tracking data has not been initialized yet.
error RebasingInterestNotInitialized(bytes32 tokenId);

/// @dev Insufficient amount of interest acrrued so far
error RebasingInterestInsufficient(bytes32 tokenId, uint256 amount, uint256 accruedAmount);

/// @dev Staking can be initialized only once
error StakingAlreadyStarted(bytes32 entityId, bytes32 tokenId);

/// @dev Staking must be started
error StakingNotStarted(bytes32 entityId, bytes32 tokenId);

/// @dev Staking must be enabled
error StakingConfigDoesNotExist(bytes32 entityId);

/// @dev Invalid A parameter value provided
error InvalidAValue();

/// @dev Invalid R parameter value provided
error InvalidRValue();

/// @dev Invalid divider parameter value provided
error InvalidDividerValue();

/// @dev Invalid interval value provided
error InvalidIntervalSecondsValue();

/// @dev Invalid staking start date provided
error InvalidStakingInitDate();

/// @dev staking entity itself should not be allowed to stake
error InvalidStaker(bytes32 entityId);

/// @dev Only one reward payment is allowed per interval
error IntervalRewardPayedOutAlready(uint64 interval);

/// @dev Token reward must be greater than minimum sell amount for the reward token
error InvalidTokenRewardAmount(bytes32 guid, bytes32 entityId, bytes32 rewardTokenId, uint256 rewardAmount);

/// @dev Insuficient balance available to perform the transfer of funds
error InsufficientBalance(bytes32 tokenId, bytes32 from, uint256 balance, uint256 amount);

/// @dev Cannot unassign the role from the sender
error CannotUnassignRoleFromSelf(string role);

/// @dev The account of rebasing tokens held by Nayms is greater than the account of rebasing tokens held by the rebasing contract
error RebasingSupplyDecreased(bytes32 tokenId, uint256 accountInNayms, uint256 accountInRebasingContract);

/// @dev This error is used to indicate that the signature could not be verified.
/// @param hash The hash of the message that was signed.
/// @notice This error suggests that the signature itself is malformed or does not correspond to the hash provided.
error InvalidSignatureError(bytes32 hash);

/// @dev This error is used to indicate that the signature has an invalid 's' value.
/// @param sValue The 's' value of the ECDSA signature that was deemed invalid.
/// @notice This error is triggered when the 's' value of the signature is not within the lower half of the secp256k1 curve's order, which can lead to malleability issues.
error InvalidSignatureSError(bytes32 sValue);

/// @dev Thrown when the number of receivers specified in a transaction is not within the acceptable range.
error InvalidReceiverCount(uint256 numberOfReceivers);

/// @dev Thrown when the maturation date of a policy is set beyond the allowable future date limit.
/// This prevents setting unrealistic maturation dates that could affect the contract's operability or the enforceability of the policy.
error MaturationDateTooFar(uint256 maturationDate);

/// @dev Thrown when the number of commission receivers for a policy exceeds the system's maximum limit.
/// This limit is enforced to prevent out-of-gas errors during commission payouts, ensuring the system remains functional and efficient.
error ExcessiveCommissionReceivers(uint256 numberOfReceivers, uint256 maxReceivers);

/// @dev Thrown when the initialization date for staking is set too far in the future, beyond the system-defined maximum limit.
error InitDateTooFar(uint256 initDate);

/// @dev Thrown when the staking interval is set outside the allowed range, either too short or too long, as defined by system limits.
error IntervalOutOfRange(uint256 interval);

/// @dev Thrown when the sum of parameters 'a' and 'r' does not equal the 'divider', which is necessary for the boost multiplier to asymptotically converge to 2.
error BoostDividerNotEqualError(uint256 a, uint256 r, uint256 divider);

/// @dev This internal token ID is invalid for the given context.
error InvalidTokenId();

/// @dev Cannot stake an amount lower than objectMinimumSell[tokenId].
error InvalidStakingAmount();
