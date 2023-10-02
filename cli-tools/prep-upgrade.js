const fs = require("fs");
const path = require("path");
const ethers = require("ethers");
// Define the FacetCutAction enum
const facetCutActionEnum = {
    0: "Add",
    1: "Replace",
    2: "Remove",
};

const filePath = process.argv[2]; // get the file path from CLI argument

const generateS03UpgradeDiamond = (facetCuts, updateStateAddress) => {
    let script = `// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// ------------------------------------------------------------------------------------------------------------
///
/// NOTE: this file is auto-generated by ${path.basename(__filename)}, please DO NOT modify it directly. Unless you want to :)
///
/// ------------------------------------------------------------------------------------------------------------

import { IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import "script/utils/DeploymentHelpers.sol";

contract S03UpgradeDiamond is DeploymentHelpers {
    using stdJson for string;

    function run(address _ownerAddress) external {
        INayms nayms = INayms(getDiamondAddressFromFile());

        if (_ownerAddress == address(0)) {
            _ownerAddress = nayms.owner();
        }

        string memory path = "${filePath}";
        string memory json = vm.readFile(path);
        bytes memory rawTxReturn = json.parseRaw(".returns.cut");
        TxReturn memory txReturn = abi.decode(rawTxReturn, (TxReturn));
        assertEq(txReturn.internalType, "struct IDiamondCut.FacetCut[]", "not the correct cut struct type");

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](${facetCuts.length});
`;

    // add the facetCuts data to the script
    facetCuts.forEach((facetCut, i) => {
        if (i === 0) {
            script += `        bytes4[] memory f = new bytes4[](${facetCut.functionSelectors.length});\n`;
        } else {
            script += `      f = new bytes4[](${facetCut.functionSelectors.length});\n`;
        }

        facetCut.functionSelectors.forEach((selector, j) => {
            script += `        f[${j}] = ${selector};\n`;
        });

        script += `        cut[${i}] = IDiamondCut.FacetCut({ facetAddress: ${facetCut.facetAddress}, action: IDiamondCut.FacetCutAction.${facetCut.action}, functionSelectors: f });
  `;
    });

    script += `
        vm.startBroadcast(_ownerAddress);`;

    if (updateStateAddress) {
        script += `
        nayms.diamondCut(cut, address(${updateStateAddress}), abi.encodeWithSignature("initialize()"));\n`;
    } else {
        script += `
        nayms.diamondCut(cut, address(0), new bytes(0));\n`;
    }

    script += `        vm.stopBroadcast();
    }
}
`;
    return script;
};

// The following parses the IDiamondCut.FacetCut[] struct from the JSON file. See test/mocks/data/facet-cut-struct-{i}.json for examples of this data structure.
fs.readFile(filePath, "utf8", (err, data) => {
    if (err) {
        console.error(`Error reading file from disk: ${err}`);
    } else {
        // parse the JSON file to a JavaScript object
        const json = JSON.parse(data);
        let valueStr = json.returns.cut.value.slice(1, -1); // Remove the outer brackets
        let tuplesStr = valueStr.split("), ");

        let facetCuts = tuplesStr.map((tupleStr) => {
            let tupleParts = tupleStr.split(", [");

            // Handle facetAddress and action
            let facetActionParts = tupleParts[0].split(", ");
            let facetAddress = ethers.utils.getAddress(facetActionParts[0].slice(1)); // Remove leading "("
            let action = facetCutActionEnum[parseInt(facetActionParts[1])];

            // Handle functionSelectors
            let functionSelectorsStr = tupleParts[1].slice(0, -1); // Remove trailing "]"
            if (functionSelectorsStr.charAt(functionSelectorsStr.length - 1) === ")") {
                functionSelectorsStr = functionSelectorsStr.slice(0, -1); // Remove trailing ")"
            }

            let functionSelectors = functionSelectorsStr.split(", ");
            // Remove any trailing "]" from the last functionSelector
            let lastFunctionSelector = functionSelectors[functionSelectors.length - 1];
            if (lastFunctionSelector.endsWith("]")) {
                functionSelectors[functionSelectors.length - 1] = lastFunctionSelector.slice(0, -1);
            }
            return { facetAddress, action, functionSelectors };
        });

        const updateStateAddress = process.argv[3];
        // Write the script to the S03UpgradeDiamond.s.sol file
        fs.writeFile(path.join(__dirname, "../script/deployment/S03UpgradeDiamond.s.sol"), generateS03UpgradeDiamond(facetCuts, updateStateAddress), (err) => {
            if (err) {
                console.error(`Error writing file to disk: ${err}`);
            } else {
                console.log(`Successfully wrote script to S03UpgradeDiamond.s.sol`);
            }
        });
    }
});
