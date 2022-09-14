const fs = require('fs')

const artifactsPath = './forge-artifacts'
const sourcePaths = [
  './src/diamonds/nayms/interfaces',
  './src/diamonds/nayms/libs'
]

let abi = []

const inlineABIs = (sourcePath) => {
  let files = fs.readdirSync(sourcePath)
  for (const file of files) {
    const jsonFile = file.replace('sol', 'json')
    let json = fs.readFileSync(`${artifactsPath}/${file}/${jsonFile}`)
    json = JSON.parse(json)
    abi.push(...json.abi)
  }
}

sourcePaths.forEach(p => inlineABIs(p))

fs.writeFileSync('./NaymsDiamond.json', JSON.stringify(abi))
console.log('ABI written to ./NaymsDiamond.json')
