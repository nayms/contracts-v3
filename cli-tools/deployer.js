const { Wallet } = require("ethers");
const fs = require("fs");
const chalk = require("chalk");
const dotenv = require("dotenv");
const { Readable } = require("stream");

dotenv.config();

if (process.argv.length != 4) {
    console.error(chalk.red(`Must provide deployment operation and target network!`));
    process.exit(1);
}

const [op, networkId] = process.argv.slice(2);

const rpcUrl = process.env[`ETH_${networkId}_RPC_URL`];
const mnemonic = fs.readFileSync("nayms_mnemonic.txt").toString();

const ownerAddress = Wallet.fromMnemonic(mnemonic, `m/44'/60'/0'/0/19`).address;
const systemAdminAddress = Wallet.fromMnemonic(mnemonic, `m/44'/60'/0'/0/0`).address;

if (op === "deploy") {
    console.log(`[ ${chalk.green(networkId)} ] Deploying new diamond`);

    const deployNewDiamondCmd = deployDiamondCmd(rpcUrl, networkId, ownerAddress, systemAdminAddress);
    execute(deployNewDiamondCmd);

    const initSimCmd = upgradeInit(rpcUrl, networkId, ownerAddress, systemAdminAddress, false);
    const result = execute(initSimCmd);
    const hashLine = result
        .split("\n")
        .find((line) => line.includes("Upgrade is not scheduled for this hash"))
        .trim()
        .split(" ");
    const upgradeHash = hashLine[hashLine.length - 1];

    const scheduleCommand = schedule({
        rpcUrl,
        networkId,
        upgradeHash,
        systemAdminAddress,
        mnemonicFile: "./nayms_mnemonic.txt",
        mnemonicIndex: 0,
    });
    execute(scheduleCommand);

    const initCmd = upgradeInit(rpcUrl, networkId, ownerAddress, systemAdminAddress);
    execute(initCmd);
} else if (op === "upgrade") {
    const addressesRaw = fs.readFileSync("deployedAddresses.json");
    const addresses = JSON.parse(addressesRaw);

    console.log(`[ ${chalk.green(networkId)} ] upgrade => ${chalk.greenBright(addresses[networkId])}`);
} else {
    console.log(chalk.red("Supported operations are: 'deploy' and 'upgrade'!"));
    process.exit(1);
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

function upgradeInit(rpcUrl, networkId, owner, sysAdmin, broadcast = true, facetsToCutIn = '"[]"', salt = `0xdeffffffff`) {
    return smartDeploy({
        rpcUrl,
        networkId,
        newDeploy: false,
        owner,
        sysAdmin,
        initDiamond: true,
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
    return `forge script SmartDeploy \\
        -s "schedule(bytes32)" ${config.upgradeHash} \\
        -f ${config.rpcUrl} \\
        --chain-id ${config.networkId} \\
        --sender ${config.systemAdminAddress} \\
        --mnemonic-paths ${config.mnemonicFile} \\
        --mnemonic-indexes ${config.mnemonicIndex} \\
        -vv \\
        --ffi \\
        --broadcast
    `;
}

function execute(cmd) {
    const { execSync } = require("child_process");
    console.log("\n ==  Executing ==\n\n", cmd);

    const result = execSync(cmd).toString();
    console.log("\n == Result ==\n\n", result);

    return result;
}
