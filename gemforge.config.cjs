require("dotenv").config();
const fs = require("fs");
const ethers = require("ethers");

const MNEMONIC = fs.readFileSync("./nayms_mnemonic.txt").toString().trim();

const walletOwnerIndex = 19;
const sysAdminAddress = ethers.Wallet.fromMnemonic(MNEMONIC).address;

module.exports = {
  // Configuration file version
  version: 2,
  // Compiler configuration
  solc: {
    // SPDX License - to be inserted in all generated .sol files
    license: "MIT",
    // Solidity compiler version - to be inserted in all generated .sol files
    version: "0.8.20",
  },
  // commands to execute
  commands: {
    // the build command
    build: "forge build",
  },
  paths: {
    // contract built artifacts folder
    artifacts: "forge-artifacts",
    // source files
    src: {
      // file patterns to include in facet parsing
      facets: [
        // include all .sol files in the facets directory ending "Facet"
        "src/facets/*Facet.sol",
      ],
    },
    // folders for gemforge-generated files
    generated: {
      // output folder for generated .sol files
      solidity: "src/generated",
      // output folder for support scripts and files
      support: ".gemforge",
      // deployments JSON file
      deployments: "gemforge.deployments.json",
    },
    // library source code
    lib: {
      // diamond library
      diamond: "lib/diamond-2-hardhat",
    },
  },
  // artifacts configuration
  artifacts: {
    // artifact format - "foundry" or "hardhat"
    format: "foundry",
  },
  // generator options
  generator: {
    // proxy interface options
    proxyInterface: {
      // imports to include in the generated IDiamondProxy interface
      imports: ["src/shared/FreeStructs.sol"],
    },
  },
  // diamond configuration
  diamond: {
    // Whether to include public methods when generating the IDiamondProxy interface. Default is to only include external methods.
    publicMethods: false,
    init: {
      contract: "InitDiamond",
      function: "init",
    },
    // Names of core facet contracts - these will not be modified/removed once deployed and are also reserved names.
    // This default list is taken from the diamond-2-hardhat library.
    // NOTE: WE RECOMMEND NOT CHANGING ANY OF THESE EXISTING NAMES UNLESS YOU KNOW WHAT YOU ARE DOING.
    coreFacets: [
      "DiamondCutFacet",
      "DiamondLoupeFacet",
      "NaymsOwnershipFacet",
      "ACLFacet",
      "GovernanceFacet",
    ],
  },
  // lifecycle hooks
  hooks: {
    // shell command to execute before build
    preBuild: "",
    // shell command to execute after build
    postBuild: "",
    // shell command to execute before deploy
    preDeploy: "",
    // shell command to execute after deploy
    postDeploy: "./script/gemforge/verify-on-etherscan.js",
  },
  // Wallets to use for deployment
  wallets: {
    // Wallet named "wallet1"
    wallet1: {
      // Wallet type - mnemonic
      type: "mnemonic",
      // Wallet config
      config: {
        // Mnemonic phrase
        words: MNEMONIC,
        // 0-based index of the account to use
        index: walletOwnerIndex,
      },
    },
  },
  networks: {
    local: { rpcUrl: "http://localhost:8545" },
    sepolia: { rpcUrl: process.env.ETH_SEPOLIA_RPC_URL },
    sepoliaFork: { rpcUrl: "http://localhost:8545" },
    mainnet: { rpcUrl: process.env.ETH_MAINNET_RPC_URL },
    mainnetFork: { rpcUrl: "http://localhost:8545" },
    baseGoerli: {
      rpcUrl: process.env.BASE_GOERLI_RPC_URL,
      verifierUrl: "https://api-goerli.basescan.org/api",
    },
    base: {
      rpcUrl: process.env.BASE_MAINNET_RPC_URL,
      verifierUrl: "https://api.basescan.org/api"
    },
    baseFork: { rpcUrl: "http://localhost:8545" },
  },
  // Targets to deploy
  targets: {
    local: {
      network: "local",
      wallet: "wallet1",
      initArgs: [sysAdminAddress],
    },
    sepolia: {
      network: "sepolia",
      wallet: "wallet1",
      initArgs: [sysAdminAddress],
    },
    sepoliaFork: {
      network: "sepoliaFork",
      wallet: "wallet1",
      initArgs: [sysAdminAddress],
    },
    mainnet: {
      network: "mainnet",
      wallet: "wallet1",
      initArgs: [sysAdminAddress],
    },
    mainnetFork: {
      network: "mainnetFork",
      wallet: "wallet1",
      initArgs: [],
    },
    baseGoerli: {
      network: "baseGoerli",
      wallet: "wallet1",
      initArgs: [sysAdminAddress],
    },
    base: {
      network: "base",
      wallet: "wallet1",
      initArgs: [sysAdminAddress],
    },
    baseFork: {
      network: "baseFork",
      wallet: "wallet1",
      initArgs: [sysAdminAddress],
    },
  },
};
