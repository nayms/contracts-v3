#!/usr/bin/env node

const chalk = require("chalk");
const path = require("path");
const fs = require("fs");
const rootFolder = path.join(__dirname, "..", "..");
const config = require(path.join(rootFolder, "gemforge.config.cjs"));

const { getProxyAddress, calculateUpgradeId, assertUpgradeIdIsEnabled, enableUpgradeViaGovernance } = require("./utils");

const _showTargetInfo = async (targetId) => {
    console.log(`Target: ${targetId}`);
    console.log(`Network: ${config.targets[targetId].network}`);
    console.log(`Wallet: ${config.targets[targetId].wallet}`);
    console.log(`\nDiamond Proxy: ${chalk.green(getProxyAddress(targetId))}\n`);
};

const tellUserToEnableUpgrade = async (targetId, cutFile) => {
    const upgradeId = await calculateUpgradeId(cutFile);

    console.log(`\nUpgrade ID: ${chalk.green(upgradeId)}\n`);

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

    const cutFile = path.join(rootFolder, ".gemforge/cut.json");

    _showTargetInfo(targetArg);

    switch (process.argv[3]) {
        case "--dry": {
            console.log("Dry-run Deployment");
            await $`yarn gemforge deploy ${targetArg} --dry`;
            break;
        }
        case "--fresh": {
            console.log(`Fresh Deploy`);
            await $`yarn gemforge deploy ${targetArg} -n`;
            break;
        }
        case "--upgrade-start": {
            console.log(`Upgrade - Deploy Facets`);
            if (fs.existsSync(cutFile)) {
                fs.unlinkSync(cutFile);
            }
            await $`yarn gemforge deploy ${targetArg} --verbose --pause-cut-to-file ${cutFile}`;
            if (!fs.existsSync(cutFile)) {
                console.log(`No upgrade necesary!`);
            } else {
                await tellUserToEnableUpgrade(targetArg, cutFile);
            }
            break;
        }
        case "--upgrade-finish": {
            console.log(`Upgrade - Diamond Cut`);
            if (!fs.existsSync(cutFile)) {
                throw new Error(`Cut JSON file not found - please run the first upgrade step first!`);
            }
            if (targetArg !== "mainnet" && targetArg !== "mainnetFork" && targetArg !== "base" && targetArg !== "baseFork") {
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
