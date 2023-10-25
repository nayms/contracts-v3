// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// solhint-disable no-console
// solhint-disable no-global-import

import "./D00GlobalDefaults.sol";

import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { DiamondProxy } from "src/generated/DiamondProxy.sol";
import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";
import { LibDiamondHelper } from "src/generated/LibDiamondHelper.sol";
import { DeploymentHelpers } from "script/utils/DeploymentHelpers.sol";
import { LibGovernance } from "src/libs/LibGovernance.sol";
import { LibHelpers } from "src/libs/LibHelpers.sol";
import { InitDiamond } from "src/init/InitDiamond.sol";

/// @notice Default test setup part 01
///         Deploy and initialize Nayms platform
abstract contract D01Deployment is D00GlobalDefaults, DeploymentHelpers {
    using LibHelpers for *;

    address public naymsAddress;

    IDiamondProxy public nayms;
    InitDiamond public initDiamond;

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
        console2.log("block.chainid", block.chainid);

        // TODO KP help!
        // bool BOOL_FORK_TEST = vm.envOr({ name: "BOOL_FORK_TEST", defaultValue: false });
        // if (BOOL_FORK_TEST) {
        //     uint256 FORK_BLOCK = vm.envOr({ name: string.concat("FORK_BLOCK_", vm.toString(block.chainid)), defaultValue: type(uint256).max });
        //     console2.log("FORK_BLOCK", FORK_BLOCK);

        //     if (FORK_BLOCK == type(uint256).max) {
        //         console2.log("Using latest block for fork, consider pinning a block number to avoid overloading the RPC endpoint");
        //         vm.createSelectFork(getChain(block.chainid).rpcUrl);
        //     } else {
        //         vm.createSelectFork(getChain(block.chainid).rpcUrl, FORK_BLOCK);
        //     }

        //     naymsAddress = getDiamondAddressFromFile();
        //     nayms = INayms(naymsAddress);

        //     deployer = address(this);
        //     owner = nayms.owner();
        //     vm.label(owner, "Owner");
        //     systemAdmin = vm.envOr({ name: string.concat("SYSTEM_ADMIN_", vm.toString(block.chainid)), defaultValue: address(0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929) });
        //     systemAdminId = LibHelpers._getIdForAddress(systemAdmin);
        //     vm.label(systemAdmin, "System Admin");

        //     string[] memory facetsToCutIn;
        //     keyToReadDiamondAddress = string.concat(".", vm.toString(block.chainid));
        //     IDiamondCut.FacetCut[] memory cut = facetDeploymentAndCut(naymsAddress, FacetDeploymentAction.UpgradeFacetsWithChangesOnly, facetsToCutIn);
        //     vm.startPrank(owner);
        //     scheduleAndUpgradeDiamond(cut);
        // } else {
        console2.log("Local testing (no fork)");

        deployer = address(this);
        owner = address(this);
        vm.startPrank(deployer);

        vm.label(account0, "Account 0 (Test Contract address, deployer, owner)");
        systemAdmin = makeAddr("System Admin 0");
        systemAdminId = LibHelpers._getIdForAddress(systemAdmin);

        console2.log("Deploy diamond");
        naymsAddress = address(new DiamondProxy(account0));
        vm.label(naymsAddress, "Nayms diamond");
        nayms = IDiamondProxy(naymsAddress);

        // deploy all facets
        IDiamondCut.FacetCut[] memory cuts = LibDiamondHelper.deployFacetsAndGetCuts(address(nayms));

        initDiamond = new InitDiamond();
        vm.label(address(initDiamond), "InitDiamond");
        console2.log("InitDiamond:", address(initDiamond));

        console2.log("Cut and init");
        nayms.diamondCut(cuts, address(initDiamond), abi.encodeCall(InitDiamond.init, (systemAdmin)));

        console2.log("Diamond setup complete.");
    }

    function scheduleAndUpgradeDiamond(IDiamondCut.FacetCut[] memory _cut, address _init, bytes memory _calldata) internal {
        // 1. schedule upgrade
        // 2. upgrade
        bytes32 upgradeHash = LibGovernance._calculateUpgradeId(_cut, _init, _calldata);
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
