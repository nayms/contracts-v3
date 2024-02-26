#!/usr/bin/env node

const chalk = require("chalk");

(async () => {
    require("dotenv").config();
    const { $ } = await import("execa");

    const deploymentInfo = require("../../gemforge.deployments.json");
    const gemforgeConfig = require("../../gemforge.config.cjs");

    const target = process.env.GEMFORGE_DEPLOY_TARGET;
    if (!target) {
        throw new Error("GEMFORGE_DEPLOY_TARGET env var not set");
    }

    // skip for localhost and forks
    if (target === "local" || /fork/i.test(target)) {
        console.log("Skipping contract verification on", target);
        return;
    }

    const contracts = deploymentInfo[target]?.contracts || [];
    const verifiers = gemforgeConfig.networks?.[target]?.verifiers || [{ verifierName: "etherscan" }];

    for (const { verifierName, verifierUrl, verifierApiKey } of verifiers) {
        console.log(chalk.cyan(`Verifying ${target} target on ${verifierName}`));

        const apiKey = verifierApiKey || process.env.ETHERSCAN_API_KEY;
        const verificationArg = verifierUrl ? `--verifier-url=${verifierUrl}` : `--verifier=${verifierName}`;

        for (const { name, onChain } of contracts) {
            let args = "0x";

            if (onChain.constructorArgs.length) {
                args = (await $`cast abi-encode constructor(address) ${onChain.constructorArgs.join(" ")}`).stdout;
            }

            console.log(`Verifying ${name} at ${onChain.address} with args ${args}`);

            await $`forge v ${onChain.address} ${name} --constructor-args ${args} --chain-id ${deploymentInfo[target].chainId} ${verificationArg} --etherscan-api-key ${apiKey} --watch`;

            console.log(`Verified!`);
        }
    }
})();
