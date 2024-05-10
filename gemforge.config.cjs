require("dotenv").config();

const fs = require("fs");
const ethers = require("ethers");

const MNEMONIC = fs.existsSync("./nayms_mnemonic.txt")
  ? fs.readFileSync("./nayms_mnemonic.txt").toString().trim()
  : "test test test test test test test test test test test junk";

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
    coreFacets: ["DiamondCutFacet", "DiamondLoupeFacet", "NaymsOwnershipFacet", "ACLFacet", "GovernanceFacet"],
  },
  // lifecycle shell command hooks
  hooks: {
    preBuild: "",
    postBuild: "",
    preDeploy: "",
    postDeploy: "./script/gemforge/verify.js",
  },
  // Wallets to use for deployment
  wallets: {
    // nayms owner
    devOwnerWallet: {
      type: "mnemonic",
      config: {
        words: MNEMONIC,
        index: 19,
      },
    },
    // nayms sys admin
    devSysAdminWallet: {
      type: "mnemonic",
      config: {
        words: MNEMONIC,
        index: 0,
      },
    },
    wallet3: {
      type: "private-key",
      config: {
        key: process.env.CONTRACT_OWNER || "",
      },
    },
  },
  networks: {
    local: { rpcUrl: "http://localhost:8545" },
    sepolia: { rpcUrl: process.env.ETH_SEPOLIA_RPC_URL },
    mainnet: { rpcUrl: process.env.ETH_MAINNET_RPC_URL },
    baseSepolia: {
      rpcUrl: process.env.BASE_SEPOLIA_RPC_URL,
      verifiers: [
        {
          verifierName: "etherscan",
          verifierUrl: "https://api-sepolia.basescan.org/api",
          verifierApiKey: process.env.BASESCAN_API_KEY,
        },
        {
          verifierName: "blockscout", // needed for louper
          verifierUrl: "https://base-sepolia.blockscout.com/api",
          verifierApiKey: process.env.BLOCKSCOUT_API_KEY,
        },
      ],
    },
    base: {
      rpcUrl: process.env.BASE_MAINNET_RPC_URL,
      verifiers: [
        {
          verifierName: "etherscan",
          verifierUrl: "https://api.basescan.org/api",
          verifierApiKey: process.env.BASESCAN_API_KEY,
        },
      ],
    },
    aurora: {
      rpcUrl: process.env.AURORA_MAINNET_RPC_URL,
      verifiers: [
        {
          verifierName: "aurora",
          verifierUrl: "https://explorer.mainnet.aurora.dev/api",
        },
      ],
    },
    auroraTestnet: {
      rpcUrl: process.env.AURORA_TESTNET_RPC_URL,
      verifiers: [
        {
          verifierName: "aurora",
          verifierUrl: "https://explorer.testnet.aurora.dev/api",
        },
      ],
    },
  },
  targets: {
    local: { network: "local", wallet: "devOwnerWallet", governance: "devSysAdminWallet" },
    sepolia: { network: "sepolia", wallet: "devOwnerWallet", governance: "devSysAdminWallet" },
    sepoliaFork: { network: "local", wallet: "devOwnerWallet", governance: "devSysAdminWallet" },
    mainnet: { network: "mainnet", wallet: "wallet3" },
    mainnetFork: { network: "local", wallet: "devOwnerWallet", governance: "devSysAdminWallet" },
    baseSepolia: { network: "baseSepolia", wallet: "devOwnerWallet", governance: "devSysAdminWallet" },
    baseSepoliaFork: { network: "local", wallet: "devOwnerWallet", governance: "devSysAdminWallet" },
    base: { network: "base", wallet: "wallet3" },
    baseFork: { network: "local", wallet: "devOwnerWallet", governance: "devSysAdminWallet" },
    aurora: { network: "aurora", wallet: "devOwnerWallet" },
    auroraFork: { network: "local", wallet: "devOwnerWallet", governance: "devSysAdminWallet" },
    auroraTestnet: { network: "auroraTestnet", wallet: "devOwnerWallet", governance: "devSysAdminWallet" },
    auroraTestnetFork: { network: "local", wallet: "devOwnerWallet", governance: "devSysAdminWallet" },
  },
};
