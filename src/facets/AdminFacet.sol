// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { OnboardingApproval } from "../shared/FreeStructs.sol";
import { Modifiers } from "../shared/Modifiers.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibConstants as LC } from "../libs/LibConstants.sol";
import { LibFeeRouter } from "../libs/LibFeeRouter.sol";

/**
 * @title Administration
 * @notice Exposes methods that require administrative privileges
 * @dev Use it to configure various core parameters
 */
contract AdminFacet is Modifiers {
    /**
     * @notice Set `_newMax` as the max dividend denominations value.
     * @param _newMax new value to be used.
     */
    function setMaxDividendDenominations(uint8 _newMax) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibAdmin._updateMaxDividendDenominations(_newMax);
    }

    /**
     * @notice Get the max dividend denominations value
     * @return max dividend denominations
     */
    function getMaxDividendDenominations() external view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.maxDividendDenominations;
    }

    /**
     * @notice Is the specified tokenId an external ERC20 that is supported by the Nayms platform?
     * @param _tokenId token address converted to bytes32
     * @return whether token is supported or not
     */
    function isSupportedExternalToken(bytes32 _tokenId) external view returns (bool) {
        return LibAdmin._isSupportedExternalToken(_tokenId);
    }

    /**
     * @notice Add another token to the supported tokens list
     * @param _tokenAddress address of the token to support
     * @param _minimumSell minimum amount of tokens that can be sold on the marketplace
     */
    function addSupportedExternalToken(address _tokenAddress, uint256 _minimumSell) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibAdmin._addSupportedExternalToken(_tokenAddress, _minimumSell);
    }

    /**
     * @notice Get the supported tokens list as an array
     * @return array containing address of all supported tokens
     */
    function getSupportedExternalTokens() external view returns (address[] memory) {
        return LibAdmin._getSupportedExternalTokens();
    }

    /**
     * @notice Gets the System context ID.
     * @return System Identifier
     */
    function getSystemId() external pure returns (bytes32) {
        return LibAdmin._getSystemId();
    }

    /**
     * @notice Check if object can be tokenized
     * @param _objectId ID of the object
     */
    function isObjectTokenizable(bytes32 _objectId) external view returns (bool) {
        return LibObject._isObjectTokenizable(_objectId);
    }

    /**
     * @notice System Admin can lock a function
     * @dev This toggles FunctionLockedStorage.lock to true
     * @param functionSelector the bytes4 function selector
     */
    function lockFunction(bytes4 functionSelector) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibAdmin._lockFunction(functionSelector);
    }

    /**
     * @notice System Admin can unlock a function
     * @dev This toggles FunctionLockedStorage.lock to false
     * @param functionSelector the bytes4 function selector
     */
    function unlockFunction(bytes4 functionSelector) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibAdmin._unlockFunction(functionSelector);
    }

    /**
     * @notice Check if a function has been locked by a system admin
     * @dev This views FunctionLockedStorage.lock
     * @param functionSelector the bytes4 function selector
     */
    function isFunctionLocked(bytes4 functionSelector) external view returns (bool) {
        return LibAdmin._isFunctionLocked(functionSelector);
    }

    /**
     * @notice Lock all contract methods involving fund transfers
     */
    function lockAllFundTransferFunctions() external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibAdmin._lockAllFundTransferFunctions();
    }

    /**
     * @notice Unlock all contract methods involving fund transfers
     */
    function unlockAllFundTransferFunctions() external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibAdmin._unlockAllFundTransferFunctions();
    }

    /**
     * @notice Update market maker fee basis points
     * @param _newMakerBP new maker fee value
     */
    function replaceMakerBP(uint16 _newMakerBP) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibFeeRouter._replaceMakerBP(_newMakerBP);
    }

    /**
     * @notice Add or update an existing fee schedule
     * @param _entityId object ID for which the fee schedule is being set, use system ID for global fee schedule
     * @param _feeScheduleType fee schedule type (premiums, trading, inital sale)
     * @param _receiver array of fee recipient IDs
     * @param _basisPoints array of basis points for each of the fee receivers
     */
    function addFeeSchedule(
        bytes32 _entityId,
        uint256 _feeScheduleType,
        bytes32[] calldata _receiver,
        uint16[] calldata _basisPoints
    ) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibFeeRouter._addFeeSchedule(_entityId, _feeScheduleType, _receiver, _basisPoints);
    }

    /**
     * @notice remove a fee schedule
     * @param _entityId object ID for which the fee schedule is being removed
     * @param _feeScheduleType type of fee schedule
     */
    function removeFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibFeeRouter._removeFeeSchedule(_entityId, _feeScheduleType);
    }

    /**
     * @notice Create a token holder entity for a user account
     * @param _onboardingApproval onboarding approval parameters, includes user address, entity ID and role ID
     */
    function onboardViaSignature(OnboardingApproval calldata _onboardingApproval) external {
        LibAdmin._onboardUserViaSignature(_onboardingApproval);
    }

    /**
     * @notice Hash to be signed by the onboarding approver
     * @param _userAddress Address being approved to onboard
     * @param _entityId Entity ID being approved for onboarding
     * @param _roleId Role being apprved for onboarding
     */
    function getOnboardingHash(address _userAddress, bytes32 _entityId, bytes32 _roleId) external view returns (bytes32) {
        return LibAdmin._getOnboardingHash(_userAddress, _entityId, _roleId);
    }
}
