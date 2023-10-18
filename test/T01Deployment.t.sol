// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { StdStorage, stdStorage } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { D03ProtocolDefaults } from "./defaults/D03ProtocolDefaults.sol";

import { InitDiamondFixture } from "./fixtures/InitDiamondFixture.sol";
import { INayms, IDiamondLoupe } from "src/diamonds/nayms/INayms.sol";
import { DiamondAlreadyInitialized } from "src/diamonds/nayms/InitDiamond.sol";

import { IERC165 } from "../src/diamonds/shared/interfaces/IERC165.sol";
import { IDiamondCut } from "../src/diamonds/shared/interfaces/IDiamondCut.sol";
import { IERC173 } from "../src/diamonds/shared/interfaces/IERC173.sol";
import { IERC20 } from "../src/erc20/IERC20.sol";
import { IACLFacet } from "../src/diamonds/nayms/interfaces/IACLFacet.sol";
import { IAdminFacet } from "../src/diamonds/nayms/interfaces/IAdminFacet.sol";
import { IEntityFacet } from "../src/diamonds/nayms/interfaces/IEntityFacet.sol";
import { IMarketFacet } from "../src/diamonds/nayms/interfaces/IMarketFacet.sol";
import { INaymsTokenFacet } from "../src/diamonds/nayms/interfaces/INaymsTokenFacet.sol";
import { ISimplePolicyFacet } from "../src/diamonds/nayms/interfaces/ISimplePolicyFacet.sol";
import { ISystemFacet } from "../src/diamonds/nayms/interfaces/ISystemFacet.sol";
import { ITokenizedVaultFacet } from "../src/diamonds/nayms/interfaces/ITokenizedVaultFacet.sol";
import { ITokenizedVaultIOFacet } from "../src/diamonds/nayms/interfaces/ITokenizedVaultIOFacet.sol";
import { IUserFacet } from "../src/diamonds/nayms/interfaces/IUserFacet.sol";
import { IGovernanceFacet } from "../src/diamonds/nayms/interfaces/IGovernanceFacet.sol";

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

        fixture.initialize();

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
        INayms.FacetCut[] memory cut;

        bytes32 upgradeHash = keccak256(abi.encode(cut, address(initDiamond), abi.encodeCall(initDiamond.initialize, ())));

        changePrank(systemAdmin);
        nayms.createUpgrade(upgradeHash);
        changePrank(owner);
        vm.expectRevert(abi.encodePacked(DiamondAlreadyInitialized.selector));
        nayms.diamondCut(cut, address(initDiamond), abi.encodeCall(initDiamond.initialize, ()));
    }

    function test_supportsInterface() public {
        assertTrue(nayms.supportsInterface(type(IERC165).interfaceId));
        assertTrue(nayms.supportsInterface(type(IDiamondCut).interfaceId));
        assertTrue(nayms.supportsInterface(type(IDiamondLoupe).interfaceId));
        assertTrue(nayms.supportsInterface(type(IERC173).interfaceId));
        assertTrue(nayms.supportsInterface(type(IERC20).interfaceId));

        assertTrue(nayms.supportsInterface(type(IACLFacet).interfaceId));
        assertTrue(nayms.supportsInterface(type(IAdminFacet).interfaceId));
        assertTrue(nayms.supportsInterface(type(IEntityFacet).interfaceId));
        assertTrue(nayms.supportsInterface(type(IGovernanceFacet).interfaceId));
        assertTrue(nayms.supportsInterface(type(IMarketFacet).interfaceId));
        assertTrue(nayms.supportsInterface(type(INaymsTokenFacet).interfaceId));
        assertTrue(nayms.supportsInterface(type(ISimplePolicyFacet).interfaceId));
        assertTrue(nayms.supportsInterface(type(ISystemFacet).interfaceId));
        assertTrue(nayms.supportsInterface(type(ITokenizedVaultFacet).interfaceId));
        assertTrue(nayms.supportsInterface(type(ITokenizedVaultIOFacet).interfaceId));
        assertTrue(nayms.supportsInterface(type(IUserFacet).interfaceId));
    }
}
