// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// solhint-disable no-console
// solhint-disable no-global-import

import "forge-std/Test.sol";
import "./D00GlobalDefaults.sol";

import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { DiamondProxy } from "src/generated/DiamondProxy.sol";
import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";
import { LibDiamondHelper } from "src/generated/LibDiamondHelper.sol";
import { LibGovernance } from "src/libs/LibGovernance.sol";
import { LibHelpers } from "src/libs/LibHelpers.sol";
import { InitDiamond } from "src/init/InitDiamond.sol";
import { StdStyle } from "forge-std/StdStyle.sol";
import { LibConstants as LC } from "src/libs/LibConstants.sol";

/// @notice Default test setup part 01
///         Deploy and initialize Nayms platform
abstract contract D01Deployment is D00GlobalDefaults, Test {
    using LibHelpers for *;
    using StdStyle for *;

    address public naymsAddress;

    IDiamondProxy public nayms;
    InitDiamond public initDiamond;

    //// test constant variables ////
    bytes32 public immutable salt = keccak256(bytes("A salt!"));

    address public deployer;
    address public owner;
    address public systemAdmin;
    bytes32 public systemAdminId;

    /// @dev Helper function to create object Ids with object type prefix.
    function makeId(bytes12 _objecType, bytes20 randomBytes) internal pure returns (bytes32) {
        if (_objecType != LC.OBJECT_TYPE_ADDRESS) {
            randomBytes |= bytes20(0x0000000000000000000000000000000000000001);
        }
        return bytes32((_objecType)) | (bytes32(randomBytes) >> 96);
    }

    struct NaymsAccount {
        bytes32 id;
        bytes32 entityId;
        uint256 pk;
        address addr;
    }

    function makeNaymsAcc(string memory name) public returns (NaymsAccount memory) {
        (address addr, uint256 privateKey) = makeAddrAndKey(name);
        return NaymsAccount({ id: LibHelpers._getIdForAddress(addr), entityId: makeId(LC.OBJECT_TYPE_ENTITY, bytes20(keccak256(bytes(name)))), pk: privateKey, addr: addr });
    }

    /// @dev Pass in a NaymsAccount to change the prank to NaymsAccount.addr
    function changePrank(NaymsAccount memory na) public {
        changePrank(na.addr);
    }

    function startPrank(NaymsAccount memory na) public {
        vm.startPrank(na.addr);
    }
    function getDiamondAddress() internal view returns (address diamondAddress) {
        diamondAddress = vm.envAddress(string.concat("TESTS_FORK_DIAMOND_ADDRESS_", vm.toString(block.chainid)));

        c.log(string.concat("Diamond address from env ", "TESTS_FORK_DIAMOND_ADDRESS_", vm.toString(block.chainid)).yellow().bold(), diamondAddress);
    }

    constructor() payable {
        c.log("\n -- D01 Deployment Defaults\n");
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

            naymsAddress = getDiamondAddress();
            nayms = IDiamondProxy(naymsAddress);

            deployer = address(this);
            owner = nayms.owner();
            vm.label(owner, "Owner");
            systemAdmin = vm.envOr({ name: string.concat("SYSTEM_ADMIN_", vm.toString(block.chainid)), defaultValue: address(0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929) });
            systemAdminId = LibHelpers._getIdForAddress(systemAdmin);
            vm.label(systemAdmin, "System Admin");

            vm.startPrank(owner);
            if (TESTS_FORK_UPGRADE_DIAMOND) {
                IDiamondCut.FacetCut[] memory cut = LibDiamondHelper.deployFacetsAndGetCuts(naymsAddress);
                scheduleAndUpgradeDiamond(cut);
            }
        } else {
            c.log("Local testing (no fork)");

            deployer = address(this);
            owner = address(this);
            vm.startPrank(deployer);

            vm.label(account0, "Account 0 (Test Contract address, deployer, owner)");
            systemAdmin = makeAddr("System Admin 0");
            systemAdminId = LibHelpers._getIdForAddress(systemAdmin);

            c.log("Deploy diamond");
            naymsAddress = address(new DiamondProxy(account0));
            vm.label(naymsAddress, "Nayms diamond");
            nayms = IDiamondProxy(naymsAddress);

            // deploy all facets
            IDiamondCut.FacetCut[] memory cuts = LibDiamondHelper.deployFacetsAndGetCuts(address(nayms));

            initDiamond = new InitDiamond();
            vm.label(address(initDiamond), "InitDiamond");
            c.log("InitDiamond:", address(initDiamond));

            c.log("Cut and init");
            nayms.diamondCut(cuts, address(initDiamond), abi.encodeCall(InitDiamond.init, (systemAdmin)));

            c.log("Diamond setup complete.");
        }
    }

    function scheduleAndUpgradeDiamond(IDiamondCut.FacetCut[] memory _cut, address _init, bytes memory _calldata) internal {
        bytes32[] memory codeHashes = new bytes32[](_cut.length);
        for (uint i; i < _cut.length; i++) {
            codeHashes[i] = LibGovernance._getCodeHash(_cut[i].facetAddress);
        }
        bytes32 upgradeHash = LibGovernance._calculateUpgradeId(codeHashes, _init, _calldata);
        if (upgradeHash == 0xc597f3eb22d11c46f626cd856bd65e9127b04623d83e442686776a2e3b670bbf) {
            c.log("There are no facets to upgrade. This hash is the keccak256 hash of an empty IDiamondCut.FacetCut[]");
        } else {
            changePrank(systemAdmin);
            // 1. schedule upgrade
            nayms.createUpgrade(upgradeHash);
            changePrank(owner);
            // 2. upgrade
            nayms.diamondCut(_cut, _init, _calldata);
            changePrank(systemAdmin);
        }
    }

    function scheduleAndUpgradeDiamond(IDiamondCut.FacetCut[] memory _cut) internal {
        scheduleAndUpgradeDiamond(_cut, address(0), "");
    }
}
