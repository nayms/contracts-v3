#!/usr/bin/env node
/* eslint-disable node/shebang */

const path = require("path");
const fs = require("fs");
const rootFolder = path.join(__dirname, "..", "..");
const { loadTarget, calculateUpgradeId, assertUpgradeIdIsEnabled, enableUpgradeViaGovernance } = require("./utils");

const _showTargetInfo = async (targetId) => {
    const { networkId, network, walletId, proxyAddress, signer } = loadTarget(targetId);

    console.log(`Target: ${targetId}`);
    console.log(`Network: ${networkId} - ${network.rpcUrl}`);
    console.log(`Wallet: ${walletId}`);
    console.log(`System Admin: ${await signer.getAddress()}`);
    console.log(`Proxy: ${proxyAddress}`);
};

const tellUserToEnableUpgrade = async (targetId, cutFile) => {
    const upgradeId = await calculateUpgradeId(cutFile);

    console.log(`Upgrade id: ${upgradeId}`);

    if (targetId === "mainnet") {
        console.log(`Please log into the MPC and enable this upgrade!`);
    } else {
        console.log(`Please run the next upgrade step to complete the upgrade.`);
    }
};

const assertThatUpgradeIsEnabled = async (targetId, cutFile) => {
    const upgradeId = await calculateUpgradeId(cutFile);

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

    if (!targetArg) {
        throw new Error(`Please specify a target!`);
    }

    console.log(`Deploying ${targetArg}`);

    const cutFile = path.join(rootFolder, ".gemforge/cut.json");

    _showTargetInfo(targetArg);

    switch (process.argv[3]) {
        case "--fresh": {
            console.log(`Fresh...`);
            await $`yarn gemforge deploy ${targetArg} -n`;
            break;
        }
        case "--upgrade-start": {
            console.log(`Upgrade step 1...`);
            if (fs.existsSync(cutFile)) {
                fs.unlinkSync(cutFile);
            }
            await $`yarn gemforge deploy ${targetArg} --pause-cut-to-file ${cutFile}`;
            if (!fs.existsSync(cutFile)) {
                console.log(`No upgrade necesary!`);
            } else {
                await tellUserToEnableUpgrade(targetArg, cutFile);
            }
            break;
        }
        case "--upgrade-finish": {
            console.log(`Upgrade step 2...`);
            if (!fs.existsSync(cutFile)) {
                throw new Error(`Cut JSON file not found - please run the first upgrade step first!`);
            }
            if (targetArg !== "mainnet") {
                await enableUpgradeViaGovernance(targetArg, cutFile);
            }
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
