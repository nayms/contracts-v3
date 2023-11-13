module.exports = {
  Nayms: require("src/generated/abi.json"),
  ERC20: require("./forge-artifacts/IERC20.sol/IERC20.json"),
  Constants: require("./forge-artifacts/LibConstants.sol/LibConstants.json"),
  targets: require("./gemforge.deployments.json"),
};
