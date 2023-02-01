// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D03ProtocolDefaults, console2, LibAdmin, LibConstants, LibHelpers, LibObject } from "./defaults/D03ProtocolDefaults.sol";
import { MockAccounts } from "test/utils/users/MockAccounts.sol";
import { LibACL } from "../src/diamonds/nayms/libs/LibACL.sol";
import { Entity } from "../src/diamonds/nayms/AppStorage.sol";
import "src/diamonds/nayms/interfaces/CustomErrors.sol";
import { IDiamondCut } from "src/diamonds/shared/interfaces/IDiamondCut.sol";
import { DiamondCutFacet } from "src/diamonds/shared/facets/PhasedDiamondCutFacet.sol";

/// @dev Testing for Nayms RBAC - Access Control List (ACL)

contract TestFacet {
    function sayHello() external returns (string memory greeting) {
        greeting = "hello";
    }
}

contract TUpgrades is D03ProtocolDefaults, MockAccounts {
    function setUp() public virtual override {
        super.setUp();
    }

    function testGovernanceUpgrade() public {
        // Replace diamondCut() with the two phase diamondCut()
        address phasedDiamondCutFacet = address(new DiamondCutFacet());

        IDiamondCut.FacetCut[] memory cut;

        cut = new IDiamondCut.FacetCut[](1);

        bytes4[] memory f0 = new bytes4[](1);
        f0[0] = IDiamondCut.diamondCut.selector;

        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(phasedDiamondCutFacet), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: f0 });

        // replace the diamondCut()
        nayms.diamondCut(cut, address(0), "");

        // test out the new diamondCut()
        address testFacetAddress = address(new TestFacet());
        cut = new IDiamondCut.FacetCut[](1);
        f0 = new bytes4[](1);
        f0[0] = TestFacet.sayHello.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(testFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: f0 });

        // warp so block.timestamp does not = 0, otherwise all upgrades will be "scheduled".
        vm.warp(100);
        // try to call diamondCut() without scheduling
        vm.expectRevert("upgrade is not scheduled");
        nayms.diamondCut(cut, address(0), "");

        // first step of two phase diamond cut upgrade
        nayms.createUpgrade(keccak256(abi.encode(cut)));

        // second step, call diamondCut()
        nayms.diamondCut(cut, address(0), "");
    }
}
