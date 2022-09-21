// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IAdminFacet {
    function setEquilibriumLevel(uint256 _newLevel) external;

    function setMaxDiscount(uint256 _newDiscount) external;

    function setTargetNaymsAllocation(uint256 _newTarget) external;

    function setDiscountToken(address _newToken) external;

    function setPoolFee(uint24 _newFee) external;

    function setCoefficient(uint256 _newCoefficient) external;

    function setMaxDividendDenominations(uint8 _newMax) external;

    function getDiscountToken() external view returns (address);

    function getEquilibriumLevel() external view returns (uint256);

    function getActualNaymsAllocation() external view returns (uint256);

    function getTargetNaymsAllocation() external view returns (uint256);

    function getMaxDiscount() external view returns (uint256);

    function getPoolFee() external view returns (uint256);

    function getRewardsCoefficient() external view returns (uint256);

    function getMaxDividendDenominations() external view returns (uint8);

    function isSupportedExternalToken(bytes32 _tokenId) external view returns (bool);

    function addSupportedExternalToken(address _tokenAddress) external;

    function getSupportedExternalTokens() external view returns (address[] memory);

    function updateRoleAssigner(string memory _role, string memory _assignerGroup) external;

    function updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) external;

    function getSystemId() external pure returns (bytes32);
}
