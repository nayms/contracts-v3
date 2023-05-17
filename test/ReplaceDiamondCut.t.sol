// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import { IDiamondCut } from "src/diamonds/nayms/INayms.sol";

import { S01DeployContract } from "script/deployment/S01DeployContract.s.sol";
import { S02ScheduleUpgrade } from "script/deployment/S02ScheduleUpgrade.s.sol";
import { S03UpgradeDiamond } from "script/deployment/S03UpgradeDiamond.s.sol";

/// @dev Testing the new simplified contract deployment and upgrade process.
/// Mainnet Nayms diamond 0x39e2f550fef9ee15b459d16bD4B243b04b1f60e5 at block 17276760 is using the
/// old phased diamondCut() method which only hashes the cut struct.
/// We test the replacement of the old phased diamondCut() method with the new phased diamondCut() method.

contract ReplaceDiamondCut is Test {
    S01DeployContract public deployer;
    S02ScheduleUpgrade public systemAdmin;
    S03UpgradeDiamond public owner;

    address public ownerAddress = 0xd5c10a9a09B072506C7f062E4f313Af29AdD9904;
    address public systemAdminAddress = 0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929;

    function setUp() public {
        vm.createSelectFork("mainnet", 17276760);
        deployer = new S01DeployContract();
        systemAdmin = new S02ScheduleUpgrade();
        owner = new S03UpgradeDiamond();
    }

    function testReplaceDiamondCut() public {
        // Deploy contract
        (IDiamondCut.FacetCut[] memory cut, bytes32 upgradeHash, bytes32 upgradeHashOld) = deployer.run("PhasedDiamondCutFacet");

        // Schedule upgrade
        systemAdmin.run(systemAdminAddress, upgradeHashOld);

        // Upgrade diamond
        owner.run(ownerAddress, cut);

        // Try upgrading with the new diamond cut
        (cut, upgradeHash, upgradeHashOld) = deployer.run("TokenizedVaultIOFacet");

        // note Start using new upgradeHash calculation
        systemAdmin.run(systemAdminAddress, upgradeHash);

        owner.run(ownerAddress, cut);
    }
}
