const fs = require("fs");
const https = require("https");

const networkId = '11155111';
const networkName = 'sepolia';

if (process.argv.length > 3) {
  console.error("Invalid arguments, only `--dry-run` or no args allowed");
  return;
}

let raw = fs.readFileSync(`broadcast/SmartDeploy.s.sol/${networkId}/smartDeploy-latest.json`);
let json = JSON.parse(raw);

json.transactions
  .filter((tx) => tx.contractName && tx.contractName.includes("Facet"))
  .forEach((element) => {
    var url = `https://api.etherscan.io/api?module=contract&action=getabi&address=${element.contractAddress}&apikey=${process.env.ETHERSCAN_API_KEY}`;

    https
      .get(url, (resp) => {
        let data = "";
        resp.on("data", (chunk) => (data += chunk));
        resp.on("end", () => {
          const r = JSON.parse(data);
          // r.status: 0 not verified, 1 verified
          if (r.status == 0) {
            // do verification!
            let cmd = `forge v ${element.contractAddress} src/diamonds/nayms/facets/${element.contractName}.sol:${element.contractName} --etherscan-api-key $ETHERSCAN_API_KEY --chain ${networkName} --watch`;

            if (process.argv.length === 3 && process.argv[2] === "--dry-run") {
              console.log(cmd);
            } else {
              const { exec } = require("child_process");
              exec(cmd, (error, stdout, stderr) => {
                if (error) {
                  console.log(`error: ${error.message}`);
                  return;
                }
                if (stderr) {
                  console.log(`stderr: ${stderr}`);
                  return;
                }
                console.log(stdout);
              });
            }
          }
        });
      })
      .on("error", (err) => console.log("Error: " + err.message));
  });
