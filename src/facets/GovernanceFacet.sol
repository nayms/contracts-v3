// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { Modifiers } from "../shared/Modifiers.sol";
import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { LibGovernance } from "src/libs/LibGovernance.sol";
import { LibAdmin } from "src/libs/LibAdmin.sol";
import { LibConstants as LC } from "src/libs/LibConstants.sol";

contract GovernanceFacet is Modifiers {
    event CreateUpgrade(bytes32 id, address indexed who);
    event UpdateUpgradeExpiration(uint256 duration);
    event UpgradeCancelled(bytes32 id, address indexed who);

    /**
     * @notice Check if the diamond has been initialized.
     * @dev This will get the value from AppStorage.diamondInitialized.
     */
    function isDiamondInitialized() external view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.diamondInitialized;
    }

    /**
     * @notice Calcuate upgrade hash: `id`
     * @dev calucate the upgrade hash by hashing all the inputs
     * @param _diamondCut the array of FacetCut struct, IDiamondCut.FacetCut[] to be used for upgrade
     * @param _init address of the init diamond to be used for upgrade
     * @param _calldata bytes to be passed as call data for upgrade
     */
    function calculateUpgradeId(IDiamondCut.FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external pure returns (bytes32) {
        return LibGovernance._calculateUpgradeId(_diamondCut, _init, _calldata);
    }

    /**
     * @notice Approve the following upgrade hash: `id`
     * @dev The diamondCut() has been modified to check if the upgrade has been scheduled. This method needs to be called in order
     *      for an upgrade to be executed.
     * @param id This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].
     */
    function createUpgrade(bytes32 id) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (s.upgradeScheduled[id] > block.timestamp) {
            revert("Upgrade has already been scheduled");
        }
        // 0 == upgrade is not scheduled / has been cancelled
        // block.timestamp + upgradeExpiration == upgrade is scheduled and expires at this time
        // Set back to 0 when an upgrade is complete
        s.upgradeScheduled[id] = block.timestamp + s.upgradeExpiration;
        emit CreateUpgrade(id, msg.sender);
    }

    /**
     * @notice Update the diamond cut upgrade expiration period.
     * @dev When createUpgrade() is called, it allows a diamondCut() upgrade to be executed. This upgrade must be executed before the
     *      upgrade expires. The upgrade expires based on when the upgrade was scheduled (when createUpgrade() was called) + AppStorage.upgradeExpiration.
     * @param duration The duration until the upgrade expires.
     */
    function updateUpgradeExpiration(uint256 duration) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(1 minutes < duration && duration < 1 weeks, "invalid upgrade expiration period");

        s.upgradeExpiration = duration;
        emit UpdateUpgradeExpiration(duration);
    }

    /**
     * @notice Cancel the following upgrade hash: `id`
     * @dev This will set the mapping AppStorage.upgradeScheduled back to 0.
     * @param id This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].
     */
    function cancelUpgrade(bytes32 id) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.upgradeScheduled[id] > 0, "invalid upgrade ID");

        s.upgradeScheduled[id] = 0;

        emit UpgradeCancelled(id, msg.sender);
    }

    /**
     * @notice Get the expiry date for provided upgrade hash.
     * @dev This will get the value from AppStorage.upgradeScheduled  mapping.
     * @param id This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].
     */
    function getUpgrade(bytes32 id) external view returns (uint256 expiry) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        expiry = s.upgradeScheduled[id];
    }

    /**
     * @notice Get the upgrade expiration period.
     * @dev This will get the value from AppStorage.upgradeExpiration. AppStorage.upgradeExpiration is added to the block.timestamp to create the upgrade expiration date.
     */
    function getUpgradeExpiration() external view returns (uint256 upgradeExpiration) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        upgradeExpiration = s.upgradeExpiration;
    }
}
