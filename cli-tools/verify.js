const fs = require("fs");
const https = require("https");

let raw = fs.readFileSync(
  "broadcast/SmartDeploy.s.sol/5/smartDeploy-latest.json"
);
let json = JSON.parse(raw);

json.transactions
  .filter((tx) => tx.contractName.includes("Facet"))
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
            let cmd = `forge v ${element.contractAddress} src/diamonds/nayms/facets/${element.contractName}.sol:${element.contractName} $ETHERSCAN_API_KEY --chain goerli --watch`;
            console.log(cmd);
          }
        });
      })
      .on("error", (err) => console.log("Error: " + err.message));
  });
