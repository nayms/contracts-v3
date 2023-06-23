// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Test } from "forge-std/Test.sol";

import { IDiamondCut } from "src/diamonds/nayms/INayms.sol";

import { S01DeployContract } from "script/deployment/S01DeployContract.s.sol";
import { S02ScheduleUpgrade } from "script/deployment/S02ScheduleUpgrade.s.sol";

/// @dev Testing the new simplified contract deployment and upgrade process.
/// Mainnet Nayms diamond 0x39e2f550fef9ee15b459d16bD4B243b04b1f60e5 at block 17276760 is using the
/// old phased diamondCut() method which only hashes the cut struct.
/// We test the replacement of the old phased diamondCut() method with the new phased diamondCut() method.

interface IS03UpgradeDiamond {
    function run(address _ownerAddress) external;
}

contract ReplaceDiamondCutTestHelpers is Test {
    function runPrepUpgrade(string memory broadcastFile) public {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "./cli-tools/prep-upgrade.js";
        cmd[2] = broadcastFile;
        vm.ffi(cmd);
    }

    function compileCode() public {
        string[] memory cmd = new string[](4);
        cmd[0] = "forge";
        cmd[1] = "build";
        cmd[2] = "--skip";
        cmd[3] = "test";
        vm.ffi(cmd);
    }
}

contract ReplaceDiamondCutTest is ReplaceDiamondCutTestHelpers {
    S01DeployContract public deploy;
    S02ScheduleUpgrade public schedule;

    address public ownerAddress = 0xd5c10a9a09B072506C7f062E4f313Af29AdD9904;
    address public systemAdminAddress = 0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929;

    address public constant MOCK_DATA_ADDRESS_DIAMOND_CUT = 0x76a3bE902A115374d1Ab57d4d6aA7c7AD5929bA5;
    address public constant MOCK_DATA_ADDRESS_TOKENIZED_VAULT = 0x7041459fa01deAcE1EB86d1a3507C2F43b9051c5;

    function setUp() public {
        vm.label(ownerAddress, "owner");
        vm.label(systemAdminAddress, "system admin");

        vm.createSelectFork("mainnet", 17276760);
        vm.chainId(1);
        deploy = new S01DeployContract();
        schedule = new S02ScheduleUpgrade();
    }

    // note This test overwrites the file in script/deployment/S03UpgradeDiamond.s.sol
    function testReplaceDiamondCut() public {
        // Deploy contract
        (IDiamondCut.FacetCut[] memory cut, bytes32 upgradeHash, bytes32 upgradeHashOld) = deploy.run("PhasedDiamondCutFacet");

        // Schedule upgrade
        schedule.run(systemAdminAddress, upgradeHashOld);

        // note hardcode where the new contracts for upgrades are deployed to make the test resistent to changes in new contract address calculations
        vm.etch(MOCK_DATA_ADDRESS_DIAMOND_CUT, vm.getDeployedCode("PhasedDiamondCutFacet.sol:PhasedDiamondCutFacet"));

        runPrepUpgrade("test/mocks/data/facet-cut-struct-1.json");

        // Upgrade diamond
        upgrade(ownerAddress);

        // Try upgrading with the new diamond cut
        (cut, upgradeHash, upgradeHashOld) = deploy.run("TokenizedVaultIOFacet");

        vm.etch(MOCK_DATA_ADDRESS_TOKENIZED_VAULT, vm.getDeployedCode("TokenizedVaultIOFacet.sol:TokenizedVaultIOFacet"));

        // note Start using new upgradeHash calculation
        schedule.run(systemAdminAddress, upgradeHash);

        // Deploy the new upgrade script
        runPrepUpgrade("test/mocks/data/facet-cut-struct-2.json");

        upgrade(ownerAddress);
    }

    function upgrade(address _ownerAddress) public {
        // Compile the script after generating it
        compileCode();
        // Deploy the new upgrade script
        address upgradeScriptAddress = deployCode("forge-artifacts/S03UpgradeDiamond.s.sol/S03UpgradeDiamond.json");
        IS03UpgradeDiamond upgradeScript = IS03UpgradeDiamond(upgradeScriptAddress);
        upgradeScript.run(_ownerAddress);
    }
}
