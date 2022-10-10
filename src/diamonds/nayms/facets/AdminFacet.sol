// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { Modifiers, LibAdmin } from "../AppStorage.sol";

/**
 * @title Administration
 * @notice Exposes methods that require administrative priviledges
 * @dev Use it to configure various core parameters
 */
contract AdminFacet is Modifiers {
    /**
     * @notice Set the equilibrium level to `_newLevel` in the NDF
     * @dev Desired amount of NAYM tokens in NDF
     * @param _newLevel new value for the equilibrium level
     */
    function setEquilibriumLevel(uint256 _newLevel) external assertSysAdmin {
        LibAdmin._setEquilibriumLevel(_newLevel);
    }

    /**
     * @notice Set the maximum discount `_newDiscount` in the NDF
     * @dev TODO explain
     * @param _newDiscount new value for the max discount
     */
    function setMaxDiscount(uint256 _newDiscount) external assertSysAdmin {
        LibAdmin._setMaxDiscount(_newDiscount);
    }

    /**
     * @notice Set the targeted NAYM allocation to `_newTarget` in the NDF
     * @dev TODO explain
     * @param _newTarget new value for the target allocation
     */
    function setTargetNaymsAllocation(uint256 _newTarget) external assertSysAdmin {
        LibAdmin._setTargetNaymsAllocation(_newTarget);
    }

    /**
     * @notice Set the `_newToken` as a token for dicounts
     * @dev TODO explain
     * @param _newToken token to be used for discounts
     */
    function setDiscountToken(address _newToken) external assertSysAdmin {
        LibAdmin._setDiscountToken(_newToken);
    }

    /**
     * @notice Set `_newFee` as NDF pool fee
     * @dev TODO explain
     * @param _newFee new value to be used as transaction fee in the NDF pool
     */
    function setPoolFee(uint24 _newFee) external assertSysAdmin {
        LibAdmin._setPoolFee(_newFee);
    }

    /**
     * @notice Set `_newCoefficient` as the coefficient
     * @dev TODO explain
     * @param _newCoefficient new value to be used as coefficient
     */
    function setCoefficient(uint256 _newCoefficient) external assertSysAdmin {
        LibAdmin._setCoefficient(_newCoefficient);
    }

    /**
     * @notice Set `_newMax` as the max dividend denominations value.
     * @dev TODO explain
     * @param _newMax new value to be used.
     */
    function setMaxDividendDenominations(uint8 _newMax) external assertSysAdmin {
        LibAdmin._updateMaxDividendDenominations(_newMax);
    }

    /**
     * @notice Get the discount token
     * @dev TODO explain
     * @return address of the token used for discounts
     */
    function getDiscountToken() external view returns (address) {
        return s.discountToken;
    }

    /**
     * @notice Get the equilibrium level
     * @dev TODO explain
     * @return equilibrium level value
     */
    function getEquilibriumLevel() external view returns (uint256) {
        return s.equilibriumLevel;
    }

    /**
     * @notice Get current NAYM allocation
     * @dev TODO explain
     * @return total number of NAYM tokens
     */
    function getActualNaymsAllocation() external view returns (uint256) {
        return s.actualNaymsAllocation;
    }

    /**
     * @notice Get the target NAYM allocation
     * @dev TODO explain
     * @return desired supply of NAYM tokens
     */
    function getTargetNaymsAllocation() external view returns (uint256) {
        return s.targetNaymsAllocation;
    }

    /**
     * @notice Get the maximum discount
     * @dev TODO explain
     * @return max discount value
     */
    function getMaxDiscount() external view returns (uint256) {
        return s.maxDiscount;
    }

    /**
     * @notice Get the pool fee
     * @dev TODO explain
     * @return current pool fee
     */
    function getPoolFee() external view returns (uint256) {
        return s.poolFee;
    }

    /**
     * @notice Get the rewards coeficient
     * @dev TODO explain
     * @return coefficient for rewards
     */
    function getRewardsCoefficient() external view returns (uint256) {
        return s.rewardsCoefficient;
    }

    /**
     * @notice Get the max dividend denominations value
     * @dev TODO explain
     * @return max dividend denominations
     */
    function getMaxDividendDenominations() external view returns (uint8) {
        return s.maxDividendDenominations;
    }

    /**
     * @notice is the specified token an external ERC20?
     * @dev TODO explain
     * @param _tokenId token address converted to bytes32
     * @return whether token issupported or not
     */
    function isSupportedExternalToken(bytes32 _tokenId) external view returns (bool) {
        return LibAdmin._isSupportedExternalToken(_tokenId);
    }

    /**
     * @notice Add another token to the supported tokens list
     * @param _tokenAddress address of the token to support
     * @dev TODO explain
     */
    function addSupportedExternalToken(address _tokenAddress) external assertSysAdmin {
        LibAdmin._addSupportedExternalToken(_tokenAddress);
    }

    /**
     * @notice Get the supported tokens list as an array
     * @dev TODO explain
     * @return array containing address of all supported tokens
     */
    function getSupportedExternalTokens() external view returns (address[] memory) {
        return LibAdmin._getSupportedExternalTokens();
    }

    /**
     * @notice Update who can assign `_role` role
     * @dev Update who has permission to assign this role
     * @param _role name of the role
     * @param _assignerGroup Group who can assign members to this role
     */
    function updateRoleAssigner(string memory _role, string memory _assignerGroup) external assertSysAdmin {
        LibAdmin._updateRoleAssigner(_role, _assignerGroup);
    }

    /**
     * @notice Update role group memebership for `_role` role and `_group` group
     * @dev Update role group memebership
     * @param _role name of the role
     * @param _group name of the group
     * @param _roleInGroup is member of
     */
    function updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) external assertSysAdmin {
        LibAdmin._updateRoleGroup(_role, _group, _roleInGroup);
    }

    /**
     * @notice Gets the System context ID.
     * @return System Identifier
     */
    function getSystemId() external pure returns (bytes32) {
        return LibAdmin._getSystemId();
    }

    /**
     * @dev Get whether id refers to an object in the system.
     * @param _id object id.
     */
    function isObject(bytes32 _id) external view returns (bool) {
        return s.existingObjects[_id];
    }

    /**
     * @dev Get meta of given object.
     * @param _id object id.
     */
    function getObjectMeta(bytes32 _id)
        external
        view
        returns (
            bytes32 parent,
            bytes32 dataHash,
            bytes32 tokenSymbol
        )
    {
        parent = s.objectParent[_id];
        dataHash = s.objectDataHashes[_id];
        tokenSymbol = s.objectTokenSymbol[_id];
    }
}
