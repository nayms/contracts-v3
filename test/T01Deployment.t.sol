// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { StdStorage, stdStorage } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { D03ProtocolDefaults } from "./defaults/D03ProtocolDefaults.sol";

import { InitDiamondFixture } from "./fixtures/InitDiamondFixture.sol";
import { IDiamondLoupe } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";
import { DiamondAlreadyInitialized } from "src/init/InitDiamond.sol";
import { LibGovernance } from "src/libs/LibGovernance.sol";

import { IERC165 } from "lib/diamond-2-hardhat/contracts/interfaces/IERC165.sol";
import { IERC173 } from "lib/diamond-2-hardhat/contracts/interfaces/IERC173.sol";
import { IERC20 } from "../src/interfaces/IERC20.sol";

contract T01DeploymentTest is D03ProtocolDefaults {
    using stdStorage for StdStorage;

    function setUp() public {}

    function testOwnerOfDiamond() public {
        assertEq(nayms.owner(), owner);
    }

    function testDiamondLoupeFunctionality() public view {
        IDiamondLoupe.Facet[] memory facets = nayms.facets();

        for (uint256 i = 0; i < facets.length; i++) {
            nayms.facetFunctionSelectors(facets[i].facetAddress);
        }

        nayms.facetAddresses();
    }

    function testInitDiamond() public skipWhenForking {
        InitDiamondFixture fixture = new InitDiamondFixture();

        changePrank(owner);
        vm.recordLogs();

        fixture.init(systemAdmin);

        // check logs
        Vm.Log[] memory entries = vm.getRecordedLogs();
        Vm.Log memory entry = entries[entries.length - 1];
        assertEq(entry.topics.length, 1);
        assertEq(entry.topics[0], keccak256("InitializeDiamond(address)"));
        address a = abi.decode(entry.data, (address));
        assertEq(a, owner);

        // check storage
        assertEq(fixture.totalSupply(), 100_000_000e18);
        assertEq(fixture.balanceOf(account0), 100_000_000e18);

        assertTrue(fixture.isObject(0));

        assertEq(fixture.getMaxDividendDenominations(), 1);
    }

    /// @dev For a new diamond using the InitDiamond only.
    function testCallInitDiamondTwice() public skipWhenForking {
        // note: Cannot use the InitDiamond contract more than once to initialize a diamond.
        IDiamondCut.FacetCut[] memory cut;

        bytes32 upgradeHash = LibGovernance._calculateUpgradeId(cut, address(initDiamond), abi.encodeCall(initDiamond.init, (systemAdmin)));

        changePrank(systemAdmin);
        nayms.createUpgrade(upgradeHash);
        changePrank(owner);
        vm.expectRevert(abi.encodePacked(DiamondAlreadyInitialized.selector));
        nayms.diamondCut(cut, address(initDiamond), abi.encodeCall(initDiamond.init, (systemAdmin)));
    }

    function test_supportsInterface() public {
        assertTrue(nayms.supportsInterface(type(IERC165).interfaceId));
        assertTrue(nayms.supportsInterface(type(IDiamondCut).interfaceId));
        assertTrue(nayms.supportsInterface(type(IDiamondLoupe).interfaceId));
        assertTrue(nayms.supportsInterface(type(IERC173).interfaceId));
        assertTrue(nayms.supportsInterface(type(IERC20).interfaceId));
    }
}
