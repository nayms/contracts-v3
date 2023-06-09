const { Wallet } = require("ethers");
const fs = require("fs");
const chalk = require("chalk");
const dotenv = require("dotenv");

dotenv.config();

if (process.argv.length != 4 && process.argv.length != 5) {
    console.error(chalk.red(`Must provide deployment operation and target network!`));
    process.exit(1);
}

const [operation, networkId, fork] = process.argv.slice(2);

const rpcUrl = fork ? "http://localhost:8545" : process.env[`ETH_${networkId}_RPC_URL`];
const mnemonic = fs.readFileSync("nayms_mnemonic.txt").toString();

const ownerAddress = Wallet.fromMnemonic(mnemonic, `m/44'/60'/0'/0/19`).address;
const systemAdminAddress =
    networkId === "1"
        ? "0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929" // mainnet sysAdminB
        : Wallet.fromMnemonic(mnemonic, `m/44'/60'/0'/0/0`).address;

if (operation === "deploy") {
    console.log(`[ ${chalk.green(networkId + (fork ? "-fork" : ""))} ] Deploying new diamond`);

    console.log(`\n[ ${chalk.green("Deploying contracts")} ]\n`);
    const deployNewDiamondCmd = deployDiamondCmd(rpcUrl, networkId, ownerAddress, systemAdminAddress);
    execute(deployNewDiamondCmd);

    console.log(`\n[ ${chalk.green("Initializing upgrade")} ]\n`);
    const initSimCmd = upgrade(rpcUrl, networkId, ownerAddress, systemAdminAddress, false);
    const result = execute(initSimCmd);
    const upgradeHash = getUpgradeHash(result);

    console.log(`\n[ ${chalk.green("Scheduling upgrade")} ]\n`);
    const scheduleCommand = schedule({
        rpcUrl,
        networkId,
        upgradeHash,
        systemAdminAddress,
        mnemonicFile: "./nayms_mnemonic.txt",
        mnemonicIndex: 0,
    });
    execute(scheduleCommand);

    console.log(`\n[ ${chalk.green("Doing upgrade")} ]\n`);
    const upgradeCmd = upgrade(rpcUrl, networkId, ownerAddress, systemAdminAddress);
    execute(upgradeCmd);
} else if (operation === "upgrade") {
    const addressesRaw = fs.readFileSync("deployedAddresses.json");
    const addresses = JSON.parse(addressesRaw);

    console.log(`[ ${chalk.green(networkId + (fork ? "-fork" : ""))} ] upgrade => ${chalk.greenBright(addresses[networkId])}\n`);

    if (networkId === "1" && fork) {
        // transfer ownership
        execute(`cast rpc anvil_impersonateAccount ${systemAdminAddress}`);
        execute(`cast send ${addresses[networkId]} "transferOwnership(address)" \
            ${ownerAddress} \
            -r http:\\127.0.0.1:8545 \
            --unlocked \
            --from ${systemAdminAddress}`);
        execute(`cast rpc anvil_setBalance ${ownerAddress} 10000000000000000000 -r http:\\127.0.0.1:8545`);
    }

    console.log(`\n[ ${chalk.green("Deploying contracts")} ]\n`);
    const upgradeCmd = upgrade(rpcUrl, networkId, ownerAddress, systemAdminAddress, false);
    const result = execute(upgradeCmd);
    const upgradeHash = getUpgradeHash(result);

    console.log(`\n[ ${chalk.green("Scheduling upgrade")} ]\n`);
    const scheduleCommand = schedule({
        rpcUrl,
        networkId,
        upgradeHash,
        systemAdminAddress,
        mnemonicFile: "./nayms_mnemonic.txt",
        mnemonicIndex: 0,
        fork,
        diamondAddress: addresses[networkId],
    });
    execute(scheduleCommand);

    console.log(`\n[ ${chalk.green("Preparing upgrade")} ]\n`);
    const prepCmd = `node ./cli-tools/prep-upgrade.js broadcast/SmartDeploy.s.sol/${networkId}/smartDeploy-latest.json`;
    execute(prepCmd);

    console.log(`\n[ ${chalk.green("Diamond cut")} ]\n`);
    const diamondCutCmd = diamondCut({
        rpcUrl,
        networkId,
        upgradeHash,
        ownerAddress,
        mnemonicFile: "./nayms_mnemonic.txt",
        mnemonicIndex: 19,
    });
    execute(diamondCutCmd);
} else {
    console.log(chalk.red("Supported operations are: 'deploy' and 'upgrade'!"));
    process.exit(1);
}

function getUpgradeHash(result) {
    const hashLine = result
        .split("\n")
        .find((line) => line.includes("upgradeHash: bytes32"))
        .trim()
        .split(" ");
    return hashLine[hashLine.length - 1];
}

function deployDiamondCmd(rpcUrl, networkId, owner, sysAdmin, facetsToCutIn = '"[]"', salt = `0xdeffffffff`) {
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
    --broadcast`;
    }

    return command;
}

function schedule(config) {
    const isFork = config.networkId === "1" && config.fork;
    const impersonateIfNeeded = isFork ? `cast rpc anvil_impersonateAccount ${config.systemAdminAddress} && ` : "";
    const mnemonicIfNeeded = isFork
        ? ""
        : ` \\
        --chain-id ${config.networkId} \\
        --mnemonic ${config.mnemonicFile} \\
        --mnemonic-index ${config.mnemonicIndex}
    `;

    return `${impersonateIfNeeded} cast send ${config.diamondAddress} "createUpgrade(bytes32)" \
        ${config.upgradeHash} \
        --rpc-url ${config.rpcUrl} ${isFork ? "--unlocked" : ""} \
        --from ${config.systemAdminAddress} ${mnemonicIfNeeded}`;
}

function diamondCut(config) {
    return `forge script S03UpgradeDiamond \
        -s "run(address)" ${config.ownerAddress} \
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
    const { execSync } = require("child_process");
    console.log(cmd);

    const result = execSync(cmd).toString();
    console.log("\n\n ------------------ \n\n", result);

    return result;
}
