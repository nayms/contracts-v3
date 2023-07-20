// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable no-console
// solhint-disable no-global-import

import "./D00GlobalDefaults.sol";

import { InitDiamond } from "src/diamonds/nayms/InitDiamond.sol";
import { INayms, IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import { Nayms } from "src/diamonds/nayms/Nayms.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";

import { LibGeneratedNaymsFacetHelpers } from "script/utils/LibGeneratedNaymsFacetHelpers.sol";
import { DeploymentHelpers } from "script/utils/DeploymentHelpers.sol";

/// @notice Default test setup part 01
///         Deploy and initialize Nayms platform
abstract contract D01Deployment is D00GlobalDefaults, DeploymentHelpers {
    using LibHelpers for *;
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

    constructor() payable {
        uint256 FORK_BLOCK = vm.envOr({ name: string.concat(vm.toString(block.chainid), "_FORK_BLOCK"), defaultValue: type(uint256).max });
        if (block.chainid != 0) {
            if (FORK_BLOCK == type(uint256).max) {
                console2.log("Using latest block for fork, consider pinning a block number to avoid overloading the RPC endpoint");
                vm.createSelectFork(getChain(block.chainid).rpcUrl);
            } else {
                vm.createSelectFork(getChain(block.chainid).rpcUrl, FORK_BLOCK);
            }
            naymsAddress = 0x39e2f550fef9ee15b459d16bD4B243b04b1f60e5;
            nayms = INayms(naymsAddress);

            deployer = address(this);
            owner = nayms.owner();
            vm.label(owner, "Owner");
            systemAdmin = 0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929;
            systemAdminId = LibHelpers._getIdForAddress(systemAdmin);
            vm.label(systemAdmin, "System Admin");

            string[] memory facetsToCutIn;
            keyToReadDiamondAddress = string.concat(".", vm.toString(block.chainid));
            IDiamondCut.FacetCut[] memory cut = facetDeploymentAndCut(getDiamondAddressFromFile(), FacetDeploymentAction.UpgradeFacetsWithChangesOnly, facetsToCutIn);
            vm.startPrank(owner);
            scheduleAndUpgradeDiamond(cut);
        } else {
            console2.log("Isolated testing (no fork)");

            deployer = address(this);
            owner = address(this);
            vm.startPrank(deployer);

            // deploy the init contract
            initDiamond = new InitDiamond();
            console2.log("InitDiamond address", address(initDiamond));
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
            scheduleAndUpgradeDiamond(cut, address(initDiamond), abi.encodeCall(initDiamond.initialize, ()));
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
            console2.log("There are no facets to upgrade. This hash is the keccak256 hash of an empty IDiamondCut.FacetCut[]");
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
}
