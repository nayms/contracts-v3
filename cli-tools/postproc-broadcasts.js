const fs = require("fs");
const glob = require("glob");
const chalk = require("chalk");

console.log(chalk.yellow("Post-processing broadcast files:"));

var walk = function (src, callback) {
  glob(src + "/**/*", callback);
};

walk("broadcast", function (err, results) {
  if (err) {
    console.log("Error", err);
    return;
  }

  results.forEach((filePath) => {
    if (filePath.endsWith(".json") && !filePath.includes("/31337/")) {
      const f = fs.readFileSync(filePath, { encoding: "utf-8" });
      const fileObject = JSON.parse(f);

      if (!fileObject.transactions.some((t) => t.rpc != null)) {
        return;
      }

      fileObject.transactions
        .filter((t) => t.rpc != null)
        .forEach((tx) => {
          console.log(
            chalk.green(tx.transactionType, tx.contractName),
            tx.hash
          );
          delete tx.rpc;
        });

      try {
        const data = JSON.stringify(fileObject, null, 2);
        fs.writeFileSync(filePath, data);
        console.log(chalk.blue(filePath), "rpc key stripped");
      } catch (error) {
        console.error(err);
      }
    }
  });
  console.log("== √ Done ==");
});
