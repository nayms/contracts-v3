require("dotenv").config();

const fs = require("fs");
const ethers = require("ethers");

const MNEMONIC = fs.existsSync("./nayms_mnemonic.txt") ? fs.readFileSync("./nayms_mnemonic.txt").toString().trim() : "test test test test test test test test test test test junk";

const sysAdminAddress = ethers.Wallet.fromMnemonic(MNEMONIC)?.address;

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
    proxy: {
      // custom template to use instead of the Gemforge default one
      template: "templates/DiamondProxy.sol",
    },
    // proxy interface options
    proxyInterface: {
      // imports to include in the generated IDiamondProxy interface
      imports: ["src/shared/FreeStructs.sol", "lib/v4-core/src/types/BalanceDelta.sol"],
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
          verifierApiKey: process.env.BLOCKSCOUT_API_KEY,
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
    // `governance` attribute is only releveant for testnets, it's a wallet to use to auto approve the upgrade ID within the script
    local: { network: "local", wallet: "devOwnerWallet", governance: "devSysAdminWallet", initArgs: [sysAdminAddress] },
    sepolia: { network: "sepolia", wallet: "devOwnerWallet", governance: "devSysAdminWallet", initArgs: [sysAdminAddress] },
    sepoliaFork: { network: "local", wallet: "devOwnerWallet", governance: "devSysAdminWallet", initArgs: [sysAdminAddress] },
    mainnet: { network: "mainnet", wallet: "wallet3", initArgs: [sysAdminAddress] },
    mainnetFork: { network: "local", wallet: "devOwnerWallet", initArgs: [sysAdminAddress] },
    baseSepolia: { network: "baseSepolia", wallet: "devOwnerWallet", governance: "devSysAdminWallet", initArgs: [sysAdminAddress] },
    baseSepoliaFork: { network: "local", wallet: "devOwnerWallet", governance: "devSysAdminWallet", initArgs: [sysAdminAddress] },
    base: { network: "base", wallet: "wallet3", initArgs: [sysAdminAddress] },
    baseFork: { network: "local", wallet: "devOwnerWallet", initArgs: [sysAdminAddress] },
    aurora: { network: "aurora", wallet: "wallet3", initArgs: [sysAdminAddress] },
    auroraFork: { network: "local", wallet: "wallet3", initArgs: [sysAdminAddress] },
    auroraTestnet: { network: "auroraTestnet", wallet: "devOwnerWallet", governance: "devSysAdminWallet", initArgs: [sysAdminAddress] },
    auroraTestnetFork: { network: "local", wallet: "devOwnerWallet", governance: "devSysAdminWallet", initArgs: [sysAdminAddress] },
  },
};
