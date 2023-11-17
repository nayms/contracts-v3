#!/usr/bin/env node
/* eslint-disable node/shebang */

(async () => {
    require("dotenv").config();
    const { $ } = await import("execa");

    const deploymentInfo = require("../../gemforge.deployments.json");

    const target = process.env.GEMFORGE_DEPLOY_TARGET;
    if (!target) {
        throw new Error("GEMFORGE_DEPLOY_TARGET env var not set");
    }

    // skip localhost
    if (target === "local") {
        console.log("Skipping verification on", target);
        return;
    }

    console.log(`Verifying for target ${target} ...`);

    const contracts = (deploymentInfo[target] || {}).contracts || [];

    for (const { name, onChain } of contracts) {
        let args = "0x";

        if (onChain.constructorArgs.length) {
            args = (await $`cast abi-encode constructor(address) ${onChain.constructorArgs.join(" ")}`).stdout;
        }

        console.log(`Verifying ${name} at ${onChain.address} with args ${args}`);

        await $`forge verify-contract ${onChain.address} ${name} --constructor-args ${args} --chain-id ${deploymentInfo[target].chainId} --verifier etherscan --etherscan-api-key ${process.env.ETHERSCAN_API_KEY} --watch`;

        console.log(`Verified!`);
    }
})();
