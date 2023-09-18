// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import { console2 as c } from "forge-std/console2.sol";
import { D03ProtocolDefaults, LibHelpers, LC } from "./defaults/D03ProtocolDefaults.sol";
import { Entity, SimplePolicy, Stakeholders } from "src/diamonds/nayms/interfaces/FreeStructs.sol";

// updateRoleGroup | isRoleInGroup | groups [role][group] = bool
// updateRoleAssigner | canGroupAssignRole | canAssign [role] = group
// getRoleInContext | roles[objectId][contextId] = role

abstract contract T02AccessHelpers is D03ProtocolDefaults {
    using LibHelpers for *;
    string[3] internal rolesThatCanAssignRoles = [LC.ROLE_SYSTEM_ADMIN, LC.ROLE_SYSTEM_MANAGER, LC.ROLE_ENTITY_MANAGER];
    mapping(string => string[]) internal roleCanAssignRoles;
    mapping(string => bytes32[]) internal roleToUsers;
    mapping(string => address[]) internal roleToUsersAddr;
    mapping(bytes32 => bytes32) internal objectToContext;

    mapping(string => string[]) internal functionToRoles;
    string[] internal functionsUsingAssertP = [
        LC.GROUP_START_TOKEN_SALE,
        LC.GROUP_EXECUTE_LIMIT_OFFER,
        LC.GROUP_CANCEL_OFFER,
        LC.GROUP_PAY_SIMPLE_PREMIUM,
        LC.GROUP_PAY_SIMPLE_CLAIM,
        LC.GROUP_PAY_DIVIDEND_FROM_ENTITY,
        LC.GROUP_EXTERNAL_DEPOSIT,
        LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY
    ];

    function hAssignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _role
    ) internal {
        nayms.assignRole(_objectId, _contextId, _role);
        roleToUsers[_role].push(_objectId);
        roleToUsersAddr[_role].push(_objectId._getAddressFromId());
        if (objectToContext[_objectId] == systemContext) {
            c.log("warning: object's context is currently systemContext");
        } else {
            objectToContext[_objectId] = _contextId;
        }
    }

    function hCreateEntity(
        bytes32 _entityId,
        bytes32 _entityAdmin,
        Entity memory _entityData,
        bytes32 _dataHash
    ) internal {
        nayms.createEntity(_entityId, _entityAdmin, _entityData, _dataHash);
        roleToUsers[LC.ROLE_ENTITY_ADMIN].push(_entityAdmin);

        if (objectToContext[_entityAdmin] == systemContext) {
            c.log("warning: object's context is currently systemContext");
        } else {
            objectToContext[_entityAdmin] = _entityId;
        }
    }
}

contract T02Access is T02AccessHelpers {
    using LibHelpers for *;

    bytes32 internal testPolicyDataHash = 0x00a420601de63bf726c0be38414e9255d301d74ad0d820d633f3ab75effd6f5b;
    Stakeholders internal stakeholders;
    SimplePolicy internal simplePolicy;

    function setUp() public {
        // Assign roles to users
        hAssignRole(sa.id, systemContext, LC.ROLE_SYSTEM_ADMIN);
        hAssignRole(sm.id, systemContext, LC.ROLE_SYSTEM_MANAGER);
        hAssignRole(su.id, systemContext, LC.ROLE_SYSTEM_UNDERWRITER);
    }

    function test_canAssign_comprehensive() public {
        roleCanAssignRoles[LC.ROLE_SYSTEM_ADMIN] = [LC.ROLE_SYSTEM_ADMIN, LC.ROLE_SYSTEM_MANAGER, LC.ROLE_SYSTEM_UNDERWRITER, LC.ROLE_ENTITY_ADMIN, LC.ROLE_ENTITY_MANAGER];

        roleCanAssignRoles[LC.ROLE_SYSTEM_MANAGER] = [LC.ROLE_ENTITY_BROKER, LC.ROLE_ENTITY_INSURED, LC.ROLE_ENTITY_CP];

        roleCanAssignRoles[LC.ROLE_ENTITY_MANAGER] = [
            LC.ROLE_ENTITY_BROKER,
            LC.ROLE_ENTITY_INSURED,
            LC.ROLE_ENTITY_COMPTROLLER_COMBINED,
            LC.ROLE_ENTITY_COMPTROLLER_WITHDRAW,
            LC.ROLE_ENTITY_COMPTROLLER_CLAIM,
            LC.ROLE_ENTITY_COMPTROLLER_DIVIDEND
        ];

        hAssignRole(em.id, tb.entityId, LC.ROLE_ENTITY_MANAGER);

        for (uint256 j; j < rolesThatCanAssignRoles.length; ++j) {
            string memory role = rolesThatCanAssignRoles[j];

            for (uint256 i; i < roleCanAssignRoles[role].length; ++i) {
                bytes32 context = objectToContext[roleToUsers[role][0]];
                assertTrue(nayms.canAssign(roleToUsers[role][0], tb.id, context, roleCanAssignRoles[role][i]), string.concat(role, " can assign ", roleCanAssignRoles[role][i]));

                if (context != systemContext) {
                    assertFalse(nayms.canAssign(roleToUsers[role][0], tb.id, systemContext, roleCanAssignRoles[role][i]));
                }
            }
        }

        assertTrue(nayms.canAssign(systemAdminId, sa.id, systemContext, LC.ROLE_SYSTEM_ADMIN));
        assertTrue(nayms.canAssign(systemAdminId, sa.id, systemContext, LC.ROLE_SYSTEM_MANAGER));
        assertTrue(nayms.canAssign(systemAdminId, sa.id, systemContext, LC.ROLE_SYSTEM_UNDERWRITER));

        assertFalse(nayms.canAssign(sm.id, sa.id, systemContext, LC.ROLE_SYSTEM_ADMIN));
        assertFalse(nayms.canAssign(sm.id, sa.id, systemContext, LC.ROLE_SYSTEM_MANAGER));
        assertFalse(nayms.canAssign(sm.id, sa.id, systemContext, LC.ROLE_SYSTEM_UNDERWRITER));
        assertFalse(nayms.canAssign(su.id, sa.id, systemContext, LC.ROLE_SYSTEM_ADMIN));
        assertFalse(nayms.canAssign(su.id, sa.id, systemContext, LC.ROLE_SYSTEM_MANAGER));
        assertFalse(nayms.canAssign(su.id, sa.id, systemContext, LC.ROLE_SYSTEM_UNDERWRITER));

        assertTrue(nayms.isRoleInGroup(LC.ROLE_SYSTEM_ADMIN, LC.GROUP_SYSTEM_ADMINS));
        assertFalse(nayms.isRoleInGroup(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_SYSTEM_ADMINS));
        assertFalse(nayms.isRoleInGroup(LC.ROLE_SYSTEM_UNDERWRITER, LC.GROUP_SYSTEM_ADMINS));

        // new group admins
        assertTrue(nayms.isRoleInGroup(LC.ROLE_SYSTEM_ADMIN, LC.GROUP_SYSTEM_ADMINS));

        assertFalse(nayms.isRoleInGroup(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_SYSTEM_ADMINS));
        assertFalse(nayms.isRoleInGroup(LC.ROLE_SYSTEM_UNDERWRITER, LC.GROUP_SYSTEM_ADMINS));

        assertTrue(nayms.canGroupAssignRole(LC.ROLE_SYSTEM_ADMIN, LC.GROUP_SYSTEM_ADMINS));
        assertTrue(nayms.canGroupAssignRole(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_SYSTEM_ADMINS));
        assertTrue(nayms.canGroupAssignRole(LC.ROLE_SYSTEM_UNDERWRITER, LC.GROUP_SYSTEM_ADMINS));

        assertTrue(nayms.canAssign(systemAdminId, sa.id, systemContext, LC.ROLE_SYSTEM_ADMIN));
        assertTrue(nayms.canAssign(systemAdminId, sa.id, systemContext, LC.ROLE_SYSTEM_MANAGER));
        assertTrue(nayms.canAssign(systemAdminId, sa.id, systemContext, LC.ROLE_SYSTEM_UNDERWRITER));

        assertFalse(nayms.isRoleInGroup(LC.ROLE_ENTITY_BROKER, LC.GROUP_SYSTEM_MANAGERS));
        assertFalse(nayms.isRoleInGroup(LC.ROLE_ENTITY_BROKER, LC.GROUP_ENTITY_MANAGERS));

        hAssignRole(em.id, tb.entityId, LC.ROLE_ENTITY_MANAGER);

        changePrank(sm.addr);
        hAssignRole(tb.id, tb.entityId, LC.ROLE_ENTITY_BROKER);
        hAssignRole(tb.id, systemContext, LC.ROLE_ENTITY_BROKER);
        assertTrue(nayms.canAssign(sm.id, tb.id, systemContext, LC.ROLE_ENTITY_BROKER));
        assertFalse(nayms.canAssign(em.id, tb.id, systemContext, LC.ROLE_ENTITY_BROKER)); // can only assign in entity context
        assertTrue(nayms.canAssign(sm.id, tb.id, tb.entityId, LC.ROLE_ENTITY_BROKER));
        assertTrue(nayms.canAssign(em.id, tb.id, tb.entityId, LC.ROLE_ENTITY_BROKER));

        changePrank(sa.addr);
        hAssignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        assertTrue(nayms.canAssign(em.id, tb.id, systemContext, LC.ROLE_ENTITY_BROKER)); // can assign in system context

        assertTrue(nayms.canGroupAssignRole(LC.ROLE_SYSTEM_ADMIN, LC.GROUP_SYSTEM_ADMINS));
        assertTrue(nayms.canGroupAssignRole(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_SYSTEM_ADMINS));
        assertTrue(nayms.canGroupAssignRole(LC.ROLE_SYSTEM_UNDERWRITER, LC.GROUP_SYSTEM_ADMINS));
        assertTrue(nayms.canGroupAssignRole(LC.ROLE_CAPITAL_PROVIDER, LC.GROUP_SYSTEM_MANAGERS));

        assertFalse(nayms.canGroupAssignRole(LC.ROLE_SYSTEM_ADMIN, LC.GROUP_SYSTEM_MANAGERS));
    }

    function test_roles_hasGroupPrivilege() public {
        hAssignRole(em.id, sm.entityId, LC.ROLE_ENTITY_MANAGER);

        changePrank(sm.addr);
        hCreateEntity(sm.entityId, ea.id, entity, "entity test hash");
        hAssignRole(tcp.id, sm.entityId, LC.ROLE_ENTITY_CP);
        hAssignRole(tb.id, sm.entityId, LC.ROLE_ENTITY_BROKER);
        hAssignRole(ti.id, sm.entityId, LC.ROLE_ENTITY_INSURED);

        changePrank(em.addr);
        hAssignRole(cc.id, sm.entityId, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);
        hAssignRole(cw.id, sm.entityId, LC.ROLE_ENTITY_COMPTROLLER_WITHDRAW);
        hAssignRole(cClaim.id, sm.entityId, LC.ROLE_ENTITY_COMPTROLLER_CLAIM);
        hAssignRole(cd.id, sm.entityId, LC.ROLE_ENTITY_COMPTROLLER_DIVIDEND);

        functionToRoles[LC.GROUP_START_TOKEN_SALE] = [LC.ROLE_SYSTEM_MANAGER, LC.ROLE_ENTITY_MANAGER];
        functionToRoles[LC.GROUP_EXECUTE_LIMIT_OFFER] = [LC.ROLE_ENTITY_CP];
        functionToRoles[LC.GROUP_CANCEL_OFFER] = [LC.ROLE_ENTITY_MANAGER, LC.ROLE_ENTITY_CP];
        functionToRoles[LC.GROUP_PAY_SIMPLE_PREMIUM] = [LC.ROLE_ENTITY_BROKER, LC.ROLE_ENTITY_INSURED];
        functionToRoles[LC.GROUP_PAY_SIMPLE_CLAIM] = [LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.ROLE_ENTITY_COMPTROLLER_CLAIM];
        functionToRoles[LC.GROUP_PAY_DIVIDEND_FROM_ENTITY] = [LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.ROLE_ENTITY_COMPTROLLER_DIVIDEND];
        functionToRoles[LC.GROUP_EXTERNAL_DEPOSIT] = [LC.ROLE_ENTITY_ADMIN, LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.ROLE_ENTITY_COMPTROLLER_WITHDRAW];
        functionToRoles[LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY] = [LC.ROLE_ENTITY_ADMIN, LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.ROLE_ENTITY_COMPTROLLER_WITHDRAW];

        for (uint256 i; i < functionsUsingAssertP.length; ++i) {
            string memory functionGroup = functionsUsingAssertP[i];
            for (uint256 j; j < functionToRoles[functionGroup].length; ++j) {
                string memory role = functionToRoles[functionGroup][j];
                bytes32 user = roleToUsers[role][0];
                bytes32 context = objectToContext[user];

                assertTrue(nayms.isInGroup(user, context, functionGroup));
                assertTrue(nayms.hasGroupPrivilege(user, context, functionGroup._stringToBytes32()));
            }
        }
    }

    function test_sysAdmin_canAssign_sysUW() public {
        changePrank(sa.addr);
        hAssignRole(address(888)._getIdForAddress(), systemContext, LC.ROLE_SYSTEM_UNDERWRITER);

        nayms.updateRoleAssigner(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_SYSTEM_ADMINS);
    }
}
