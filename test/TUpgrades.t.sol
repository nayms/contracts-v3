// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D03ProtocolDefaults, console2, LibAdmin, LibConstants, LibHelpers, LibObject } from "./defaults/D03ProtocolDefaults.sol";
import { MockAccounts } from "test/utils/users/MockAccounts.sol";
import { LibACL } from "../src/diamonds/nayms/libs/LibACL.sol";
import { Entity } from "../src/diamonds/nayms/AppStorage.sol";
import "src/diamonds/nayms/interfaces/CustomErrors.sol";
import { IDiamondCut } from "src/diamonds/shared/interfaces/IDiamondCut.sol";

/// @dev Testing for Nayms RBAC - Access Control List (ACL)

contract TUpgrades is D03ProtocolDefaults, MockAccounts {
    function setUp() public virtual override {
        super.setUp();
    }

    function testGovernanceUpgrade() public {
        address target = address(nayms);
        uint256 value = 0;

        IDiamondCut.FacetCut[] memory cut;

        // nayms.diamondCut(cut, address(0), abi.encodeCall(initDiamond.initialize, ()));

        bytes memory data = abi.encodeCall(IDiamondCut.diamondCut, (cut, address(0), ""));
        bytes32 predecessor;
        bytes32 salt = bytes32("0xF");

        // Construct the transaction to be scheduled
        bytes32 txId = nayms.hashOperation(target, value, data, predecessor, salt);

        uint256 delay = 0;

        // The block timestamp must be >0, otherwise the timestamp will = 0 which means the transaction is not scheduled.
        vm.warp(100);

        // Schedule the transaction
        nayms.schedule(txId, delay);

        // get timestamp
        nayms.getTimestamp(txId);

        // Execute the transaction
        // vm.prank(nayms.owner());
        // todo must change who can call diamondCut() to be the timelock address
        nayms.transferOwnership(address(nayms));
        nayms.execute(target, value, data, predecessor, salt);

        // address[] memory targets;
        // uint256[] memory values;
        // bytes[] memory payloads;

        // nayms.hashOperationBatch(targets, values, payloads, predecessor, salt);

        // // todo this currently passes with a 0 byte payload
        // nayms.scheduleBatch(targets, values, payloads, predecessor, salt, delay);

        // nayms.executeBatch(targets, values, payloads, predecessor, salt);
    }
}
