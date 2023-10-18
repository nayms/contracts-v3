// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// solhint-disable no-console
// solhint-disable no-global-import

import "./D00GlobalDefaults.sol";

import { InitDiamond } from "src/diamonds/nayms/InitDiamond.sol";
import { INayms, IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import { Nayms } from "src/diamonds/nayms/Nayms.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";

import { LibGeneratedNaymsFacetHelpers } from "script/utils/LibGeneratedNaymsFacetHelpers.sol";
import { DeploymentHelpers } from "script/utils/DeploymentHelpers.sol";
import { LibConstants as LC } from "src/diamonds/nayms/libs/LibConstants.sol";
import { StdStyle } from "forge-std/StdStyle.sol";

/// @notice Default test setup part 01
///         Deploy and initialize Nayms platform
abstract contract D01Deployment is D00GlobalDefaults, DeploymentHelpers {
    using LibHelpers for *;
    using StdStyle for *;

    InitDiamond public initDiamond;
    Nayms public naymsContract;
    address public naymsAddress;
    INayms public nayms;

    //// test constant variables ////
    bytes32 public immutable salt = keccak256(bytes("A salt!"));

    address public deployer;
    address public owner;
    address public systemAdmin;
    bytes32 public systemAdminId;

    INayms.FacetCut[] CUT_STRUCT;

    struct NaymsAccount {
        bytes32 id;
        bytes32 entityId;
        uint256 pk;
        address addr;
    }

    function makeNaymsAcc(string memory name) public returns (NaymsAccount memory) {
        (address addr, uint256 privateKey) = makeAddrAndKey(name);
        return NaymsAccount({ id: LibHelpers._getIdForAddress(addr), entityId: keccak256(bytes(name)), pk: privateKey, addr: addr });
    }

    /// @dev Pass in a NaymsAccount to change the prank to NaymsAccount.addr
    function changePrank(NaymsAccount memory na) public {
        changePrank(na.addr);
    }

    constructor() payable {
        c.log("block.chainid", block.chainid);

        bool BOOL_FORK_TEST = vm.envOr({ name: "BOOL_FORK_TEST", defaultValue: false });
        c.log("Are tests being run on a fork?".yellow().bold(), BOOL_FORK_TEST);
        bool TESTS_FORK_UPGRADE_DIAMOND = vm.envOr({ name: "TESTS_FORK_UPGRADE_DIAMOND", defaultValue: true });
        c.log("Are we testing diamond upgrades on a fork?".yellow().bold(), TESTS_FORK_UPGRADE_DIAMOND);

        if (BOOL_FORK_TEST) {
            uint256 FORK_BLOCK = vm.envOr({ name: string.concat("FORK_BLOCK_", vm.toString(block.chainid)), defaultValue: type(uint256).max });
            c.log("FORK_BLOCK", FORK_BLOCK);

            if (FORK_BLOCK == type(uint256).max) {
                c.log("Using latest block for fork, consider pinning a block number to avoid overloading the RPC endpoint");
                vm.createSelectFork(getChain(block.chainid).rpcUrl);
            } else {
                vm.createSelectFork(getChain(block.chainid).rpcUrl, FORK_BLOCK);
            }

            naymsAddress = getDiamondAddressFromFile();
            nayms = INayms(naymsAddress);

            deployer = address(this);
            owner = nayms.owner();
            vm.label(owner, "Owner");
            systemAdmin = vm.envOr({ name: string.concat("SYSTEM_ADMIN_", vm.toString(block.chainid)), defaultValue: address(0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929) });
            systemAdminId = LibHelpers._getIdForAddress(systemAdmin);
            vm.label(systemAdmin, "System Admin");

            string[] memory facetsToCutIn;
            keyToReadDiamondAddress = string.concat(".", vm.toString(block.chainid));
            IDiamondCut.FacetCut[] memory cut = facetDeploymentAndCut(naymsAddress, FacetDeploymentAction.UpgradeFacetsWithChangesOnly, facetsToCutIn);
            vm.startPrank(owner);
            if (TESTS_FORK_UPGRADE_DIAMOND) scheduleAndUpgradeDiamond(cut);
        } else {
            c.log("Local testing (no fork)");

            deployer = address(this);
            owner = address(this);
            vm.startPrank(deployer);

            // deploy the init contract
            initDiamond = new InitDiamond();
            c.log("InitDiamond address", address(initDiamond));
            vm.label(address(initDiamond), "InitDiamond");
            // deploy all facets
            address[] memory naymsFacetAddresses = LibGeneratedNaymsFacetHelpers.deployNaymsFacets();

            vm.label(account0, "Account 0 (Test Contract address, deployer, owner)");
            systemAdmin = makeAddr("System Admin 0");
            systemAdminId = LibHelpers._getIdForAddress(systemAdmin);

            naymsContract = new Nayms(owner, systemAdmin);
            nayms = INayms(address(naymsContract));
            naymsAddress = address(nayms);
            // initialize the diamond as well as cut in all facets
            INayms.FacetCut[] memory cut = LibGeneratedNaymsFacetHelpers.createNaymsDiamondFunctionsCut(naymsFacetAddresses);
            INayms.FacetCut[] memory cut2 = removeStruct(cut, getFacetIndex("ACL"));
            INayms.FacetCut[] memory cut3 = removeStruct(cut2, getFacetIndex("Governance") - 1);
            scheduleAndUpgradeDiamond(cut3, address(initDiamond), abi.encodeCall(initDiamond.initialize, ()));

            // Remove system admin from system managers group
            nayms.updateRoleGroup(LC.ROLE_SYSTEM_ADMIN, LC.GROUP_SYSTEM_MANAGERS, false);

            nayms.updateRoleGroup(LC.ROLE_SYSTEM_UNDERWRITER, LC.GROUP_SYSTEM_UNDERWRITERS, true);

            nayms.updateRoleGroup(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_SYSTEM_MANAGERS, true);
            nayms.updateRoleAssigner(LC.ROLE_ENTITY_CP, LC.GROUP_SYSTEM_MANAGERS);

            nayms.updateRoleGroup(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_MANAGERS, true);
            nayms.updateRoleGroup(LC.ROLE_ENTITY_MANAGER, LC.GROUP_MANAGERS, true);
            nayms.updateRoleAssigner(LC.ROLE_ENTITY_BROKER, LC.GROUP_MANAGERS);
            nayms.updateRoleAssigner(LC.ROLE_ENTITY_INSURED, LC.GROUP_MANAGERS);

            nayms.updateRoleGroup(LC.ROLE_ENTITY_MANAGER, LC.GROUP_ENTITY_MANAGERS, true);
            nayms.updateRoleAssigner(LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.GROUP_ENTITY_MANAGERS);
            nayms.updateRoleAssigner(LC.ROLE_ENTITY_COMPTROLLER_WITHDRAW, LC.GROUP_ENTITY_MANAGERS);
            nayms.updateRoleAssigner(LC.ROLE_ENTITY_COMPTROLLER_CLAIM, LC.GROUP_ENTITY_MANAGERS);
            nayms.updateRoleAssigner(LC.ROLE_ENTITY_COMPTROLLER_DIVIDEND, LC.GROUP_ENTITY_MANAGERS);

            nayms.updateRoleAssigner(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_SYSTEM_ADMINS);
            nayms.updateRoleAssigner(LC.ROLE_SYSTEM_UNDERWRITER, LC.GROUP_SYSTEM_ADMINS);
            nayms.updateRoleAssigner(LC.ROLE_ENTITY_ADMIN, LC.GROUP_SYSTEM_ADMINS);
            nayms.updateRoleAssigner(LC.ROLE_ENTITY_MANAGER, LC.GROUP_SYSTEM_ADMINS);

            // Setup roles which can call functions
            nayms.updateRoleGroup(LC.ROLE_SYSTEM_MANAGER, LC.GROUP_START_TOKEN_SALE, true);
            nayms.updateRoleGroup(LC.ROLE_ENTITY_MANAGER, LC.GROUP_START_TOKEN_SALE, true);

            nayms.updateRoleGroup(LC.ROLE_ENTITY_MANAGER, LC.GROUP_CANCEL_OFFER, true);
            nayms.updateRoleGroup(LC.ROLE_ENTITY_CP, LC.GROUP_CANCEL_OFFER, true);

            nayms.updateRoleGroup(LC.ROLE_ENTITY_CP, LC.GROUP_EXECUTE_LIMIT_OFFER, true);

            nayms.updateRoleGroup(LC.ROLE_ENTITY_BROKER, LC.GROUP_PAY_SIMPLE_PREMIUM, true);
            nayms.updateRoleGroup(LC.ROLE_ENTITY_INSURED, LC.GROUP_PAY_SIMPLE_PREMIUM, true);

            nayms.updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.GROUP_PAY_SIMPLE_CLAIM, true);
            nayms.updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_CLAIM, LC.GROUP_PAY_SIMPLE_CLAIM, true);

            nayms.updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.GROUP_PAY_DIVIDEND_FROM_ENTITY, true);
            nayms.updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_DIVIDEND, LC.GROUP_PAY_DIVIDEND_FROM_ENTITY, true);

            nayms.updateRoleGroup(LC.ROLE_ENTITY_ADMIN, LC.GROUP_EXTERNAL_DEPOSIT, true);
            nayms.updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.GROUP_EXTERNAL_DEPOSIT, true);
            nayms.updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_WITHDRAW, LC.GROUP_EXTERNAL_DEPOSIT, true);

            nayms.updateRoleGroup(LC.ROLE_ENTITY_ADMIN, LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY, true);
            nayms.updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_COMBINED, LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY, true);
            nayms.updateRoleGroup(LC.ROLE_ENTITY_COMPTROLLER_WITHDRAW, LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY, true);
        }
    }

    function scheduleAndUpgradeDiamond(
        IDiamondCut.FacetCut[] memory _cut,
        address _init,
        bytes memory _calldata
    ) internal {
        // 1. schedule upgrade
        // 2. upgrade
        bytes32 upgradeHash = keccak256(abi.encode(_cut, _init, _calldata));
        if (upgradeHash == 0xc597f3eb22d11c46f626cd856bd65e9127b04623d83e442686776a2e3b670bbf) {
            c.log("There are no facets to upgrade. This hash is the keccak256 hash of an empty IDiamondCut.FacetCut[]");
        } else {
            changePrank(systemAdmin);
            nayms.createUpgrade(upgradeHash);
            changePrank(owner);
            nayms.diamondCut(_cut, _init, _calldata);
            changePrank(systemAdmin);
        }
    }

    function scheduleAndUpgradeDiamond(IDiamondCut.FacetCut[] memory _cut) internal {
        scheduleAndUpgradeDiamond(_cut, address(0), "");
    }

    function removeStruct(INayms.FacetCut[] memory inputArray, uint256 indexToRemove) public pure returns (INayms.FacetCut[] memory) {
        require(indexToRemove < inputArray.length, "Index out of bounds");

        c.log("REMOVING STRUCT".green().bold());
        INayms.FacetCut[] memory newArray = new INayms.FacetCut[](inputArray.length - 1);
        uint256 j;
        for (uint256 i; i < inputArray.length; i++) {
            if (i != indexToRemove) {
                newArray[j] = inputArray[i];
                j++;
            }
        }

        return newArray;
    }

    function getFacetIndex(string memory facetName) public pure returns (uint256) {
        string[] memory facetNames = LibGeneratedNaymsFacetHelpers.getFacetNames();
        for (uint256 i; i < facetNames.length; i++) {
            if (keccak256(abi.encodePacked(facetNames[i])) == keccak256(abi.encodePacked(facetName))) {
                return (i);
            }
        }
    }
}
