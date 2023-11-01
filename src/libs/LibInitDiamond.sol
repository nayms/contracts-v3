// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { AppStorage, FunctionLockedStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { LibConstants as LC } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibACL } from "./LibACL.sol";

library LibInitDiamond {
    function setSystemAdmin(address _newSystemAdmin) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 userId = LibHelpers._getIdForAddress(_newSystemAdmin);
        s.existingObjects[userId] = true;

        LibACL._assignRole(userId, LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LC.ROLE_SYSTEM_ADMIN));
    }

    function setUpgradeExpiration() internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        /// @dev We set the upgrade expiration to 7 days from now (604800 seconds)
        s.upgradeExpiration = 1 weeks;
    }

    function setRoleGroupsAndAssigners() internal {
        LibACL._updateRoleGroup(LC.ROLE_SYSTEM_ADMIN, LC.GROUP_SYSTEM_MANAGERS, false);

        // setup core groups
        LibACL._updateRoleGroup(LC.ROLE_SYSTEM_UNDERWRITER, LC.GROUP_SYSTEM_UNDERWRITERS, true);
        LibACL._updateRoleGroup(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_SYSTEM_MANAGERS, true);
        LibACL._updateRoleGroup(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_MANAGERS, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_MANAGER, LC.GROUP_MANAGERS, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_MANAGER, LC.GROUP_ENTITY_MANAGERS, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_ADMIN, LC.GROUP_ENTITY_ADMINS, true);

        // setup function groups
        LibACL._updateRoleGroup(LC.ROLE_SYSTEM_ADMIN, LC.GROUP_SYSTEM_ADMINS, true);
        LibACL._updateRoleGroup(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_START_TOKEN_SALE, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_MANAGER, LC.GROUP_START_TOKEN_SALE, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_MANAGER, LC.GROUP_CANCEL_OFFER, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_CP, LC.GROUP_CANCEL_OFFER, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_CP, LC.GROUP_EXECUTE_LIMIT_OFFER, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_ADMIN, LC.GROUP_EXECUTE_LIMIT_OFFER, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_BROKER, LC.GROUP_PAY_SIMPLE_PREMIUM, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_INSURED, LC.GROUP_PAY_SIMPLE_PREMIUM, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.GROUP_PAY_SIMPLE_CLAIM, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_CLAIM, LC.GROUP_PAY_SIMPLE_CLAIM, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.GROUP_PAY_DIVIDEND_FROM_ENTITY, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_DIVIDEND, LC.GROUP_PAY_DIVIDEND_FROM_ENTITY, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_ADMIN, LC.GROUP_EXTERNAL_DEPOSIT, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.GROUP_EXTERNAL_DEPOSIT, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_WITHDRAW, LC.GROUP_EXTERNAL_DEPOSIT, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_ADMIN, LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_WITHDRAW, LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY, true);

        // setup stakeholder groups
        LibACL._updateRoleGroup(LC.ROLE_UNDERWRITER, LC.GROUP_UNDERWRITERS, true);
        LibACL._updateRoleGroup(LC.ROLE_BROKER, LC.GROUP_BROKERS, true);
        LibACL._updateRoleGroup(LC.ROLE_CAPITAL_PROVIDER, LC.GROUP_CAPITAL_PROVIDERS, true);
        LibACL._updateRoleGroup(LC.ROLE_INSURED_PARTY, LC.GROUP_INSURED_PARTIES, true);

        // setup assigners
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_CP, LC.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_BROKER, LC.GROUP_MANAGERS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_INSURED, LC.GROUP_MANAGERS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.GROUP_ENTITY_MANAGERS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_COMPTROLLER_WITHDRAW, LC.GROUP_ENTITY_MANAGERS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_COMPTROLLER_CLAIM, LC.GROUP_ENTITY_MANAGERS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_COMPTROLLER_DIVIDEND, LC.GROUP_ENTITY_MANAGERS);
        LibACL._updateRoleAssigner(LC.ROLE_SYSTEM_ADMIN, LC.GROUP_SYSTEM_ADMINS);
        LibACL._updateRoleAssigner(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_SYSTEM_ADMINS);
        LibACL._updateRoleAssigner(LC.ROLE_SYSTEM_UNDERWRITER, LC.GROUP_SYSTEM_ADMINS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_ADMIN, LC.GROUP_SYSTEM_ADMINS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_MANAGER, LC.GROUP_SYSTEM_ADMINS);
    }
}
