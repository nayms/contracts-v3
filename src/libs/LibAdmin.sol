// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AppStorage, FunctionLockedStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { Entity, OnboardingApproval } from "../shared/FreeStructs.sol";
import { LibConstants as LC } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibERC20 } from "./LibERC20.sol";
import { LibEntity } from "./LibEntity.sol";
import { LibACL } from "./LibACL.sol";
import { LibEIP712 } from "./LibEIP712.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// prettier-ignore
import {
    CannotSupportExternalTokenWithMoreThan18Decimals,
    ObjectTokenSymbolAlreadyInUse,
    MinimumSellCannotBeZero,
    EntityOnboardingNotApproved,
    InvalidSelfOnboardRoleApproval,
    InvalidSignatureError,
    InvalidSignatureSError,
    InvalidSignatureLength
} from "../shared/CustomErrors.sol";

import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";

library LibAdmin {
    using ECDSA for bytes32;

    event MaxDividendDenominationsUpdated(uint8 oldMax, uint8 newMax);
    event SupportedTokenAdded(address indexed tokenAddress);
    event FunctionsLocked(bytes4[] functionSelectors);
    event FunctionsUnlocked(bytes4[] functionSelectors);
    event SelfOnboardingCompleted(address indexed userAddress);

    /// @notice The minimum amount of an object (par token, external token) that can be sold on the market
    event MinimumSellUpdated(bytes32 objectId, uint256 minimumSell);

    function _getSystemId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LC.SYSTEM_IDENTIFIER);
    }

    function _updateMaxDividendDenominations(uint8 _newMaxDividendDenominations) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint8 old = s.maxDividendDenominations;
        require(_newMaxDividendDenominations > old, "_updateMaxDividendDenominations: cannot reduce");
        s.maxDividendDenominations = _newMaxDividendDenominations;

        emit MaxDividendDenominationsUpdated(old, _newMaxDividendDenominations);
    }

    function _getMaxDividendDenominations() internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.maxDividendDenominations;
    }

    function _isSupportedExternalTokenAddress(address _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.externalTokenSupported[_tokenId];
    }

    function _isSupportedExternalToken(bytes32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return LibHelpers._isAddress(_tokenId) && s.externalTokenSupported[LibHelpers._getAddressFromId(_tokenId)];
    }

    function _addSupportedExternalToken(address _tokenAddress, uint256 _minimumSell) internal {
        if (LibERC20.decimals(_tokenAddress) > 18) {
            revert CannotSupportExternalTokenWithMoreThan18Decimals();
        }
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(!s.externalTokenSupported[_tokenAddress], "external token already added");
        require(s.objectTokenWrapperId[_tokenAddress] == bytes32(0), "cannot add participation token wrapper as external");

        if (_minimumSell == 0) revert MinimumSellCannotBeZero();

        string memory symbol = LibERC20.symbol(_tokenAddress);
        if (s.tokenSymbolObjectId[symbol] != bytes32(0)) {
            revert ObjectTokenSymbolAlreadyInUse(LibHelpers._getIdForAddress(_tokenAddress), symbol);
        }

        s.externalTokenSupported[_tokenAddress] = true;
        bytes32 tokenId = LibHelpers._getIdForAddress(_tokenAddress);
        LibObject._createObject(tokenId, LC.OBJECT_TYPE_ADDRESS);
        s.supportedExternalTokens.push(_tokenAddress);
        s.tokenSymbolObjectId[symbol] = tokenId;
        s.objectMinimumSell[tokenId] = _minimumSell;

        emit SupportedTokenAdded(_tokenAddress);
        emit MinimumSellUpdated(tokenId, _minimumSell);
    }

    function _getSupportedExternalTokens() internal view returns (address[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Supported tokens cannot be removed because they may exist in the system!
        return s.supportedExternalTokens;
    }

    function _lockFunction(bytes4 functionSelector) internal {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        s.locked[functionSelector] = true;

        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = functionSelector;
        emit FunctionsLocked(functionSelectors);
    }

    function _unlockFunction(bytes4 functionSelector) internal {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        s.locked[functionSelector] = false;

        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = functionSelector;
        emit FunctionsUnlocked(functionSelectors);
    }

    function _isFunctionLocked(bytes4 functionSelector) internal view returns (bool) {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        return s.locked[functionSelector];
    }

    function _lockAllFundTransferFunctions() internal {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        s.locked[IDiamondProxy.startTokenSale.selector] = true;
        s.locked[IDiamondProxy.paySimpleClaim.selector] = true;
        s.locked[IDiamondProxy.paySimplePremium.selector] = true;
        s.locked[IDiamondProxy.checkAndUpdateSimplePolicyState.selector] = true;
        s.locked[IDiamondProxy.cancelOffer.selector] = true;
        s.locked[IDiamondProxy.executeLimitOffer.selector] = true;
        s.locked[IDiamondProxy.internalTransferFromEntity.selector] = true;
        s.locked[IDiamondProxy.payDividendFromEntity.selector] = true;
        s.locked[IDiamondProxy.internalBurn.selector] = true;
        s.locked[IDiamondProxy.wrapperInternalTransferFrom.selector] = true;
        s.locked[IDiamondProxy.withdrawDividend.selector] = true;
        s.locked[IDiamondProxy.withdrawAllDividends.selector] = true;
        s.locked[IDiamondProxy.externalWithdrawFromEntity.selector] = true;
        s.locked[IDiamondProxy.externalDeposit.selector] = true;
        s.locked[IDiamondProxy.stake.selector] = true;
        s.locked[IDiamondProxy.unstake.selector] = true;
        s.locked[IDiamondProxy.collectRewards.selector] = true;
        s.locked[IDiamondProxy.collectRewardsToInterval.selector] = true;
        s.locked[IDiamondProxy.payReward.selector] = true;
        s.locked[IDiamondProxy.cancelSimplePolicy.selector] = true;
        s.locked[IDiamondProxy.createSimplePolicy.selector] = true;
        s.locked[IDiamondProxy.createEntity.selector] = true;
        s.locked[IDiamondProxy.compoundRewards.selector] = true;

        bytes4[] memory lockedFunctions = new bytes4[](23);
        lockedFunctions[0] = IDiamondProxy.startTokenSale.selector;
        lockedFunctions[1] = IDiamondProxy.paySimpleClaim.selector;
        lockedFunctions[2] = IDiamondProxy.paySimplePremium.selector;
        lockedFunctions[3] = IDiamondProxy.checkAndUpdateSimplePolicyState.selector;
        lockedFunctions[4] = IDiamondProxy.cancelOffer.selector;
        lockedFunctions[5] = IDiamondProxy.executeLimitOffer.selector;
        lockedFunctions[6] = IDiamondProxy.internalTransferFromEntity.selector;
        lockedFunctions[7] = IDiamondProxy.payDividendFromEntity.selector;
        lockedFunctions[8] = IDiamondProxy.internalBurn.selector;
        lockedFunctions[9] = IDiamondProxy.wrapperInternalTransferFrom.selector;
        lockedFunctions[10] = IDiamondProxy.withdrawDividend.selector;
        lockedFunctions[11] = IDiamondProxy.withdrawAllDividends.selector;
        lockedFunctions[12] = IDiamondProxy.externalWithdrawFromEntity.selector;
        lockedFunctions[13] = IDiamondProxy.externalDeposit.selector;
        lockedFunctions[14] = IDiamondProxy.stake.selector;
        lockedFunctions[15] = IDiamondProxy.unstake.selector;
        lockedFunctions[16] = IDiamondProxy.collectRewards.selector;
        lockedFunctions[17] = IDiamondProxy.payReward.selector;
        lockedFunctions[18] = IDiamondProxy.cancelSimplePolicy.selector;
        lockedFunctions[19] = IDiamondProxy.createSimplePolicy.selector;
        lockedFunctions[20] = IDiamondProxy.createEntity.selector;
        lockedFunctions[21] = IDiamondProxy.collectRewardsToInterval.selector;
        lockedFunctions[22] = IDiamondProxy.compoundRewards.selector;

        emit FunctionsLocked(lockedFunctions);
    }

    function _unlockAllFundTransferFunctions() internal {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        s.locked[IDiamondProxy.startTokenSale.selector] = false;
        s.locked[IDiamondProxy.paySimpleClaim.selector] = false;
        s.locked[IDiamondProxy.paySimplePremium.selector] = false;
        s.locked[IDiamondProxy.checkAndUpdateSimplePolicyState.selector] = false;
        s.locked[IDiamondProxy.cancelOffer.selector] = false;
        s.locked[IDiamondProxy.executeLimitOffer.selector] = false;
        s.locked[IDiamondProxy.internalTransferFromEntity.selector] = false;
        s.locked[IDiamondProxy.payDividendFromEntity.selector] = false;
        s.locked[IDiamondProxy.internalBurn.selector] = false;
        s.locked[IDiamondProxy.wrapperInternalTransferFrom.selector] = false;
        s.locked[IDiamondProxy.withdrawDividend.selector] = false;
        s.locked[IDiamondProxy.withdrawAllDividends.selector] = false;
        s.locked[IDiamondProxy.externalWithdrawFromEntity.selector] = false;
        s.locked[IDiamondProxy.externalDeposit.selector] = false;
        s.locked[IDiamondProxy.stake.selector] = false;
        s.locked[IDiamondProxy.unstake.selector] = false;
        s.locked[IDiamondProxy.collectRewards.selector] = false;
        s.locked[IDiamondProxy.payReward.selector] = false;
        s.locked[IDiamondProxy.cancelSimplePolicy.selector] = false;
        s.locked[IDiamondProxy.createSimplePolicy.selector] = false;
        s.locked[IDiamondProxy.createEntity.selector] = false;
        s.locked[IDiamondProxy.collectRewardsToInterval.selector] = false;
        s.locked[IDiamondProxy.compoundRewards.selector] = false;

        bytes4[] memory lockedFunctions = new bytes4[](23);
        lockedFunctions[0] = IDiamondProxy.startTokenSale.selector;
        lockedFunctions[1] = IDiamondProxy.paySimpleClaim.selector;
        lockedFunctions[2] = IDiamondProxy.paySimplePremium.selector;
        lockedFunctions[3] = IDiamondProxy.checkAndUpdateSimplePolicyState.selector;
        lockedFunctions[4] = IDiamondProxy.cancelOffer.selector;
        lockedFunctions[5] = IDiamondProxy.executeLimitOffer.selector;
        lockedFunctions[6] = IDiamondProxy.internalTransferFromEntity.selector;
        lockedFunctions[7] = IDiamondProxy.payDividendFromEntity.selector;
        lockedFunctions[8] = IDiamondProxy.internalBurn.selector;
        lockedFunctions[9] = IDiamondProxy.wrapperInternalTransferFrom.selector;
        lockedFunctions[10] = IDiamondProxy.withdrawDividend.selector;
        lockedFunctions[11] = IDiamondProxy.withdrawAllDividends.selector;
        lockedFunctions[12] = IDiamondProxy.externalWithdrawFromEntity.selector;
        lockedFunctions[13] = IDiamondProxy.externalDeposit.selector;
        lockedFunctions[14] = IDiamondProxy.stake.selector;
        lockedFunctions[15] = IDiamondProxy.unstake.selector;
        lockedFunctions[16] = IDiamondProxy.collectRewards.selector;
        lockedFunctions[17] = IDiamondProxy.payReward.selector;
        lockedFunctions[18] = IDiamondProxy.cancelSimplePolicy.selector;
        lockedFunctions[19] = IDiamondProxy.createSimplePolicy.selector;
        lockedFunctions[20] = IDiamondProxy.createEntity.selector;
        lockedFunctions[21] = IDiamondProxy.collectRewardsToInterval.selector;
        lockedFunctions[22] = IDiamondProxy.compoundRewards.selector;

        emit FunctionsUnlocked(lockedFunctions);
    }

    function _onboardUserViaSignature(OnboardingApproval memory _approval) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        address userAddress = msg.sender;

        bytes32 entityId = _approval.entityId;
        bytes32 roleId = _approval.roleId;
        bytes memory sig = _approval.signature;

        if (entityId == 0 || roleId == 0 || sig.length == 0) revert EntityOnboardingNotApproved(userAddress);

        bool isTokenHolder = roleId == LibHelpers._stringToBytes32(LC.ROLE_ENTITY_TOKEN_HOLDER);
        bool isCapitalProvider = roleId == LibHelpers._stringToBytes32(LC.ROLE_ENTITY_CP);
        if (!isTokenHolder && !isCapitalProvider) {
            revert InvalidSelfOnboardRoleApproval(roleId);
        }

        bytes32 signingHash = _getOnboardingHash(userAddress, entityId, roleId);
        bytes32 signerId = LibHelpers._getIdForAddress(_getSigner(signingHash, sig));

        if (!LibACL._isInGroup(signerId, LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LC.GROUP_ONBOARDING_APPROVERS))) {
            revert EntityOnboardingNotApproved(userAddress);
        }

        if (!s.existingEntities[entityId]) {
            Entity memory entity;
            bytes32 userId = LibHelpers._getIdForAddress(userAddress);
            LibEntity._createEntity(entityId, userId, entity, 0);
        }

        if (s.roles[entityId][LibAdmin._getSystemId()] != 0) {
            LibACL._unassignRole(entityId, LibAdmin._getSystemId());
        }
        LibACL._assignRole(entityId, LibAdmin._getSystemId(), roleId);

        emit SelfOnboardingCompleted(userAddress);
    }

    function _setMinimumSell(bytes32 _objectId, uint256 _minimumSell) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (_minimumSell == 0) revert MinimumSellCannotBeZero();

        s.objectMinimumSell[_objectId] = _minimumSell;

        emit MinimumSellUpdated(_objectId, _minimumSell);
    }

    function _getOnboardingHash(address _userAddress, bytes32 _entityId, bytes32 _roleId) internal view returns (bytes32) {
        return
            LibEIP712._hashTypedDataV4(
                keccak256(abi.encode(keccak256("OnboardingApproval(address _userAddress,bytes32 _entityId,bytes32 _roleId)"), _userAddress, _entityId, _roleId))
            );
    }

    function _getSigner(bytes32 signingHash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        if (signature.length != 65) {
            revert InvalidSignatureLength();
        }

        // currently is to use assembly.
        /// @solidity memory-safe-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))

            switch v
            // if v == 0, then v = 27
            case 0 {
                v := 27
            }
            // if v == 1, then v = 28
            case 1 {
                v := 28
            }
        }

        (address signer, ECDSA.RecoverError err, ) = ECDSA.tryRecover(MessageHashUtils.toEthSignedMessageHash(signingHash), v, r, s);

        if (err == ECDSA.RecoverError.InvalidSignature) revert InvalidSignatureError(signingHash);
        else if (err == ECDSA.RecoverError.InvalidSignatureS) revert InvalidSignatureSError(s);

        return signer;
    }
}
