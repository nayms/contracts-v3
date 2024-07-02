const chalk = require("chalk");
const path = require("path");
const rootFolder = path.join(__dirname, "..", "..", "..");

const fs = require("fs");
const ethers = require("ethers");
const config = require(path.join(rootFolder, "gemforge.config.cjs"));
const deployments = require(path.join(rootFolder, "gemforge.deployments.json"));
const { abi } = require(path.join(rootFolder, "forge-artifacts/IDiamondProxy.sol/IDiamondProxy.json"));

const loadTarget = (exports.loadTarget = (targetId, walletIdAttr) => {
    const networkId = config.targets[targetId].network;
    const network = config.networks[networkId];
    const walletId = config.targets[targetId][walletIdAttr || "wallet"];
    const wallet = config.wallets[walletId];

    const provider = new ethers.providers.JsonRpcProvider(network.rpcUrl);

    const signer =
        wallet.type === "mnemonic"
            ? ethers.Wallet.fromMnemonic(wallet.config.words, `m/44'/60'/0'/0/${wallet.config.index || 0}`).connect(provider)
            : new ethers.Wallet(wallet.config.key).connect(provider);

    const proxyAddress = getProxyAddress(targetId);
    const contract = proxyAddress ? new ethers.Contract(proxyAddress, abi, signer) : null;

    return { networkId, network, walletId, wallet, proxyAddress, signer, contract };
});

const getProxyAddress = (exports.getProxyAddress = (targetId) => {
    return deployments[targetId]?.contracts.find((a) => a.name === "DiamondProxy")?.onChain.address;
});

exports.calculateUpgradeId = async (cutFile) => {
    const cutData = require(cutFile);
    const encodedData = ethers.utils.defaultAbiCoder.encode(
        ["tuple(address facetAddress, uint8 action, bytes4[] functionSelectors)[]", "address", "bytes"],
        [cutData.cuts, cutData.initContractAddress, cutData.initData]
    );
    return ethers.utils.keccak256(encodedData);
};

exports.enableUpgradeViaGovernance = async (targetId, cutFile) => {
    if (deployments[targetId].chaiId === 1 || deployments[targetId].chaiId === 8453) {
        throw new Error("Only testnet upgrades can be automated!");
    }

    const { contract } = loadTarget(targetId, "governance");

    const upgradeId = await exports.calculateUpgradeId(cutFile);
    console.log(`Approving the upgrade ID: ${chalk.green(upgradeId)}`);

    const tx = await contract.createUpgrade(upgradeId);
    console.log(`Transaction hash: ${tx.hash}`);

    await tx.wait();
    console.log("Transaction mined!");
};

exports.assertUpgradeIdIsEnabled = async (targetId, upgradeId) => {
    const { contract } = loadTarget(targetId);
    const val = await contract.getUpgrade(upgradeId);
    if (!val) {
        throw new Error(`Upgrade not found!`);
    }
};
