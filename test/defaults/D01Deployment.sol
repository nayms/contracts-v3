// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./D00GlobalDefaults.sol";

import { InitDiamond } from "src/diamonds/nayms/InitDiamond.sol";
import { INayms, IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import { Nayms } from "src/diamonds/nayms/Nayms.sol";
import { LibAdmin } from "src/diamonds/nayms/libs/LibAdmin.sol";
import { LibConstants } from "src/diamonds/nayms/libs/LibConstants.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";
import { LibObject } from "src/diamonds/nayms/libs/LibObject.sol";
import { LibSimplePolicy } from "src/diamonds/nayms/libs/LibSimplePolicy.sol";

import { LibGeneratedNaymsFacetHelpers } from "script/utils/LibGeneratedNaymsFacetHelpers.sol";

// import { DSILib } from "../utils/DSILib.sol";

// import { DeploymentHelpers } from "script/utils/DeploymentHelpers.sol";

/// @notice Default test setup part 01
///         Deploy and initialize Nayms platform
contract D01Deployment is D00GlobalDefaults /*, DeploymentHelpers*/ {
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

    Nayms public naymsContract;
    address public naymsAddress;
    InitDiamond public initDiamond;

    INayms public nayms;
    //// test constant variables ////
    bytes32 public immutable salt = keccak256(bytes("A salt!"));

    address public systemAdmin;
    bytes32 public systemAdminId;
    address public owner;
    address public deployer;

    function setUp() public virtual override {
        super.setUp();

        // deploy the init contract
        initDiamond = new InitDiamond();

        // deploy all facets
        address[] memory naymsFacetAddresses = LibGeneratedNaymsFacetHelpers.deployNaymsFacets();

        owner = account0;
        deployer = account0;
        vm.label(account0, "Account 0 (Test Contract address, deployer, owner)");

        systemAdmin = makeAddr("System Admin 0");
        systemAdminId = LibHelpers._getIdForAddress(systemAdmin);

        naymsContract = new Nayms(owner, systemAdmin);
        nayms = INayms(address(naymsContract));

        naymsAddress = address(nayms);
        // initialize the diamond as well as cut in all facets
        INayms.FacetCut[] memory cut = LibGeneratedNaymsFacetHelpers.createNaymsDiamondFunctionsCut(naymsFacetAddresses);

        nayms.diamondCut(cut, address(initDiamond), abi.encodeCall(initDiamond.initialize, ()));
    }

    function scheduleAndUpgradeDiamond(IDiamondCut.FacetCut[] memory _cut) internal {
        // 1. schedule upgrade
        // 2. upgrade
        bytes32 upgradeHash = keccak256(abi.encode(_cut, address(0), ""));
        if (upgradeHash == 0xc597f3eb22d11c46f626cd856bd65e9127b04623d83e442686776a2e3b670bbf) {
            console2.log("There are no facets to upgrade. This hash is the keccak256 hash of an empty IDiamondCut.FacetCut[]");
        } else {
            changePrank(systemAdmin);
            nayms.createUpgrade(upgradeHash);
            changePrank(owner);
            nayms.diamondCut(_cut, address(0), new bytes(0));
            changePrank(systemAdmin);
        }
    }

    function scheduleAndUpgradeDiamond(IDiamondCut.FacetCut[] memory _cut, address _init, bytes memory _calldata) internal {
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
}
