// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../utils/DeploymentHelpers.sol";

contract SmartDeploy is DeploymentHelpers {
    function smartDeploy(
        bool deployNewDiamond,
        address _owner,
        address _systemAdmin,
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

        (diamondAddress, initDiamondAddress, upgradeHash) = smartDeployment(deployNewDiamond, _owner, _systemAdmin, initNewDiamond, facetDeploymentAction, facetsToCutIn, salt);

        vm.stopBroadcast();
    }

    function scheduleAndUpgradeDiamond() external {
        // 1. deploys new facets
        // 2. schedules upgrade
        // 3. upgrade
        INayms nayms = INayms(getDiamondAddressFromFile());

        string[] memory facetsToCutIn;
        vm.startBroadcast(msg.sender);
        IDiamondCut.FacetCut[] memory cut = facetDeploymentAndCut(getDiamondAddressFromFile(), FacetDeploymentAction.UpgradeFacetsWithChangesOnly, facetsToCutIn);
        bytes32 upgradeHash = keccak256(abi.encode(cut, address(0), new bytes(0)));
        if (upgradeHash == 0xc597f3eb22d11c46f626cd856bd65e9127b04623d83e442686776a2e3b670bbf) {
            console2.log("There are no facets to upgrade. This hash is the keccak256 hash of an empty IDiamondCut.FacetCut[]");
        } else {
            nayms.createUpgrade(upgradeHash);
            nayms.diamondCut(cut, address(0), new bytes(0));
        }
        vm.stopBroadcast();
    }

    function schedule(bytes32 upgradeHash) external {
        INayms nayms = INayms(getDiamondAddressFromFile());
        vm.startBroadcast(msg.sender);
        nayms.createUpgrade(upgradeHash);
        vm.stopBroadcast();
    }

    function hash(
        bool deployNewDiamond,
        address _owner,
        address _systemAdmin,
        bool initNewDiamond,
        FacetDeploymentAction facetDeploymentAction,
        string[] memory facetsToCutIn,
        bytes32 salt
    ) external returns (bytes32 upgradeHash, IDiamondCut.FacetCut[] memory cut) {
        vm.startBroadcast(msg.sender);

        address initDiamondAddress;
        (upgradeHash, cut, initDiamondAddress) = initUpgradeHash(deployNewDiamond, _owner, _systemAdmin, initNewDiamond, facetDeploymentAction, facetsToCutIn, salt);

        vm.stopBroadcast();
    }
}
