#!/usr/bin/env node

const path = require("path");
const fs = require("fs");
const rootFolder = path.join(__dirname, "..", "..");
const { loadTarget, calculateUpgradeId, assertUpgradeIdIsEnabled } = require("./utils");

const enableCutViaGovernance = async (targetId, cutFile) => {
    const { networkId, network, walletId, proxyAddress, signer, contract } = loadTarget(targetId);

    console.log(`Target: ${targetId}`);
    console.log(`Network: ${networkId} - ${network.rpcUrl}`);
    console.log(`Wallet: ${walletId}`);
    console.log(`System Admin: ${await signer.getAddress()}`);
    console.log(`Proxy: ${proxyAddress}`);

    const upgradeId = await calculateUpgradeId(targetId, cutFile);

    console.log(`Upgrade id: ${upgradeId}`);

    const tx = await contract.createUpgrade(upgradeId);
    console.log(`Transaction hash: ${tx.hash}`);
    await tx.wait();
    console.log("Transaction mined!");

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

    if (!targetArg || targetArg === "mainnet") {
        throw new Error(`Please use deploy-mainnet to deploy to mainnet!`);
    }

    console.log(`Deploying ${targetArg}`);

    if (process.argv[3] == "--fresh") {
        console.log(`Fresh...`);

        await $`yarn gemforge deploy ${targetArg} -n`;
    } else {
        console.log(`Upgrade...`);

        const cutFile = path.join(rootFolder, ".gemforge/cut.json");
        if (fs.existsSync(cutFile)) {
            fs.unlinkSync(cutFile);
        }

        await $`yarn gemforge deploy ${targetArg} --pause-cut-to-file ${cutFile}`;

        if (!fs.existsSync(cutFile)) {
            console.log(`Nothing to upgrade!`);
        } else {
            console.log(`Enabling cut via governance for ${targetArg}...`);

            await enableCutViaGovernance(targetArg, cutFile);

            console.log(`Resuming deployment for ${targetArg}...`);

            await $`yarn gemforge deploy ${targetArg} --resume-cut-from-file ${cutFile}`;
        }
    }

    console.log(`Done!`);
})();
