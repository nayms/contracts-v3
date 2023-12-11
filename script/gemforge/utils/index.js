const path = require("path");
const rootFolder = path.join(__dirname, "..", "..", "..");

const ethers = require("ethers");
const config = require(path.join(rootFolder, "gemforge.config.cjs"));
const deployments = require(path.join(rootFolder, "gemforge.deployments.json"));
const { abi } = require(path.join(rootFolder, "forge-artifacts/IDiamondProxy.sol/IDiamondProxy.json"));

const loadTarget = (exports.loadTarget = (targetId) => {
    const networkId = config.targets[targetId].network;
    const network = config.networks[networkId];
    const walletId = config.targets[targetId].wallet;
    const wallet = config.wallets[walletId];

    const proxyAddress = deployments[targetId]?.contracts.find((a) => a.name === "DiamondProxy")?.onChain.address;

    const provider = new ethers.providers.JsonRpcProvider(network.rpcUrl);
    const signer = ethers.Wallet.fromMnemonic(wallet.config.words).connect(provider);
    const contract = proxyAddress ? new ethers.Contract(proxyAddress, abi, signer) : null;

    return { networkId, network, walletId, wallet, proxyAddress, signer, contract };
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
    const { contract } = loadTarget(targetId);

    const upgradeId = await exports.calculateUpgradeId(cutFile);

    console.log(`Enabling upgrade in contract, upgrade id: ${upgradeId}`);

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
