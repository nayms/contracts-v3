// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibConstants as LC } from "../libs/LibConstants.sol";
import { LibACL } from "../libs/LibACL.sol";
import { FeeSchedule, SimplePolicy } from "../shared/FreeStructs.sol";

// solhint-disable no-console
import { console2 as console } from "forge-std/console2.sol";
import { StdStyle } from "forge-std/Test.sol";

error DiamondAlreadyInitialized();

contract OneOff360InitDiamond {
    function initialize() external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        console.log(StdStyle.cyan("STARTING CUSTOM INIT"));

        // Set Commissions (all are in basis points)
        bytes32[] memory receiver = new bytes32[](1);
        receiver[0] = LibHelpers._stringToBytes32(LC.NAYMS_LTD_IDENTIFIER);

        uint16[] memory premiumBP = new uint16[](1);
        premiumBP[0] = 300;
        uint16[] memory tradingBP = new uint16[](1);
        tradingBP[0] = 30;
        uint16[] memory initSaleBP = new uint16[](1);
        initSaleBP[0] = 100;

        s.feeSchedules[LC.DEFAULT_FEE_SCHEDULE][LC.FEE_TYPE_PREMIUM] = FeeSchedule({ receiver: receiver, basisPoints: premiumBP });
        s.feeSchedules[LC.DEFAULT_FEE_SCHEDULE][LC.FEE_TYPE_TRADING] = FeeSchedule({ receiver: receiver, basisPoints: tradingBP });
        s.feeSchedules[LC.DEFAULT_FEE_SCHEDULE][LC.FEE_TYPE_INITIAL_SALE] = FeeSchedule({ receiver: receiver, basisPoints: initSaleBP });

        console.log(StdStyle.yellow("PLATFORM FEES SETUP COMPLETE"));

        uint16[] memory zeroBP = new uint16[](1);
        s.feeSchedules[0x3426d806c3a8118219d01b78c44b26983f41f455bd526d58bf68e8d30bc9fb5b][LC.FEE_TYPE_PREMIUM] = FeeSchedule({ receiver: receiver, basisPoints: zeroBP });
        s.feeSchedules[0xab023d09eb3f2cd821b38c355c45b7aaae24711ac087da3c8c45b7e77190577b][LC.FEE_TYPE_PREMIUM] = FeeSchedule({ receiver: receiver, basisPoints: zeroBP });

        rmPlatformCommission(0x8cf246e1ffc63c7d56520b7233e05a8d6dd1fa48d49aa918c128c3768f1e2645);
        rmPlatformCommission(0x7249c272bfe97f529a7535745274e93178c64c7f23703caf3ff26ab06c084394);

        console.log(StdStyle.yellow("PREMIUM FEES OVERRIDE COMPLETE"));

        // ensure token symbol uniqueness, for pTokens and supported external tokens
        s.tokenSymbolObjectId["USDC"] = LibHelpers._getIdForAddress(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        s.tokenSymbolObjectId["NSA01"] = 0xdea30058ce67bbce0dbae527d1ac265828ca8d4d82375d9df75f6451759a8b30;
        s.tokenSymbolObjectId["2104SA1"] = 0x4d08e6fa0cc734574355d6113bc42ca2152ecfd91cf32f37db48d764187c5dbf;
        s.tokenSymbolObjectId["AONSA01"] = 0xf37ea2fbf7e9c42246780e084895bdb31a91a189a0e78d3ca38a8fbe0772d71d;
        s.tokenSymbolObjectId["ILWSA01"] = 0xab023d09eb3f2cd821b38c355c45b7aaae24711ac087da3c8c45b7e77190577b;
        s.tokenSymbolObjectId["KF1SA"] = 0x3426d806c3a8118219d01b78c44b26983f41f455bd526d58bf68e8d30bc9fb5b;

        console.log(StdStyle.yellow("TOKEN SYMBOL UNIQUENESS FIXED"));

        // update role group mappings and assigners
        // Remove system admin from system managers group
        LibACL._updateRoleGroup(LC.ROLE_SYSTEM_ADMIN, LC.GROUP_SYSTEM_MANAGERS, false);

        LibACL._updateRoleGroup(LC.ROLE_SYSTEM_UNDERWRITER, LC.GROUP_SYSTEM_UNDERWRITERS, true);

        LibACL._updateRoleGroup(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_SYSTEM_MANAGERS, true);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_CP, LC.GROUP_SYSTEM_MANAGERS);

        LibACL._updateRoleGroup(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_MANAGERS, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_MANAGER, LC.GROUP_MANAGERS, true);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_BROKER, LC.GROUP_MANAGERS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_INSURED, LC.GROUP_MANAGERS);

        LibACL._updateRoleGroup(LC.ROLE_ENTITY_MANAGER, LC.GROUP_ENTITY_MANAGERS, true);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.GROUP_ENTITY_MANAGERS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_COMPTROLLER_WITHDRAW, LC.GROUP_ENTITY_MANAGERS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_COMPTROLLER_CLAIM, LC.GROUP_ENTITY_MANAGERS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_COMPTROLLER_DIVIDEND, LC.GROUP_ENTITY_MANAGERS);

        LibACL._updateRoleAssigner(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_SYSTEM_ADMINS);
        LibACL._updateRoleAssigner(LC.ROLE_SYSTEM_UNDERWRITER, LC.GROUP_SYSTEM_ADMINS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_ADMIN, LC.GROUP_SYSTEM_ADMINS);
        LibACL._updateRoleAssigner(LC.ROLE_ENTITY_MANAGER, LC.GROUP_SYSTEM_ADMINS);

        // Setup roles which can call functions
        LibACL._updateRoleGroup(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_START_TOKEN_SALE, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_MANAGER, LC.GROUP_START_TOKEN_SALE, true);

        LibACL._updateRoleGroup(LC.ROLE_ENTITY_MANAGER, LC.GROUP_CANCEL_OFFER, true);
        LibACL._updateRoleGroup(LC.ROLE_ENTITY_CP, LC.GROUP_CANCEL_OFFER, true);

        LibACL._updateRoleGroup(LC.ROLE_ENTITY_CP, LC.GROUP_EXECUTE_LIMIT_OFFER, true);

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

        console.log(StdStyle.green("ROLES AND GROUPS SETUP COMPLETE"));
    }

    function rmPlatformCommission(bytes32 policyId) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        SimplePolicy storage sp = s.simplePolicies[policyId];

        uint256 count = sp.commissionReceivers.length;
        for (uint256 i = 1; i < count; ++i) {
            uint256 index = count - i;
            bytes32 receiver = sp.commissionReceivers[index];

            if (
                receiver == LibHelpers._stringToBytes32(LC.NAYMS_LTD_IDENTIFIER) ||
                receiver == LibHelpers._stringToBytes32(LC.NDF_IDENTIFIER) ||
                receiver == LibHelpers._stringToBytes32(LC.STM_IDENTIFIER)
            ) {
                sp.commissionReceivers.pop();
                sp.commissionBasisPoints.pop();
            } else {
                break;
            }
        }
    }
}
