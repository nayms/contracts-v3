#!/usr/bin/env node

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
        console.log("Skipping verification on", target);
        return;
    }

    console.log(`Verifying for target ${target} ...`);

    const verifierUrl = gemforgeConfig.networks?.[target]?.verifierUrl;
    const verificationArg = verifierUrl ? `--verifier-url=${verifierUrl}` : "--verifier etherscan";

    const contracts = deploymentInfo[target]?.contracts || [];

    for (const { name, onChain } of contracts) {
        let args = "0x";

        if (onChain.constructorArgs.length) {
            args = (await $`cast abi-encode constructor(address) ${onChain.constructorArgs.join(" ")}`).stdout;
        }

        console.log(`Verifying ${name} at ${onChain.address} with args ${args}`);

        await $`forge verify-contract ${onChain.address} ${name} --constructor-args ${args} --chain-id ${deploymentInfo[target].chainId} ${verificationArg} --etherscan-api-key ${process.env.ETHERSCAN_API_KEY} --watch`;

        console.log(`Verified!`);
    }
})();
