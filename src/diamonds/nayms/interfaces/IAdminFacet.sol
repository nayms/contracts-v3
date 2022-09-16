// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/**
 * @title Administration
 * @notice Exposes methods that require administrative priviledges
 * @dev Use it to configure various core parameters
 */
interface IAdminFacet {
    /**
     * @notice Set the equilibrium level to `_newLevel` in the NDF
     * @dev Desired amount of NAYM tokens in NDF
     * @param _newLevel new value for the equilibrium level
     */
    function setEquilibriumLevel(uint256 _newLevel) external;

    /**
     * @notice Set the maximum discount `_newDiscount` in the NDF
     * @dev TODO explain
     * @param _newDiscount new value for the max discount
     */
    function setMaxDiscount(uint256 _newDiscount) external;

    /**
     * @notice Set the targeted NAYM allocation to `_newTarget` in the NDF
     * @dev TODO explain
     * @param _newTarget new value for the target allocation
     */
    function setTargetNaymsAllocation(uint256 _newTarget) external;

    /**
     * @notice Set the `_newToken` as a token for dicounts
     * @dev TODO explain
     * @param _newToken token to be used for discounts
     */
    function setDiscountToken(address _newToken) external;

    /**
     * @notice Set `_newFee` as NDF pool fee
     * @dev TODO explain
     * @param _newFee new value to be used as transaction fee in the NDF pool
     */
    function setPoolFee(uint24 _newFee) external;

    /**
     * @notice Set `_newCoefficient` as the coefficient
     * @dev TODO explain
     * @param _newCoefficient new value to be used as coefficient
     */
    function setCoefficient(uint256 _newCoefficient) external;

    /**
     * @notice Set `_newMax` as the max dividend denominations value.
     * @dev TODO explain
     * @param _newMax new value to be used.
     */
    function setMaxDividendDenominations(uint8 _newMax) external;

    /**
     * @notice Get the discount token
     * @dev TODO explain
     * @return address of the token used for discounts
     */
    function getDiscountToken() external view returns (address);

    /**
     * @notice Get the equilibrium level
     * @dev TODO explain
     * @return equilibrium level value
     */
    function getEquilibriumLevel() external view returns (uint256);

    /**
     * @notice Get current NAYM allocation
     * @dev TODO explain
     * @return total number of NAYM tokens
     */
    function getActualNaymsAllocation() external view returns (uint256);

    /**
     * @notice Get the target NAYM allocation
     * @dev TODO explain
     * @return desired supply of NAYM tokens
     */
    function getTargetNaymsAllocation() external view returns (uint256);

    /**
     * @notice Get the maximum discount
     * @dev TODO explain
     * @return max discount value
     */
    function getMaxDiscount() external view returns (uint256);

    /**
     * @notice Get the pool fee
     * @dev TODO explain
     * @return current pool fee
     */
    function getPoolFee() external view returns (uint256);

    /**
     * @notice Get the rewards coeficient
     * @dev TODO explain
     * @return coefficient for rewards
     */
    function getRewardsCoefficient() external view returns (uint256);

    /**
     * @notice Get the max dividend denominations value
     * @dev TODO explain
     * @return max dividend denominations
     */
    function getMaxDividendDenominations() external view returns (uint8);

    /**
     * @notice is the specified token an external ERC20?
     * @dev TODO explain
     * @param _tokenId token address converted to bytes32
     * @return whether token issupported or not
     */
    function isSupportedExternalToken(bytes32 _tokenId) external view returns (bool);

    /**
     * @notice Add another token to the supported tokens list
     * @param _tokenAddress address of the token to support
     * @dev TODO explain
     */
    function addSupportedExternalToken(address _tokenAddress) external;

    /**
     * @notice Get the supported tokens list as an array
     * @dev TODO explain
     * @return array containing address of all supported tokens
     */
    function getSupportedExternalTokens() external view returns (address[] memory);

    /**
     * @notice Update who can assign `_role` role
     * @dev Update who has permission to assign this role
     * @param _role name of the role
     * @param _assignerGroup Group who can assign members to this role
     */
    function updateRoleAssigner(string memory _role, string memory _assignerGroup) external;

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
    ) external;

    /**
     * @notice gets the System context ID.
     * @return System Identifier
     */
    function getSystemId() external pure returns (bytes32);
}
