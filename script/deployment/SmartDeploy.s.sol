// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../utils/DeploymentHelpers.sol";

contract SmartDeploy is DeploymentHelpers {
    function smartDeploy(
        bool deployNewDiamond,
        bool initNewDiamond,
        FacetDeploymentAction facetDeploymentAction,
        string[] memory facetsToCutIn,
        bytes32 salt
    )
        external
        returns (
            // string[] memory facetsToCutIn
            address diamondAddress,
            address initDiamondAddress,
            bytes32 upgradeHash
        )
    {
        vm.startBroadcast(msg.sender);

        (diamondAddress, initDiamondAddress, upgradeHash) = smartDeployment(deployNewDiamond, initNewDiamond, facetDeploymentAction, facetsToCutIn, salt);

        vm.stopBroadcast();
    }

    function scheduleAndUpgradeDiamond() external {
        INayms nayms = INayms(getDiamondAddressFromFile());

        string[] memory facetsToCutIn;
        IDiamondCut.FacetCut[] memory cut = facetDeploymentAndCut(getDiamondAddressFromFile(), FacetDeploymentAction.UpgradeFacetsWithChangesOnly, facetsToCutIn);

        bytes32 upgradeHash = keccak256(abi.encode(cut));

        if (upgradeHash == 0x569e75fc77c1a856f6daaf9e69d8a9566ca34aa47f9133711ce065a571af0cfd) {
            console2.log("There are no facets to upgrade. This hash is the keccak256 hash of an empty IDiamondCut.FacetCut[]");
        } else {
            vm.startBroadcast(msg.sender);
            nayms.createUpgrade(upgradeHash);
            nayms.diamondCut(cut, address(0), new bytes(0));
            vm.stopBroadcast();
        }
    }

    function hash(
        bool deployNewDiamond,
        FacetDeploymentAction facetDeploymentAction,
        string[] memory facetsToCutIn,
        bytes32 salt
    ) external returns (bytes32 upgradeHash, IDiamondCut.FacetCut[] memory cut) {
        vm.startPrank(msg.sender);

        (upgradeHash, cut) = initUpgradeHash(deployNewDiamond, facetDeploymentAction, facetsToCutIn, salt);

        vm.stopPrank();
    }
}
