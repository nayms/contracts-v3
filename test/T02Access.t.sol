// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
// import { c as c } from "forge-std/c.sol";
import { D03ProtocolDefaults, LibHelpers, LC, c } from "./defaults/D03ProtocolDefaults.sol";
import { Entity, SimplePolicy, Stakeholders } from "src/shared/FreeStructs.sol";
import "src/shared/CustomErrors.sol";

// updateRoleGroup | isRoleInGroup | groups [role][group] = bool
// updateRoleAssigner | canGroupAssignRole | canAssign [role] = group
// getRoleInContext | roles[objectId][contextId] = role

contract T02Access is D03ProtocolDefaults {
    using LibHelpers for *;

    bytes32 internal testPolicyDataHash = 0x00a420601de63bf726c0be38414e9255d301d74ad0d820d633f3ab75effd6f5b;
    Stakeholders internal stakeholders;
    SimplePolicy internal simplePolicy;

    function setUp() public {
        // Assign roles to users
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

        changePrank(sa.addr);
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

    function testWithdrawRestriction() public {
        // The roles that can receive funds from a withdraw: ea, cc, cw
        changePrank(ea);
        writeTokenBalance(ea.addr, naymsAddress, wethAddress, 1 ether);
        nayms.externalDeposit(wethAddress, 1 ether); // deposit 100 weth into ea's parent (sm.entityId)
        // Withdrawing from the entity sm.entityId
        nayms.externalWithdrawFromEntity(sm.entityId, ea.addr, wethAddress, 100);

        changePrank(cc);
        writeTokenBalance(cc.addr, naymsAddress, wethAddress, 1 ether);
        vm.expectRevert(); // Invalid group privilege
        nayms.externalWithdrawFromEntity(sm.entityId, cc.addr, wethAddress, 100);

        changePrank(sm);
        nayms.setEntity(cc.id, sm.entityId); // User's parent must be set to the entity to deposit and withdraw from it
        changePrank(cc);
        nayms.externalWithdrawFromEntity(sm.entityId, cc.addr, wethAddress, 100);

        vm.expectRevert(abi.encodeWithSelector(ExternalWithdrawInvalidReceiver.selector, sm.addr));
        nayms.externalWithdrawFromEntity(sm.entityId, sm.addr, wethAddress, 100); // Invalid receiver sm.addr
    }

    function test_preventRoleDemotion() public {
        changePrank(sa);
        // Currently you can assign a user with the same role
        nayms.assignRole(sm.id, systemContext, LC.ROLE_SYSTEM_MANAGER);

        // A system manager cannot unassign a system admin
        changePrank(sm);
        vm.expectRevert(
            abi.encodeWithSelector(AssignerCannotUnassignRole.selector, sm.id, sa.id, systemContext, string(LC.ROLE_SYSTEM_ADMIN._stringToBytes32()._bytes32ToBytes()))
        );
        nayms.assignRole(sa.id, systemContext, LC.ROLE_ENTITY_CP);

        // An entity manager cannot unassign a system manager
        changePrank(em);
        vm.expectRevert();
        nayms.assignRole(sm.id, systemContext, string(LC.ROLE_ENTITY_MANAGER._stringToBytes32()._bytes32ToBytes()));
    }
}
