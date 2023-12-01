// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { Modifiers } from "../shared/Modifiers.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibConstants as LC } from "../libs/LibConstants.sol";
import { LibFeeRouter } from "../libs/LibFeeRouter.sol";
import { FeeSchedule } from "../shared/FreeStructs.sol";

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

    function isObjectTokenizable(bytes32 _objectId) external view returns (bool) {
        return LibObject._isObjectTokenizable(_objectId);
    }

    function lockFunction(bytes4 functionSelector) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibAdmin._lockFunction(functionSelector);
    }

    function unlockFunction(bytes4 functionSelector) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibAdmin._unlockFunction(functionSelector);
    }

    function isFunctionLocked(bytes4 functionSelector) external view returns (bool) {
        return LibAdmin._isFunctionLocked(functionSelector);
    }

    function lockAllFundTransferFunctions() external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibAdmin._lockAllFundTransferFunctions();
    }

    function unlockAllFundTransferFunctions() external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibAdmin._unlockAllFundTransferFunctions();
    }

    function replaceMakerBP(uint16 _newMakerBP) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibFeeRouter._replaceMakerBP(_newMakerBP);
    }

    function addFeeSchedule(
        bytes32 _entityId,
        uint256 _feeScheduleType,
        bytes32[] calldata _receiver,
        uint16[] calldata _basisPoints
    ) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibFeeRouter._addFeeSchedule(_entityId, _feeScheduleType, _receiver, _basisPoints);
    }

    function removeFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibFeeRouter._removeFeeSchedule(_entityId, _feeScheduleType);
    }

    function objectMinimumSell(bytes32 _objectId) external view returns (uint256) {
        return LibAdmin._objectMinimumSell(_objectId);
    }
}
