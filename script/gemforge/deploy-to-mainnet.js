#!/usr/bin/env node

const path = require("path");
const fs = require("fs");
const rootFolder = path.join(__dirname, "..", "..");
const { loadTarget, calculateUpgradeId, assertUpgradeIdIsEnabled } = require("./utils");

const _showTargetInfo = async (targetId) => {
    const { networkId, network, walletId, proxyAddress, signer, contract } = loadTarget(targetId);

    console.log(`Target: ${targetId}`);
    console.log(`Network: ${networkId} - ${network.rpcUrl}`);
    console.log(`Wallet: ${walletId}`);
    console.log(`System Admin: ${await signer.getAddress()}`);
    console.log(`Proxy: ${proxyAddress}`);
};

const tellUserToEnableUpgrade = async (targetId, cutFile) => {
    _showTargetInfo(targetId);

    const upgradeId = await calculateUpgradeId(targetId, cutFile);

    console.log(`Upgrade id: ${upgradeId}`);

    console.log(`Please log into the MPC and enable this upgrade!`);
};

const assertThatUpgradeIsEnabled = async (targetId, cutFile) => {
    _showTargetInfo(targetId);

    const upgradeId = await calculateUpgradeId(targetId, cutFile);

    await assertUpgradeIdIsEnabled(targetId, upgradeId);
};

(async () => {
    const execa = await import("execa");
    const $ = execa.$({
        cwd: rootFolder,
        stdio: "inherit",
        shell: true,
        env: {
            ...process.env,
        },
    });

    const targetArg = process.argv[2];

    if (!targetArg || targetArg !== "mainnet") {
        throw new Error(`Please use deploy to deploy to non-mainnet targets!`);
    }

    console.log(`Deploying ${targetArg}`);

    const cutFile = path.join(rootFolder, ".gemforge/mainnet-cut.json");
    if (fs.existsSync(cutFile)) {
        fs.unlinkSync(cutFile);
    }

    switch (process.argv[3]) {
        case "--fresh": {
            console.log(`Fresh...`);
            await $`yarn gemforge deploy ${targetArg} -n`;
            break;
        }
        case "--upgrade-start": {
            console.log(`Upgrade step 1...`);
            await $`yarn gemforge deploy ${targetArg} --pause-cut-to-file ${cutFile}`;
            await tellUserToEnableUpgrade(targetArg, cutFile);
            break;
        }
        case "--upgrade-finish": {
            console.log(`Upgrade step 2...`);
            await assertThatUpgradeIsEnabled(targetArg, cutFile);
            await $`yarn gemforge deploy ${targetArg} --resume-cut-from-file ${cutFile}`;
            break;
        }
        default: {
            throw new Error("Expecting one of: --fresh, --upgrade-start, --upgrade-finish");
        }
    }

    console.log(`Done!`);
})();
