// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { AppStorage, FunctionLockedStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibACL } from "./LibACL.sol";

library LibInitDiamond {
    function setSystemAdmin(address _newSystemAdmin) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 userId = LibHelpers._getIdForAddress(_newSystemAdmin);
        s.existingObjects[userId] = true;

        LibACL._assignRole(userId, LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.ROLE_SYSTEM_ADMIN));
    }

    function setUpgradeExpiration() internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        /// @dev We set the upgrade expiration to 7 days from now (604800 seconds)
        s.upgradeExpiration = 1 weeks;
    }

    function setRoleGroupsAndAssigners() internal {
        LibACL._updateRoleGroup(LibConstants.ROLE_SYSTEM_ADMIN, LibConstants.GROUP_SYSTEM_ADMINS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_SYSTEM_ADMIN, LibConstants.GROUP_SYSTEM_MANAGERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_SYSTEM_MANAGER, LibConstants.GROUP_SYSTEM_MANAGERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_ENTITY_ADMIN, LibConstants.GROUP_ENTITY_ADMINS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_ENTITY_MANAGER, LibConstants.GROUP_ENTITY_MANAGERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_BROKER, LibConstants.GROUP_BROKERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_UNDERWRITER, LibConstants.GROUP_UNDERWRITERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_INSURED_PARTY, LibConstants.GROUP_INSURED_PARTIES, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_CAPITAL_PROVIDER, LibConstants.GROUP_CAPITAL_PROVIDERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_CLAIMS_ADMIN, LibConstants.GROUP_CLAIMS_ADMINS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_TRADER, LibConstants.GROUP_TRADERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_SEGREGATED_ACCOUNT, LibConstants.GROUP_SEGREGATED_ACCOUNTS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_SERVICE_PROVIDER, LibConstants.GROUP_SERVICE_PROVIDERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_BROKER, LibConstants.GROUP_POLICY_HANDLERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_INSURED_PARTY, LibConstants.GROUP_POLICY_HANDLERS, true);

        LibACL._updateRoleAssigner(LibConstants.ROLE_SYSTEM_ADMIN, LibConstants.GROUP_SYSTEM_ADMINS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_SYSTEM_MANAGER, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_ENTITY_ADMIN, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_ENTITY_MANAGER, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_BROKER, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_UNDERWRITER, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_INSURED_PARTY, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_CAPITAL_PROVIDER, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_CLAIMS_ADMIN, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_TRADER, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_SEGREGATED_ACCOUNT, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_SERVICE_PROVIDER, LibConstants.GROUP_SYSTEM_MANAGERS);
    }
}
