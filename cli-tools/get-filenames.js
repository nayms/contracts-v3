const fs = require("fs");
const path = require("path");

function getFileNames(directory) {
  return fs.readdirSync(directory).map((file) => {
    const baseName = path.basename(file, ".sol");
    return path.parse(baseName).name;
  });
}

let fileNames = [];

for (let i = 2; i < process.argv.length; i++) {
  const directoryPath = process.argv[i];
  fileNames = fileNames.concat(getFileNames(directoryPath));
}

const namesToRemove = ["DiamondCutFacet", "OwnershipFacet"];

fileNames = fileNames.filter((name) => !namesToRemove.includes(name));

fileNames.push("Nayms");

fileNames.forEach((name, index) => {
  console.log(`contractName[${index}] = "${name}";`);
});

const formattedFileNames = fileNames.map((name) => `"${name}"`);

const arrayString = `'[${formattedFileNames.join(",")}]'`;

console.log(arrayString);
