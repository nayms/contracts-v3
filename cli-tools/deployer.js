const { Wallet } = require("ethers");
const fs = require("fs");
const chalk = require("chalk");
const dotenv = require("dotenv");

dotenv.config();


if (process.argv.length < 4) {
    console.error(chalk.red(`Must provide deployment action and target network!`));
    console.log(`Allowed actions are: ${chalk.green("deploy")} and ${chalk.green("upgrade")}`);
    process.exit(1);
}

const [action, networkId, ...otherArgs] = process.argv.slice(2);

const flags = new Set(["--fork", "--dry-run"]);
if (!otherArgs.every((a) => flags.has(a))) {
    console.log(`Allowed flags are only: ${chalk.green("--fork")} and ${chalk.green("--dry-run")}`);
    process.exit(1);
}

const fork = otherArgs.includes("--fork");
const dryRun = otherArgs.includes("--dry-run");

const rpcUrl = fork ? "http://localhost:8545" : process.env[`ETH_${networkId}_RPC_URL`];
const mnemonicFile = networkId === "1" && !fork ? "nayms_mnemonic_mainnet.txt" : "nayms_mnemonic.txt";
const mnemonic = fs.readFileSync(mnemonicFile).toString();

const ownerAddress = Wallet.fromMnemonic(mnemonic, `m/44'/60'/0'/0/19`).address; // acc20
const systemAdminAddress =
    networkId === "1"
        ? "0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929" // mainnet sysAdminB
        : Wallet.fromMnemonic(mnemonic, `m/44'/60'/0'/0/0`).address; // acc1

if (action === "deploy") {
    console.log(`[ ${chalk.green(networkId + (fork ? "-fork" : ""))} ] Deploying new diamond`);

    console.log(`\n[ ${chalk.green("Deploying contracts")} ]\n`);
    const deployNewDiamondCmd = deployDiamond(rpcUrl, networkId, ownerAddress, systemAdminAddress);
    execute(deployNewDiamondCmd);

    console.log(`\n[ ${chalk.green("Initializing upgrade")} ]\n`);
    const initSimCmd = upgrade(rpcUrl, networkId, ownerAddress, systemAdminAddress, false);
    const result = execute(initSimCmd);
    const upgradeHash = getUpgradeHash(result);

    console.log(`\n[ ${chalk.green("Scheduling upgrade")} ]\n`);
    const scheduleCommand = scheduleUpgrade({
        rpcUrl,
        networkId,
        upgradeHash,
        systemAdminAddress,
        mnemonicFile: mnemonicFile,
        mnemonicIndex: 0,
    });
    execute(scheduleCommand);

    console.log(`\n[ ${chalk.green("Doing upgrade")} ]\n`);
    const upgradeCmd = upgrade(rpcUrl, networkId, ownerAddress, systemAdminAddress);
    execute(upgradeCmd);
} else if (action === "upgrade") {
    const addressesRaw = fs.readFileSync("deployedAddresses.json");
    const addresses = JSON.parse(addressesRaw);

    console.log(`[ ${chalk.green(networkId + (fork ? "-fork" : ""))} ] upgrade => ${chalk.greenBright(addresses[networkId])}\n`);

    if (networkId === "1" && fork) {
        // transfer ownership to non-mainnet account
        execute(`cast rpc anvil_impersonateAccount ${systemAdminAddress}`);
        execute(`cast send ${addresses[networkId]} "transferOwnership(address)" \\
            ${ownerAddress} \\
            -r http:\\127.0.0.1:8545 \\
            --unlocked \\
            --from ${systemAdminAddress}`);
        execute(`cast rpc anvil_setBalance ${ownerAddress} 10000000000000000000 -r http:\\127.0.0.1:8545`);
    }

    console.log(`\n[ ${chalk.green("Deploying contracts")} ]\n`);
    const upgradeCmd = upgrade(rpcUrl, networkId, ownerAddress, systemAdminAddress, false);
    const result = execute(upgradeCmd);
    const upgradeHash = getUpgradeHash(result);

    if (networkId === "1" && !fork) {
        console.log(`Please get the following upgrade hash approved: ${chalk.green(upgradeHash)}`);
    } else {
        console.log(`\n[ ${chalk.green("Scheduling upgrade")} ]\n`);
        const scheduleCommand = scheduleUpgrade({
            rpcUrl,
            networkId,
            upgradeHash,
            systemAdminAddress,
            mnemonicFile: mnemonicFile,
            mnemonicIndex: 0,
            fork,
            diamondAddress: addresses[networkId],
        });
        execute(scheduleCommand);
    }

    console.log(`\n[ ${chalk.green("Preparing upgrade")} ]\n`);
    const prepCmd = `node ./cli-tools/prep-upgrade.js broadcast/SmartDeploy.s.sol/${networkId}/smartDeploy-latest.json`;
    execute(prepCmd);

    console.log(`\n[ ${chalk.green("Diamond cut")} ]\n`);
    const diamondCutCmd = diamondCut({
        rpcUrl,
        networkId,
        upgradeHash,
        ownerAddress,
        mnemonicFile: mnemonicFile,
        mnemonicIndex: networkId === "1" && !fork ? 1 : 19,
    });
    if (networkId === "1" && !fork) {
        console.log("Execute the following command to cut in the facets, once the upgrade hash is approved");
        console.log(chalk.blue(diamondCutCmd));
    } else {
        execute(diamondCutCmd);
    }
} else {
    console.log(chalk.red("Supported actions are: 'deploy' and 'upgrade'!"));
    process.exit(1);
}

function getUpgradeHash(result) {
    if (!result) {
        return "not found";
    }
    const hashLine = result
        .split("\n")
        .find((line) => line.includes("upgradeHash: bytes32"))
        .trim()
        .split(" ");
    return hashLine[hashLine.length - 1];
}

function deployDiamond(rpcUrl, networkId, owner, sysAdmin, facetsToCutIn = '"[]"', salt = `0xdeffffffff`) {
    return smartDeploy({
        rpcUrl,
        networkId,
        newDeploy: true,
        owner,
        sysAdmin,
        initDiamond: false,
        facetAction: 2,
        facetsToCutIn,
        salt,
        sender: owner,
        mnemonicFile: "./nayms_mnemonic.txt",
        mnemonicIndex: 19,
        broadcast: true,
    });
}

function upgrade(rpcUrl, networkId, owner, sysAdmin, initDiamond = true, broadcast = true, facetsToCutIn = '"[]"', salt = `0xdeffffffff`) {
    return smartDeploy({
        rpcUrl,
        networkId,
        newDeploy: false,
        owner,
        sysAdmin,
        initDiamond,
        facetAction: 1,
        facetsToCutIn,
        salt,
        sender: owner,
        mnemonicFile: "./nayms_mnemonic.txt",
        mnemonicIndex: 19,
        broadcast,
    });
}

function smartDeploy(config) {
    let command = `forge script SmartDeploy \\
        -s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" ${config.newDeploy} ${config.owner} ${config.sysAdmin} ${config.initDiamond} ${config.facetAction} ${config.facetsToCutIn} ${config.salt} \\
        -f ${config.rpcUrl} \\
        --chain-id ${config.networkId}`;

    if (config.broadcast) {
        command += ` \\
        --sender ${config.sender} \\
        --mnemonic-paths ${config.mnemonicFile} \\
        --mnemonic-indexes ${config.mnemonicIndex}`;
    }

    command += ` \\
        -vv \\
        --ffi`;

    if (config.broadcast) {
        command += ` \\
        --broadcast \\
        --verify --delay 30 --retries 10`;
    }

    return command;
}

function scheduleUpgrade(config) {
    const isFork = config.networkId === "1" && config.fork;
    const impersonateIfNeeded = isFork ? `cast rpc anvil_impersonateAccount ${config.systemAdminAddress} && ` : "";
    const mnemonicIfNeeded = isFork
        ? ""
        : ` \\
        --chain-id ${config.networkId} \\
        --mnemonic ${config.mnemonicFile} \\
        --mnemonic-index ${config.mnemonicIndex}
    `;

    return `${impersonateIfNeeded} cast send ${config.diamondAddress} "createUpgrade(bytes32)" \\
        ${config.upgradeHash} \\
        --rpc-url ${config.rpcUrl} ${isFork ? "--unlocked" : ""} \\
        --from ${config.systemAdminAddress} ${mnemonicIfNeeded}`;
}

function diamondCut(config) {
    return `forge script S03UpgradeDiamond \\
        -s "run(address)" ${config.ownerAddress} \\
        -f ${config.rpcUrl} \\
        --chain-id ${config.networkId} \\
        --sender ${config.ownerAddress} \\
        --mnemonic-paths ${config.mnemonicFile} \\
        --mnemonic-indexes ${config.mnemonicIndex} \\
        -vv \\
        --ffi \\
        --broadcast`;
}

function execute(cmd) {
    console.log(cmd);

    if (!dryRun) {
        const { execSync } = require("child_process");

        const result = execSync(cmd).toString();
        console.log("\n\n ------------------ \n\n", result);
        return result;
    }
}
