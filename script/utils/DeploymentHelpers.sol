// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { strings } from "lib/solidity-stringutils/src/strings.sol";
import "./LibGeneratedNaymsFacetHelpers.sol";
import { INayms, IDiamondCut, IDiamondLoupe } from "src/diamonds/nayms/INayms.sol";
import { Create3Deployer } from "src/utils/Create3Deployer.sol";

import { PhasedDiamondCutFacet } from "src/diamonds/shared/facets/PhasedDiamondCutFacet.sol";

// solhint-disable no-empty-blocks
// solhint-disable state-visibility
// solhint-disable quotes
// solhint-disable no-console

/// @notice helper methods to deploy a diamond,

interface IInitDiamond {
    function initialize() external;
}

contract DeploymentHelpers is Test {
    using strings for *;
    using stdStorage for StdStorage;

    uint256[] SUPPORTED_CHAINS = [1, 5, 31337, 11155111];

    string public constant artifactsPath = "forge-artifacts/";
    // File that is being parsed for the diamond address. If we are deploying a new diamond, then the address will be overwritten here.
    string public deployFile = "deployedAddresses.json";

    string public keyToReadDiamondAddress = string.concat(".", vm.toString(block.chainid));

    mapping(address => string) newFacetNames;
    address internal sDiamondAddress;

    IDiamondCut.FacetCut[] public cutS;

    bytes4[] public replaceSelectors;
    bytes4[] public addSelectors;
    bytes4[] public removeSelectors;

    enum FacetDeploymentAction {
        DeployAllFacets,
        UpgradeFacetsWithChangesOnly,
        UpgradeFacetsListedOnly
    }

    // return array of function selectors for given facet name
    function generateSelectors(string memory _facetName) internal returns (bytes4[] memory selectors) {
        //get string of contract methods
        string[] memory cmd = new string[](4);
        cmd[0] = "forge";
        cmd[1] = "inspect";
        cmd[2] = _facetName;
        cmd[3] = "methods";
        bytes memory res = vm.ffi(cmd);
        string memory st = string(res);

        // extract function signatures and take first 4 bytes of keccak
        strings.slice memory s = st.toSlice();
        strings.slice memory delim = ":".toSlice();
        strings.slice memory delim2 = ",".toSlice();
        selectors = new bytes4[]((s.count(delim)));

        for (uint256 i = 0; i < selectors.length; i++) {
            s.split('"'.toSlice());
            selectors[i] = bytes4(s.split(delim).until('"'.toSlice()).keccak());
            s.split(delim2);
        }
        return selectors;
    }

    function removeFromArray(uint256 index) public {
        // console2.log(string.concat("removeFromArray index: ", vm.toString(index), ". removeSelectors.length: ", vm.toString(removeSelectors.length)));
        require(removeSelectors.length > index, "Out of bounds");
        // move all elements to the left, starting from the `index + 1`
        for (uint256 i = index; i < removeSelectors.length - 1; i++) {
            removeSelectors[i] = removeSelectors[i + 1];
        }
        removeSelectors.pop(); // delete the last item
    }

    function getDiamondAddressFromFile() internal view returns (address diamondAddress) {
        // Read in current diamond address
        string memory deployData = vm.readFile(deployFile);

        bytes memory parsed = vm.parseJson(deployData, keyToReadDiamondAddress);
        diamondAddress = abi.decode(parsed, (address));
    }

    // true: deploys a new diamond, writes to deployFile
    // false: reads deployFile
    function diamondDeployment(
        bool deployNewDiamond,
        address owner,
        address systemAdmin,
        bytes32 salt
    ) public returns (address diamondAddress) {
        if (deployNewDiamond) {
            if (salt != 0) {
                // deterministically deploy diamond
                Create3Deployer create3 = new Create3Deployer();

                console2.log("Deterministic contract address", create3.getDeployed(salt));
                diamondAddress = create3.deployContract(salt, abi.encodePacked(type(Nayms).creationCode, abi.encode(owner, systemAdmin)), 0);
            } else {
                diamondAddress = address(new Nayms(owner, systemAdmin));
            }

            vm.label(address(diamondAddress), "New Nayms Diamond");

            // Output diamond address

            // If key exists, then replace value.
            // Otherwise, add a new row.
            try vm.parseJson(deployFile, keyToReadDiamondAddress) {
                vm.writeJson(vm.toString(address(diamondAddress)), deployFile, keyToReadDiamondAddress);
            } catch {
                string memory json = vm.readFile(deployFile);
                uint256 numOfChainIds = SUPPORTED_CHAINS.length;
                uint256 chainId;
                for (uint256 i; i < numOfChainIds; i++) {
                    chainId = SUPPORTED_CHAINS[i];
                    try vm.parseJsonAddress(json, string.concat(".", vm.toString(chainId))) {
                        vm.serializeAddress("key", vm.toString(chainId), vm.parseJsonAddress(json, string.concat(".", vm.toString(chainId))));
                    } catch {}
                }
                string memory addRow = vm.serializeAddress("key", vm.toString(block.chainid), diamondAddress);
                vm.writeJson(addRow, deployFile);
            }
        } else {
            // Read in current diamond address
            diamondAddress = getDiamondAddressFromFile();

            vm.label(address(diamondAddress), "Same Nayms Diamond");
        }

        // store diamond address to be used later to create output
        sDiamondAddress = diamondAddress;
    }

    function findAndReplace(bytes memory res, string memory find) public view returns (string[] memory parts) {
        string memory start = string(res);
        strings.slice memory s = start.toSlice();
        string memory d = find;
        strings.slice memory delim = d.toSlice();
        s.count(delim);
        parts = new string[](s.count(delim) + 1);
        for (uint256 i = 0; i < parts.length; i++) {
            parts[i] = s.split(delim).toString();
        }
    }

    function findAndReplaceToString(bytes memory res, string memory find) public view returns (string memory whole) {
        string memory start = string(res);
        strings.slice memory s = start.toSlice();
        string memory d = find;
        strings.slice memory delim = d.toSlice();
        s.count(delim);
        string[] memory parts = new string[](s.count(delim) + 1);

        for (uint256 i = 0; i < parts.length; i++) {
            parts[i] = s.split(delim).toString();
        }
    }

    function replaceNewLineWithComma(bytes memory res) public view returns (string[] memory parts) {
        string memory start = string(res);
        strings.slice memory s = start.toSlice();
        string memory d = "\n";
        strings.slice memory delim = d.toSlice();
        s.count(delim);
        parts = new string[](s.count(delim) + 1);
        for (uint256 i = 0; i < parts.length; i++) {
            parts[i] = s.split(delim).toString();
        }
    }

    function deployContract(string memory contractName) public returns (address contractAddress) {
        string memory artifactFile = string.concat(artifactsPath, contractName, ".sol/", contractName, ".json");

        contractAddress = deployCode(artifactFile);
    }

    function deploySelectFacet(string memory facetName) public returns (address facetAddress) {
        string memory artifactFile = string.concat(artifactsPath, facetName, "Facet.sol/", facetName, "Facet.json");

        facetAddress = deployCode(artifactFile);
    }

    /**
     * @notice Compares the bytecode in the artifact to the matching onchain facet bytecode .
     * @dev This method returns true for matching bytecode.
     */
    function compareBytecode(address diamondAddress, string memory facetName) public returns (bool bytecodeMatchFlag) {
        // read the newly compiled artifact file for the facet
        string memory artifactFile = string.concat(artifactsPath, facetName, "Facet.sol/", facetName, "Facet.json");
        string memory artifactData = vm.readFile(artifactFile);

        bytes memory bytecode = vm.parseJson(artifactData, ".deployedBytecode.object");
        bytes memory bytecodeDecoded = abi.decode(bytecode, (bytes));

        bytes4[] memory functionSignatures = generateSelectors(string.concat(facetName, "Facet"));
        uint256 numberOfFunctionSignaturesFromArtifact = functionSignatures.length;
        // get first non zero address
        address targetFacetAddress;
        for (uint256 i; i < numberOfFunctionSignaturesFromArtifact; i++) {
            targetFacetAddress = IDiamondLoupe(diamondAddress).facetAddress(functionSignatures[i]);
            if (targetFacetAddress != address(0)) {
                break;
            }
        }

        bytes memory targetFacetBytecode = targetFacetAddress.code;
        bytecodeMatchFlag = checkEq0(targetFacetBytecode, bytecodeDecoded);
    }

    /**
     * @notice Deploys a new facet by its name (calling deploySelectFacet()) and creates the Cut struct
     */
    function deployFacetAndCreateFacetCut(string memory facetName) public returns (IDiamondCut.FacetCut memory cut) {
        cut.facetAddress = deploySelectFacet(facetName);

        newFacetNames[cut.facetAddress] = facetName;

        cut.functionSelectors = generateSelectors(string.concat(facetName, "Facet"));

        cut.action = IDiamondCut.FacetCutAction.Add;
    }

    /**
     * @notice OLD WAY TO MAKE COVERAGE WORK. Deploys a new facet by its name (calling deploySelectFacet()) and creates the Cut struct
     */

    function deployFacetAndCreateFacetCutOLD(string memory facetName) public returns (IDiamondCut.FacetCut memory cut) {
        cut.facetAddress = LibGeneratedNaymsFacetHelpers.deployNaymsFacetsByName(facetName);

        newFacetNames[cut.facetAddress] = facetName;

        cut.functionSelectors = generateSelectors(string.concat(facetName, "Facet"));

        cut.action = IDiamondCut.FacetCutAction.Add;
    }

    /**
     * @notice Pass in the facet deployment pattern that is desired. The various facet deployment patterns are explained in the FacetDeploymentAction enum.
     */
    function facetDeploymentAndCut(
        address diamondAddress,
        FacetDeploymentAction facetDeploymentAction,
        string[] memory facetsToCutIn
    ) public returns (IDiamondCut.FacetCut[] memory cut) {
        // If deployAllFacets == true, then deploy all of the facets currently defined
        // If deployAllFacets == false, then only upgrade the facets listed in the array facetsToCutIn
        // deployAllFacets == false

        string[] memory allFacetNames = LibGeneratedNaymsFacetHelpers.getFacetNames();
        uint256 numberOfFacets = allFacetNames.length;

        if (facetDeploymentAction == FacetDeploymentAction.DeployAllFacets) {
            // loop through allFacetNames and deploy them
            // note this purely adds all facet methods.
            cut = new IDiamondCut.FacetCut[](numberOfFacets);
            for (uint256 i; i < numberOfFacets; i++) {
                // note: bring this back once coverage covers deployments from bytecode
                // cut[i] = deployFacetAndCreateFacetCut(allFacetNames[i]);
                cut[i] = deployFacetAndCreateFacetCutOLD(allFacetNames[i]);
            }
        } else if (facetDeploymentAction == FacetDeploymentAction.UpgradeFacetsWithChangesOnly) {
            // V1: check if facet bytecode is different. If so, then deploy facet and add, remove, replace methods.
            // loop through allFacetNames
            // check if function sig exists

            for (uint256 i; i < numberOfFacets; i++) {
                if (!compareBytecode(diamondAddress, allFacetNames[i])) {
                    dynamicFacetCutV1(diamondAddress, allFacetNames[i]);
                }
            }

            cut = cutS;
        } else if (facetDeploymentAction == FacetDeploymentAction.UpgradeFacetsListedOnly) {
            // Deploy the facets listed in facetsToCutIn
            // require(facetsToCutIn.length > 0, "facetDeployment: did not provide any facet names to be manually deployed");

            for (uint256 i; i < facetsToCutIn.length; i++) {
                dynamicFacetCutV1(diamondAddress, facetsToCutIn[i]);
            }

            cut = cutS;
        }
    }

    /// Adds any new function sigs. Replaces any functions with the same sig. Removes any functions that don't exist in the new facet.
    /// @notice V1 of dynamic facet cuts. If the facet has a new method, then the facet will be newly deployed and cut in
    // If the facet has a method with the same function sig

    /**
     * @dev If the facet only has methods with the same function sig (no new function sigs), then this method is not smart enough
     * to know whether or not there's a change in the function itself to warrent a new deployment / diamond cut.
     * This extra smartness will come in V2 of dynamicFacetCut() :)
     * @param diamondAddress The address of the diamond to be upgraded. note: The diamond must have the standard diamond loupe functions
     * @param facetName Name of the facet to cut in
     */
    function dynamicFacetCutV1(address diamondAddress, string memory facetName) public returns (IDiamondCut.FacetCut[] memory cut) {
        // if it already exists - replace
        // if it doesn't exist in the old facet - add
        // if it doesn't exist in the new facet and it doesn't exist in the old facet - remove

        uint256 replaceCount;
        uint256 addCount;
        uint256 removeCount;

        address oldFacetAddress;

        bytes4[] memory functionSelectors = generateSelectors(string.concat(facetName, "Facet"));
        uint256 numFunctionSelectors = functionSelectors.length;
        // REPLACE, ADD (remove is after REPLACE and ADD)
        if (numFunctionSelectors > 0) {
            for (uint256 i; i < numFunctionSelectors; ++i) {
                // replace "old" method with "new" method
                if (IDiamondLoupe(diamondAddress).facetAddress(functionSelectors[i]) != address(0)) {
                    replaceCount++;

                    replaceSelectors.push(functionSelectors[i]);

                    // assume the old facet address is the address with a matching function selector
                    oldFacetAddress = IDiamondLoupe(diamondAddress).facetAddress(functionSelectors[i]);
                    // add method if it doesn't exist in the old facet
                } else if (IDiamondLoupe(diamondAddress).facetAddress(functionSelectors[i]) == address(0)) {
                    addCount++;
                    addSelectors.push(functionSelectors[i]);
                }
            }
        }

        // REMOVE
        // if there are selectors in the old facet that are not being replaced, then they should be removed, since they are not in the new facet
        // from the list of selectors from the old facet, remove from the list the selectors that are being replaced.
        uint256 numberOfSelectorsFromOldFacet;
        // bytes4[] memory removeSelectors;
        if (oldFacetAddress != address(0)) {
            bytes4[] memory oldFacetSelectors = IDiamondLoupe(diamondAddress).facetFunctionSelectors(oldFacetAddress);
            numberOfSelectorsFromOldFacet = oldFacetSelectors.length;
            for (uint256 i; i < numberOfSelectorsFromOldFacet; i++) {
                address facetAddress = IDiamondLoupe(diamondAddress).facetAddress(oldFacetSelectors[i]);
            }

            // get list of selectors in "current" facet
            removeSelectors = IDiamondLoupe(diamondAddress).facetFunctionSelectors(oldFacetAddress);
            uint256 oldFacetCount = removeSelectors.length;

            uint256 numSelectorsRemovedFromFacet;

            for (uint256 k; k < oldFacetCount; k++) {
                for (uint256 j; j < numFunctionSelectors; j++) {
                    // compare list of old selectors with list of new selectors, if any are the same, then remove from the list of old selectors (removeSelectors[])
                    if (removeSelectors[k - numSelectorsRemovedFromFacet] == functionSelectors[j] && removeSelectors[k - numSelectorsRemovedFromFacet] != 0) {
                        removeFromArray(k - numSelectorsRemovedFromFacet);
                        numSelectorsRemovedFromFacet++;
                        break;
                    }
                }
            }
        }

        removeCount = removeSelectors.length;

        // deploy a new facet if it's needed
        address newFacetAddress;

        if (addCount != 0 || replaceCount != 0) {
            newFacetAddress = deploySelectFacet(facetName);

            newFacetNames[newFacetAddress] = facetName;
        }

        if (addCount > 0 && replaceCount > 0 && removeCount > 0) {
            cut = new IDiamondCut.FacetCut[](3);

            cut[0] = IDiamondCut.FacetCut({ facetAddress: address(newFacetAddress), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: replaceSelectors });
            cut[1] = IDiamondCut.FacetCut({ facetAddress: address(newFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: addSelectors });
            cut[2] = IDiamondCut.FacetCut({ facetAddress: address(0), action: IDiamondCut.FacetCutAction.Remove, functionSelectors: removeSelectors });
            cutS.push(IDiamondCut.FacetCut({ facetAddress: address(newFacetAddress), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: replaceSelectors }));
            cutS.push(IDiamondCut.FacetCut({ facetAddress: address(newFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: addSelectors }));
            cutS.push(IDiamondCut.FacetCut({ facetAddress: address(0), action: IDiamondCut.FacetCutAction.Remove, functionSelectors: removeSelectors }));
        } else if (addCount > 0 && replaceCount > 0) {
            cut = new IDiamondCut.FacetCut[](2);

            cut[0] = IDiamondCut.FacetCut({ facetAddress: address(newFacetAddress), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: replaceSelectors });
            cut[1] = IDiamondCut.FacetCut({ facetAddress: address(newFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: addSelectors });
            cutS.push(IDiamondCut.FacetCut({ facetAddress: address(newFacetAddress), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: replaceSelectors }));
            cutS.push(IDiamondCut.FacetCut({ facetAddress: address(newFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: addSelectors }));
        } else {
            cut = new IDiamondCut.FacetCut[](1);
            if (addCount > 0) {
                cut[0] = IDiamondCut.FacetCut({ facetAddress: address(newFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: addSelectors });
                cutS.push(IDiamondCut.FacetCut({ facetAddress: address(newFacetAddress), action: IDiamondCut.FacetCutAction.Add, functionSelectors: addSelectors }));
            } else if (replaceCount > 0) {
                cut[0] = IDiamondCut.FacetCut({ facetAddress: address(newFacetAddress), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: replaceSelectors });
                cutS.push(IDiamondCut.FacetCut({ facetAddress: address(newFacetAddress), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: replaceSelectors }));
            }
        }

        // clear out storage arrays. Otherwise, these storage arrays will retain the state from the first iteration of this method which is not desired for a subsequent call.
        delete replaceSelectors;
        delete addSelectors;
        delete removeSelectors;
    }

    function cutAndInit(
        address diamondAddress,
        IDiamondCut.FacetCut[] memory cut,
        address initAddress
    ) public {
        if (initAddress != address(0)) {
            IInitDiamond initDiamond = IInitDiamond(initAddress);

            IDiamondCut(diamondAddress).diamondCut(cut, address(initAddress), abi.encodeCall(initDiamond.initialize, ()));
        } else {
            IDiamondCut(diamondAddress).diamondCut(cut, address(0), "");
        }
    }

    /**
     * @notice This method ties everything together
     * @param deployNewDiamond Flag: true: deploy a new diamond. false: use the current diamond.
     * @param initNewDiamond Flag: true: deploy InitDiamond and initialize the diamond. false: does not deploy InitDiamond and does not call initialize.
     * @param facetDeploymentAction DeployAllFacets - deploys all facets in the facets folder and cuts them in.
     * UpgradeFacetsWithChangesOnly - looks at bytecode, if there's a difference, then will deploy a new facet, run through dynamic deployment
     * UpgradeFacetsListedOnly - looks at facetsToCutIn and runs through dynamic deployment only on those facets
     * @param facetsToCutIn List facets to manually cut in
     * @return diamondAddress initDiamond, upgradeHash hash of the facet cuts
     */
    function smartDeployment(
        bool deployNewDiamond,
        address _owner,
        address _systemAdmin,
        bool initNewDiamond,
        FacetDeploymentAction facetDeploymentAction,
        string[] memory facetsToCutIn,
        bytes32 salt
    )
        public
        returns (
            address diamondAddress,
            address initDiamondAddress,
            IDiamondCut.FacetCut[] memory cut,
            bytes32 upgradeHash
        )
    {
        // deploys new Nayms diamond, or gets the diamond address from file
        diamondAddress = diamondDeployment(deployNewDiamond, _owner, _systemAdmin, salt);

        // deploys facets
        cut = facetDeploymentAndCut(diamondAddress, facetDeploymentAction, facetsToCutIn);

        if (initNewDiamond) {
            IInitDiamond initDiamond = IInitDiamond(LibGeneratedNaymsFacetHelpers.deployNaymsFacetsByName("InitDiamond"));
            initDiamondAddress = address(initDiamond);
            upgradeHash = keccak256(abi.encode(cut, initDiamondAddress, abi.encodeCall(initDiamond.initialize, ())));
        } else {
            upgradeHash = keccak256(abi.encode(cut, address(0), ""));
        }
        console2.log(StdStyle.blue("upgradeHash: "), StdStyle.yellow(vm.toString(upgradeHash)));
        debugDeployment(diamondAddress, facetsToCutIn, facetDeploymentAction);

        uint256 upgradeExpiry = INayms(diamondAddress).getUpgrade(upgradeHash);
        if (upgradeExpiry >= block.timestamp) {
            cutAndInit(diamondAddress, cut, initDiamondAddress);
        } else {
            console2.log(StdStyle.red("UPGRADE NOT PERFORMED"), StdStyle.blue("(but facets have been deployed and the upgrade hash is valid)"));
            console2.log("Upgrade is not scheduled for this hash", vm.toString(upgradeHash));
            console2.log("Upgrade expiry time from getUpgrade()", vm.toString(upgradeExpiry));
            console2.log("Current block.timestamp for chainid", vm.toString(block.chainid), vm.toString(block.timestamp));
            console2.log("Use the upgrade hash given above to schedule an upgrade");
        }
    }

    function initUpgradeHash(
        bool deployNewDiamond,
        address _owner,
        address _systemAdmin,
        bool initNewDiamond,
        FacetDeploymentAction facetDeploymentAction,
        string[] memory facetsToCutIn,
        bytes32 salt
    )
        internal
        returns (
            bytes32 upgradeHash,
            IDiamondCut.FacetCut[] memory cut,
            address initDiamondAddress
        )
    {
        address diamondAddress = diamondDeployment(deployNewDiamond, _owner, _systemAdmin, salt);
        if (diamondAddress == address(0)) {
            return (upgradeHash, cut, initDiamondAddress);
        }

        cut = facetDeploymentAndCut(diamondAddress, facetDeploymentAction, facetsToCutIn);

        bool initialize;

        try INayms(diamondAddress).isDiamondInitialized() returns (bool result) {
            initialize = result;
        } catch (bytes memory) {
            // if the diamond does not have the isDiamondInitialized method, then check bool initNewDiamond
            if (initNewDiamond) {
                initialize = false; // if initialize == false then we will deploy InitDiamond and call initialize
            }
        }
        if (!initialize) {
            IInitDiamond initDiamond = IInitDiamond(LibGeneratedNaymsFacetHelpers.deployNaymsFacetsByName("InitDiamond"));
            initDiamondAddress = address(initDiamond);
            upgradeHash = keccak256(abi.encode(cut, initDiamondAddress, abi.encodeCall(initDiamond.initialize, ())));
        } else {
            upgradeHash = keccak256(abi.encode(cut, address(0), ""));
        }

        console2.log(StdStyle.blue("upgradeHash: "), StdStyle.yellow(vm.toString(upgradeHash)));
        debugDeployment(diamondAddress, facetsToCutIn, facetDeploymentAction);
    }

    function debugDeployment(
        address diamondAddress,
        string[] memory facetsToCutIn,
        FacetDeploymentAction facetDeploymentAction
    ) internal {
        console2.log(StdStyle.underline("Upgrade stats:"));

        uint256 numFacets = cutS.length;

        console2.log(StdStyle.underline("Number of facets being added/removed/replaced:"), cutS.length);

        uint256 addCount;
        uint256 replaceCount;
        uint256 removeCount;

        uint256 totalAddCount;
        uint256 totalReplaceCount;
        uint256 totalRemoveCount;

        for (uint256 i; i < numFacets; i++) {
            console2.log(string.concat(newFacetNames[cutS[i].facetAddress], " ", vm.toString(cutS[i].facetAddress)));

            if (cutS[i].action == IDiamondCut.FacetCutAction.Add) {
                console2.log("Adding:");
                addCount++;
                totalAddCount += cutS[i].functionSelectors.length;
            } else if (cutS[i].action == IDiamondCut.FacetCutAction.Replace) {
                console2.log("Replacing:");
                replaceCount++;
                totalReplaceCount += cutS[i].functionSelectors.length;
            } else if (cutS[i].action == IDiamondCut.FacetCutAction.Remove) {
                console2.log("Removing:");
                removeCount++;
                totalRemoveCount += cutS[i].functionSelectors.length;
            }

            uint256 numSelectors = cutS[i].functionSelectors.length;
            for (uint256 j; j < numSelectors; j++) {
                console2.log(vm.toString(cutS[i].functionSelectors[j]));
            }
        }

        if (facetDeploymentAction == FacetDeploymentAction.UpgradeFacetsListedOnly) {
            console2.log("Number of facets being added/removed/replaced:", facetsToCutIn.length);
        }

        console2.log("Number of facets being added:", addCount);
        console2.log("Number of facets being removed:", removeCount);
        console2.log("Number of facets being replaced:", replaceCount);

        console2.log("Number of function selectors being added:", totalAddCount);
        console2.log("Number of function selectors being removed:", totalRemoveCount);
        console2.log("Number of function selectors being replaced:", totalReplaceCount);

        INayms nayms = INayms(diamondAddress);
        console2.log("Contract owner:", nayms.owner());
    }

    function updateDeployOutputName(string memory outputName) public {
        deployFile = outputName;
    }
}
