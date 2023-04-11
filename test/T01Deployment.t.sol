// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable-next-line no-global-import
import "./defaults/D03ProtocolDefaults.sol";

import { InitDiamondFixture } from "./fixtures/InitDiamondFixture.sol";
import { INayms, IDiamondLoupe } from "src/diamonds/nayms/INayms.sol";
import { DiamondAlreadyInitialized } from "src/diamonds/nayms/InitDiamond.sol";
import { CREATE3 } from "solmate/utils/CREATE3.sol";

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
    function setUp() public virtual override {
        super.setUp();
    }

    function testOwnerOfDiamond() public {
        // The owner of the diamond should be the original deployer
        assertEq(nayms.owner(), deployer);
    }

    function testDiamondLoupeFunctionality() public view {
        IDiamondLoupe.Facet[] memory facets = nayms.facets();

        for (uint256 i = 0; i < facets.length; i++) {
            nayms.facetFunctionSelectors(facets[i].facetAddress);
        }

        nayms.facetAddresses();
    }

    function testInitDiamond() public {
        InitDiamondFixture fixture = new InitDiamondFixture();

        vm.recordLogs();

        fixture.initialize();

        // check logs
        Vm.Log[] memory entries = vm.getRecordedLogs();
        Vm.Log memory entry = entries[entries.length - 1];
        assertEq(entry.topics.length, 1);
        assertEq(entry.topics[0], keccak256("InitializeDiamond(address,bytes32)"));
        (address a, bytes32 b) = abi.decode(entry.data, (address, bytes32));
        assertEq(a, account0);
        assertEq(b, account0Id);

        // check storage

        assertEq(fixture.totalSupply(), 100_000_000e18);
        assertEq(fixture.balanceOf(account0), 100_000_000e18);

        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_SYSTEM_ADMIN, LibConstants.GROUP_SYSTEM_ADMINS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_SYSTEM_ADMIN, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_SYSTEM_MANAGER, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_ENTITY_ADMIN, LibConstants.GROUP_ENTITY_ADMINS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_ENTITY_MANAGER, LibConstants.GROUP_ENTITY_MANAGERS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_BROKER, LibConstants.GROUP_BROKERS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_UNDERWRITER, LibConstants.GROUP_UNDERWRITERS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_INSURED_PARTY, LibConstants.GROUP_INSURED_PARTIES));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_CAPITAL_PROVIDER, LibConstants.GROUP_CAPITAL_PROVIDERS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_CLAIMS_ADMIN, LibConstants.GROUP_CLAIMS_ADMINS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_TRADER, LibConstants.GROUP_TRADERS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_SEGREGATED_ACCOUNT, LibConstants.GROUP_SEGREGATED_ACCOUNTS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_SERVICE_PROVIDER, LibConstants.GROUP_SERVICE_PROVIDERS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_BROKER, LibConstants.GROUP_POLICY_HANDLERS));
        assertTrue(fixture.isRoleInGroup(LibConstants.ROLE_INSURED_PARTY, LibConstants.GROUP_POLICY_HANDLERS));

        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_SYSTEM_ADMIN, LibConstants.GROUP_SYSTEM_ADMINS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_SYSTEM_MANAGER, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_ENTITY_ADMIN, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_ENTITY_MANAGER, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_BROKER, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_UNDERWRITER, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_INSURED_PARTY, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_CAPITAL_PROVIDER, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_BROKER, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_INSURED_PARTY, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_UNDERWRITER, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_CLAIMS_ADMIN, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_TRADER, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_SEGREGATED_ACCOUNT, LibConstants.GROUP_SYSTEM_MANAGERS));
        assertTrue(fixture.canGroupAssignRole(LibConstants.ROLE_SERVICE_PROVIDER, LibConstants.GROUP_SYSTEM_MANAGERS));

        assertTrue(fixture.isObject(0));
        assertTrue(fixture.isObject(account0Id));

        assertEq(fixture.getMaxDividendDenominations(), 1);

        // If the following tests fail, it means that the interface in the repo has been updated and does not match the interface in the diamond.
        assertTrue(nayms.supportsInterface(type(IERC165).interfaceId), "IERC165");
        assertTrue(nayms.supportsInterface(type(IDiamondCut).interfaceId), "IDiamondCut");
        assertTrue(nayms.supportsInterface(type(IDiamondLoupe).interfaceId), "IDiamondLoupe");
        assertTrue(nayms.supportsInterface(type(IERC173).interfaceId), "IERC173");
        assertTrue(nayms.supportsInterface(type(IERC20).interfaceId), "IERC20");

        assertTrue(nayms.supportsInterface(type(IACLFacet).interfaceId), "IACLFacet");
        assertTrue(nayms.supportsInterface(type(IAdminFacet).interfaceId), "IAdminFacet");
        assertTrue(nayms.supportsInterface(type(IEntityFacet).interfaceId), "IEntityFacet");
        assertTrue(nayms.supportsInterface(type(IMarketFacet).interfaceId), "IMarketFacet");
        assertTrue(nayms.supportsInterface(type(INaymsTokenFacet).interfaceId), "INaymsTokenFacet");
        assertTrue(nayms.supportsInterface(type(ISimplePolicyFacet).interfaceId), "ISimplePolicyFacet");
        assertTrue(nayms.supportsInterface(type(ISystemFacet).interfaceId), "ISystemFacet");
        assertTrue(nayms.supportsInterface(type(ITokenizedVaultFacet).interfaceId), "ITokenizedVaultFacet");
        assertTrue(nayms.supportsInterface(type(ITokenizedVaultIOFacet).interfaceId), "ITokenizedVaultIOFacet");
        assertTrue(nayms.supportsInterface(type(IUserFacet).interfaceId), "IUserFacet");
        assertTrue(nayms.supportsInterface(type(IGovernanceFacet).interfaceId), "IGovernanceFacet");
    }

    function testCallInitDiamondTwice() public {
        // note: Cannot use the InitDiamond contract more than once to initialize a diamond.
        INayms.FacetCut[] memory cut;

        bytes32 upgradeHash = keccak256(abi.encode(cut));
        nayms.createUpgrade(upgradeHash);
        vm.expectRevert(abi.encodePacked(DiamondAlreadyInitialized.selector));
        changePrank(deployer);
        nayms.diamondCut(cut, address(initDiamond), abi.encodeCall(initDiamond.initialize, ()));
    }
}
