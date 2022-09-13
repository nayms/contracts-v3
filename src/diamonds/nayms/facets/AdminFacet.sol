// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { Modifiers, LibAdmin } from "../AppStorage.sol";

contract AdminFacet is Modifiers {
    function setEquilibriumLevel(uint256 _newLevel) external assertSysAdmin {
        LibAdmin._setEquilibriumLevel(_newLevel);
    }

    function setMaxDiscount(uint256 _newDiscount) external assertSysAdmin {
        LibAdmin._setMaxDiscount(_newDiscount);
    }

    function setTargetNaymsAllocation(uint256 _newTarget) external assertSysAdmin {
        LibAdmin._setTargetNaymsAllocation(_newTarget);
    }

    function setDiscountToken(address _newToken) external assertSysAdmin {
        LibAdmin._setDiscountToken(_newToken);
    }

    function setPoolFee(uint24 _newFee) external assertSysAdmin {
        LibAdmin._setPoolFee(_newFee);
    }

    function setCoefficient(uint256 _newCoefficient) external assertSysAdmin {
        LibAdmin._setCoefficient(_newCoefficient);
    }

    function getDiscountToken() external view returns (address) {
        return s.discountToken;
    }

    function getEquilibriumLevel() external view returns (uint256) {
        return s.equilibriumLevel;
    }

    function getActualNaymsAllocation() external view returns (uint256) {
        return s.actualNaymsAllocation;
    }

    function getTargetNaymsAllocation() external view returns (uint256) {
        return s.targetNaymsAllocation;
    }

    function getMaxDiscount() external view returns (uint256) {
        return s.maxDiscount;
    }

    function getPoolFee() external view returns (uint256) {
        return s.poolFee;
    }

    function getRewardsCoefficient() external view returns (uint256) {
        return s.rewardsCoefficient;
    }

    function isSupportedExternalToken(bytes32 _tokenId) external view returns (bool) {
        return LibAdmin._isSupportedExternalToken(_tokenId);
    }

    function addSupportedExternalToken(address _tokenAddress) external assertSysAdmin {
        LibAdmin._addSupportedExternalToken(_tokenAddress);
    }

    function getSupportedExternalTokens() external view returns (address[] memory) {
        return LibAdmin._getSupportedExternalTokens();
    }

    function updateRoleAssigner(string memory _role, string memory _assignerGroup) external assertSysAdmin {
        LibAdmin._updateRoleAssigner(_role, _assignerGroup);
    }

    function updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) external assertSysAdmin {
        LibAdmin._updateRoleGroup(_role, _group, _roleInGroup);
    }

    function getSystemId() external pure returns (bytes32) {
        return LibAdmin._getSystemId();
    }
}
