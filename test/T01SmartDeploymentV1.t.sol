// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9;

import "script/utils/DeploymentHelpers.sol";
import "src/diamonds/shared/interfaces/IDiamondCut.sol";
import { INayms } from "src/diamonds/nayms/INayms.sol";

// TODO:
// append to deployedAddresses.json

contract T01SmartDeploymentV1 is DeploymentHelpers {
    function setUp() public {}

    function testNewDiamondDeployment() public {
        address diamondAddress = diamondDeployment(true);

        assertEq(sDiamondAddress, diamondAddress, "the stored diamond address should be the same as the diamond address being returned by the function");
    }

    function testParseDeployedAddressesJson() public {
        string memory deployData = vm.readFile(deployFile);

        bytes memory parsed = vm.parseJson(deployData, ".NaymsDiamond.1");
        // bytes memory parsed = vm.parseJson(deployData, ".NaymsDiamond.1");

        address decoded = abi.decode(parsed, (address));
        console2.log(decoded);
        // todo use stdJson library
        // deployData.readAddress(".NaymsDiamond");
    }

    function testUseCurrentDiamondDeployment() public {
        address diamondAddress = diamondDeployment(false);
        // assertEq(sDiamondAddress > address(0), "the stored diamond address should not be address(0)");
        // assertEq(diamondAddress, diamondAddress, "the returned diamond address should not be address(0)");
        assertEq(sDiamondAddress, diamondAddress, "the stored diamond address should be the same as the diamond address being returned by the function");
    }

    function testFfiListFiles() public {
        string[] memory inputs = new string[](12);
        inputs[0] = "find";
        inputs[1] = "broadcast/DeployDiamond.s.sol/5/";
        inputs[2] = "-name";
        inputs[3] = "*.json";
        inputs[4] = "-type";
        inputs[5] = "f";
        inputs[6] = "-execdir";
        inputs[7] = "basename";
        inputs[8] = "-s";
        inputs[9] = ".json";
        inputs[10] = "{}";
        inputs[11] = "+";

        bytes memory res = vm.ffi(inputs);
        console2.log(string(res));

        // string[] memory parts = findAndReplace(res, "run-");
        // vm.toString(parts);
        // replaceNewLineWithComma(res);

        // removes the string "run-" from the given bytes, and outputs a single string
        string memory whole = findAndReplaceToString(res, "run-");

        // note: this will leave an empty element in the array
        string memory whole2 = findAndReplaceToString(bytes(whole), "latest");

        // string[] memory parts = findAndReplace(bytes(whole), "\n");
        string[] memory parts2 = findAndReplace(bytes(whole2), "\n");

        // lets now convert this array of strings into an array of numbers, with no empty elements
    }

    // what we should capture at every new deployment:
    // the timestamp that the broadcasted transaction was made

    // therefore, the key for the diamond is: chainid, timestamp
    // the key for facets are: chainid, diamond address (is this necessary?), timestamp

    // is the latest.json what's on chain? check by parsing the latest.json
    // if this is not the
    function testFfiFindFacetNames() public {
        ffiFindFacetNames();
    }

    function testFfiGenerateInterfaces() public {
        string[] memory facetNames = ffiFindFacetNames();

        string memory artifactFile;
        string memory outputPathAndName;

        string[] memory inputs = new string[](5);
        inputs[0] = "cast";
        inputs[1] = "interface";
        inputs[2] = artifactFile;
        inputs[3] = "-o";
        inputs[4] = outputPathAndName;

        for (uint256 i; i < facetNames.length; i++) {
            artifactFile = string.concat(artifactsPath, facetNames[i], "Facet.sol/", facetNames[i], "Facet.json");
            outputPathAndName = string.concat("test-interfaces/I", facetNames[i], ".sol");
            inputs[2] = artifactFile;
            inputs[4] = outputPathAndName;
            bytes memory res = vm.ffi(inputs);
        }
    }

    function testReadBroadcast() public {
        vm.chainId(5);

        string memory facetName = "ACL";
        string memory chainIdS = vm.toString(block.chainid);
        string memory scriptName = "DeployDiamond.s.sol";

        string memory broadcastFile = string.concat("broadcast/", scriptName, "/", chainIdS, "/", "run-latest.json");

        string memory broadcastData = vm.readFile(broadcastFile);
        bytes memory parsedBroadcastData = vm.parseJson(broadcastData, ".bytecode.object");
    }

    function testValidateDeployment() public {
        // ensure that the deployment was made
        // have a validated flag that returns true if the deployment was validated
        // if it's a facet, then check to see if the facet has actually been cut in or not to the current diamond
        // deployed but not cut in? state this
        // deployed and cut in as expected?
    }

    function testOutputDeployment() public {
        string memory write = LibWriteJson.createObject(
            LibWriteJson.keyObject("NaymsDiamond", LibWriteJson.keyObject(vm.toString(block.chainid), LibWriteJson.keyValue("address", vm.toString(address(0)))))
        );
        vm.writeFile(deployFile, write);

        string memory deployData = vm.readFile(deployFile);

        string memory whole = findAndReplaceToString(bytes(deployData), "run-");
    }

    function testDeployFacetAndCreateFacetCut() public {
        string memory facetName = "ACL";

        IDiamondCut.FacetCut memory cut = deployFacetAndCreateFacetCut(facetName);

        console2.log(cut.facetAddress);
        console2.logBytes4(cut.functionSelectors[0]);
    }

    function testDeployNewDiamondAndDeployAllFacetsFacetDeploymentAndCut() public {
        address diamondAddress = diamondDeployment(true);
        string[] memory facetsToCutIn;

        // deploys facets
        console2.log("in test before facetDeploymentAndCut");
        // facetDeploymentAndCut(diamondAddress, FacetDeploymentAction.DeployAllFacets, facetsToCutIn);
        IDiamondCut.FacetCut[] memory cut = facetDeploymentAndCut(diamondAddress, FacetDeploymentAction.DeployAllFacets, facetsToCutIn);
        console2.log(cut[0].facetAddress);
        console2.logBytes4(cut[0].functionSelectors[0]);

        INayms nayms = INayms(diamondAddress);

        console2.log("nayms owner", nayms.owner());
        console2.log("msg.sender", msg.sender);

        nayms.facets();
        vm.startPrank(msg.sender);
        cutAndInit(diamondAddress, cut, address(0));
        nayms.facets();
    }

    function testDeployNewDiamondAndUpgradeFacetsWithChangesOnlyAndCut() public {
        address diamondAddress = diamondDeployment(true);
        string[] memory facetsToCutIn;

        // deploys facets
        console2.log("in test before facetDeploymentAndCut");
        // facetDeploymentAndCut(diamondAddress, FacetDeploymentAction.DeployAllFacets, facetsToCutIn);
        IDiamondCut.FacetCut[] memory cut = facetDeploymentAndCut(diamondAddress, FacetDeploymentAction.UpgradeFacetsWithChangesOnly, facetsToCutIn);
        // console2.log(cut[0].facetAddress);
        // console2.logBytes4(cut[0].functionSelectors[0]);

        INayms nayms = INayms(diamondAddress);

        // console2.log("nayms owner", nayms.owner());
        // console2.log("msg.sender", msg.sender);

        nayms.facets();
        vm.startPrank(msg.sender);
        cutAndInit(diamondAddress, cut, address(0));
        nayms.facets();
    }

    function testDeployNewDiamondAndUpgradeFacetsListedOnlyAndCut() public {
        address diamondAddress = diamondDeployment(true);
        string[] memory facetsToCutIn = new string[](2);
        facetsToCutIn[0] = "ACL";
        facetsToCutIn[1] = "System";
        IDiamondCut.FacetCut[] memory cut = facetDeploymentAndCut(diamondAddress, FacetDeploymentAction.UpgradeFacetsListedOnly, facetsToCutIn);

        INayms nayms = INayms(diamondAddress);

        nayms.facets();
        vm.startPrank(msg.sender);
        cutAndInit(diamondAddress, cut, address(0));
        nayms.facets();
    }

    function testCompareBytecode() public {
        vm.startPrank(msg.sender);

        address diamondAddress = diamondDeployment(true);
        string[] memory facetsToCutIn;
        IDiamondCut.FacetCut[] memory cut = facetDeploymentAndCut(diamondAddress, FacetDeploymentAction.UpgradeFacetsWithChangesOnly, facetsToCutIn);

        cutAndInit(diamondAddress, cut, address(0));

        // testing equivalent bytecode
        compareBytecode(diamondAddress, "ACL");
    }

    function testSmartDeploy() public {
        string[] memory facetsToCutIn;
        vm.startPrank(msg.sender);
        smartDeployment(true, true, FacetDeploymentAction.DeployAllFacets, facetsToCutIn);

        // don't deploy an InitDiamond and don't call initialize
        smartDeployment(true, false, FacetDeploymentAction.DeployAllFacets, facetsToCutIn);
    }

    function test2SmartDeploy() public {
        string[] memory facetsToCutIn;
        vm.startPrank(msg.sender);
        (address diamondAddress, address initDiamondAddress) = smartDeployment(true, true, FacetDeploymentAction.UpgradeFacetsWithChangesOnly, facetsToCutIn);

        // (address diamondAddress2, address initDiamondAddress2) = smartDeployment(false, true, FacetDeploymentAction.UpgradeFacetsWithChangesOnly, facetsToCutIn);
    }

    // test scenarios
    // deploy new diamond, deploy all facets
    // deploy

    // first deploy
}
