// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable-next-line no-global-import
import "./defaults/D03ProtocolDefaults.sol";
import { MockAccounts } from "test/utils/users/MockAccounts.sol";

import "src/diamonds/nayms/interfaces/CustomErrors.sol";
import { LibACL } from "../src/diamonds/nayms/libs/LibACL.sol";
import { Entity } from "../src/diamonds/nayms/AppStorage.sol";
import { IDiamondCut } from "src/diamonds/shared/interfaces/IDiamondCut.sol";

/// @dev Testing for Nayms upgrade pattern

contract TestFacet {
    function sayHello() external pure returns (string memory greeting) {
        greeting = "hello";
    }

    function sayHello2() external pure returns (string memory greeting) {
        greeting = "hello2";
    }
}

contract T01GovernanceUpgrades is D03ProtocolDefaults, MockAccounts {
    uint256 public constant STARTING_BLOCK_TIMESTAMP = 100;
    address public testFacetAddress;

    function setUp() public virtual override {
        super.setUp();

        testFacetAddress = address(new TestFacet());

        // todo handle block timestamp
        // warp so block.timestamp does not = 0, otherwise all upgrades will be "scheduled".
        vm.warp(STARTING_BLOCK_TIMESTAMP);
    }

    function testUnscheduledGovernanceUpgrade() public {
        IDiamondCut.FacetCut[] memory cut;
        cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory f0 = new bytes4[](1);
        f0 = new bytes4[](1);
        f0[0] = TestFacet.sayHello.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(testFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: f0 });

        // try to call diamondCut() without scheduling
        vm.expectRevert("upgrade is not valid");
        nayms.diamondCut(cut, address(0), "");
    }

    function testExpiredGovernanceUpgrade() public {
        IDiamondCut.FacetCut[] memory cut;
        cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory f0 = new bytes4[](1);
        f0 = new bytes4[](1);
        f0[0] = TestFacet.sayHello.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(testFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: f0 });

        vm.warp(7 days + STARTING_BLOCK_TIMESTAMP + 1);
        // try to call diamondCut() without scheduling
        vm.expectRevert("upgrade is not valid");
        nayms.diamondCut(cut, address(0), "");
    }

    function testGovernanceUpgrade() public {
        IDiamondCut.FacetCut[] memory cut;
        cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory f0 = new bytes4[](1);
        f0 = new bytes4[](1);
        f0[0] = TestFacet.sayHello.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(testFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: f0 });

        nayms.createUpgrade(keccak256(abi.encode(cut)));

        changePrank(deployer);
        nayms.diamondCut(cut, address(0), "");

        bytes memory call = abi.encodeCall(TestFacet.sayHello, ());

        (bool success, ) = address(nayms).call(call);
        assertTrue(success);
    }

    function testMustBeOwnerToDoAGovernanceUpgrade() public {
        IDiamondCut.FacetCut[] memory cut;
        cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory f0 = new bytes4[](1);
        f0 = new bytes4[](1);
        f0[0] = TestFacet.sayHello.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(testFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: f0 });

        nayms.createUpgrade(keccak256(abi.encode(cut)));

        changePrank(address(0xAAAAAAAAA));

        vm.expectRevert("LibDiamond: Must be contract owner");
        nayms.diamondCut(cut, address(0), "");
    }

    function testCancelGovernanceUpgrade() public {
        IDiamondCut.FacetCut[] memory cut;
        cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory f0 = new bytes4[](1);
        f0 = new bytes4[](1);
        f0[0] = TestFacet.sayHello.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(testFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: f0 });

        nayms.createUpgrade(keccak256(abi.encode(cut)));

        nayms.cancelUpgrade(keccak256(abi.encode(cut)));

        // second step, call diamondCut()
        vm.expectRevert("upgrade is not valid");
        nayms.diamondCut(cut, address(0), "");
    }

    function testScheduleTheSameGovernanceUpgradeBeforeExpiration() public {
        IDiamondCut.FacetCut[] memory cut;
        cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory f0 = new bytes4[](1);
        f0 = new bytes4[](1);
        f0[0] = TestFacet.sayHello.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(testFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: f0 });

        nayms.createUpgrade(keccak256(abi.encode(cut)));

        vm.expectRevert("Upgrade has already been scheduled");
        nayms.createUpgrade(keccak256(abi.encode(cut)));

        vm.warp(7 days + STARTING_BLOCK_TIMESTAMP + 1);

        /// note: don't need to cancel an upgrade if it has already expired
        nayms.createUpgrade(keccak256(abi.encode(cut)));
    }

    function testGovernanceUpgradeMultiple() public {
        IDiamondCut.FacetCut[] memory cut;
        cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory f0 = new bytes4[](1);
        f0 = new bytes4[](1);
        f0[0] = TestFacet.sayHello.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(testFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: f0 });

        nayms.createUpgrade(keccak256(abi.encode(cut)));

        // cut in the method sayHello2()
        IDiamondCut.FacetCut[] memory cut2;
        cut2 = new IDiamondCut.FacetCut[](1);
        bytes4[] memory f1 = new bytes4[](1);
        f1 = new bytes4[](1);
        f1[0] = TestFacet.sayHello2.selector;
        cut2[0] = IDiamondCut.FacetCut({ facetAddress: address(testFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: f1 });

        nayms.createUpgrade(keccak256(abi.encode(cut2)));

        changePrank(deployer);

        nayms.diamondCut(cut, address(0), "");

        nayms.diamondCut(cut2, address(0), "");
    }

    function testUpdateUpgradeExpiration() public {
        IDiamondCut.FacetCut[] memory cut;
        cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory f0 = new bytes4[](1);
        f0 = new bytes4[](1);
        f0[0] = TestFacet.sayHello.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(testFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: f0 });

        nayms.createUpgrade(keccak256(abi.encode(cut)));

        changePrank(address(0xAAAAAAAAA));
        vm.expectRevert("not a system admin");
        nayms.updateUpgradeExpiration(1 days);

        changePrank(systemAdmin);
        nayms.updateUpgradeExpiration(1 days);

        assertEq(block.timestamp + 7 days, nayms.getUpgrade(keccak256(abi.encode(cut))));

        IDiamondCut.FacetCut[] memory cut2;
        cut2 = new IDiamondCut.FacetCut[](1);
        bytes4[] memory f1 = new bytes4[](1);
        f1 = new bytes4[](1);
        f1[0] = TestFacet.sayHello2.selector;
        cut2[0] = IDiamondCut.FacetCut({ facetAddress: address(testFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: f1 });

        nayms.createUpgrade(keccak256(abi.encode(cut2)));
        assertEq(block.timestamp + 1 days, nayms.getUpgrade(keccak256(abi.encode(cut2))));
    }
}
