const fs = require("fs");

let data = fs.readFileSync("codeReconReport.json", "utf8");
data = JSON.parse(data);

let cleanedString = data.reconResult
  .replace(/\\"/g, '"')
  .replace(/"\{/g, "{")
  .replace(/\}"/g, "}")
  .slice(1, -1);
cleanedString = "[" + cleanedString + "]";
let cleanedJSON = JSON.parse(cleanedString);

data.reconResult = cleanedJSON;

fs.writeFileSync("codeReconReport.json", JSON.stringify(data, null, 2));
