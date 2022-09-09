let deployedAddresses;
try {
  deployedAddresses = require("./deployedAddresses.json");
} catch (_ignore) {}

const coreContracts = [
  { name: "Nayms", actual: "INayms" },
  { name: "ERC20", actual: "IERC20" },
  { name: "LibACL", actual: "LibACL" },
  { name: "LibAdmin", actual: "LibAdmin" },
  { name: "LibEntity", actual: "LibEntity" },
  { name: "LibFeeRouter", actual: "LibFeeRouter" },
  { name: "LibMarket", actual: "LibMarket" },
  { name: "LibSimplePolicy", actual: "LibSimplePolicy" },
  { name: "LibTokenizedVault", actual: "LibTokenizedVault" },
  { name: "LibTokenizedVaultIO", actual: "LibTokenizedVaultIO" },
  { name: "Constants", actual: "Constants" },
].reduce((m, n) => {
  m[n.name] = require(`./forge-artifacts/${n.actual}.sol/${n.actual}.json`);
  return m;
}, {});

// todo: extract events from abis
const extractEventsFromAbis = (abis) =>
  abis.reduce((output, contract) => {
    contract.abi
      .filter(({ type }) => type === "event")
      .forEach((e) => {
        if (!output[e.name]) {
          output[e.name] = e;
        }
      });
    return output;
  }, {});

module.exports = {
  addresses: deployedAddresses,
  contracts: coreContracts,
  events: extractEventsFromAbis(Object.values(coreContracts)),
  extractEventsFromAbis,
};
