const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

function getFileNames(directory) {
  return fs.readdirSync(directory).map((file) => {
    const baseName = path.basename(file, ".sol");
    return path.parse(baseName).name;
  });
}

let fileNames = [];
fileNames = fileNames.concat(getFileNames("src/diamonds/nayms/facets/"));
fileNames = fileNames.concat(getFileNames("src/diamonds/shared/facets/"));

const namesToRemove = ["DiamondCutFacet", "OwnershipFacet"];

fileNames = fileNames.filter((name) => !namesToRemove.includes(name));

fileNames.push("Nayms");

fileNames.forEach((name, index) => {
  console.log(`contractName[${index}] = "${name}";`);
});

const formattedFileNames = fileNames.map((name) => `'${name}'`);

const arrayString = `[${formattedFileNames.join(",")}]`;

console.log(formattedFileNames);

let cmd = `forge script CodeRecon -s "run(string[] memory)" ${arrayString} -f ${process.env.ETH_MAINNET_RPC_URL} --chain-id 1 --etherscan-api-key ${process.env.ETHERSCAN_API_KEY} -vv`;

console.log(`Running command forge script CodeRecon`);

let output = execSync(cmd);
console.log(`Output: ${output}`);

console.log("Running parse-json.js");
execSync("node cli-tools/parse-json.js");
