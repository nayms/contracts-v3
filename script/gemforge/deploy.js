#!/usr/bin/env node

const path = require('path')
const fs = require('fs')
const rootFolder = path.join(__dirname, '..', '..')

const enableCutViaGovernance = async (targetId, cutFile) => {
  const ethers = require('ethers')
  const config = require(path.join(rootFolder, 'gemforge.config.cjs'))
  const deployments = require(path.join(rootFolder, 'gemforge.deployments.json'))
  const cutData = require(cutFile)
  const { abi } = require(path.join(rootFolder, 'forge-artifacts/IDiamondProxy.sol/IDiamondProxy.json'))
  const networkId = config.targets[targetId].network
  const network = config.networks[networkId]
  const walletId = config.targets[targetId].wallet
  const wallet = config.wallets[walletId]

  const proxyAddress = deployments[targetId].contracts.find(a => a.name === 'DiamondProxy').onChain.address

  const provider = new ethers.providers.JsonRpcProvider(network.rpcUrl)
  const signer = ethers.Wallet.fromMnemonic(wallet.config.words, "m/44'/60'/0'/0/1").connect(provider)
  const contract = new ethers.Contract(proxyAddress, abi, signer)

  console.log(`Target: ${targetId}`)
  console.log(`Network: ${networkId} - ${network.rpcUrl}`)
  console.log(`Wallet: ${walletId}`)
  console.log(`System Admin: ${await signer.getAddress()}`)
  console.log(`Proxy: ${proxyAddress}`)

  const upgradeId = await contract.calculateUpgradeId(cutData.cuts, cutData.initContractAddress, cutData.initData)
  console.log(`Upgrade id: ${upgradeId}`)

  const tx = await contract.createUpgrade(upgradeId)
  console.log(`Transaction hash: ${tx.hash}`)
  await tx.wait()
  console.log('Transaction mined!')
}

(async () => {
  const execa = (await import('execa'));
  const $ = execa.$({
    cwd: rootFolder,
    stdio: 'inherit',
    shell: true,
    env: {
      ...process.env,
    }
  })
  
  const targetArg = process.argv[2]
  
  console.log(`Deploying ${targetArg}`)

  if (process.argv[3] == '--fresh') {
    console.log(`Fresh...`)

    await $`yarn gemforge deploy ${targetArg} -n`
  } else {
    console.log(`Upgrade...`)

    const cutFile = path.join(rootFolder, '.gemforge/cut.json')
    if (fs.existsSync(cutFile)) {
      fs.unlinkSync(cutFile)
    }

    await $`yarn gemforge deploy ${targetArg} --pause-cut-to-file ${cutFile}`

    if (!fs.existsSync(cutFile)) {
      console.log(`Nothing to upgrade!`)
    } else {
      console.log(`Enabling cut via governance for ${targetArg}...`)

      await enableCutViaGovernance(targetArg, cutFile)

      console.log(`Resuming deployment for ${targetArg}...`)

      await $`yarn gemforge deploy ${targetArg} --resume-cut-from-file ${cutFile}`
    }
  }

  console.log(`Done!`)
})()  


