// Post-coverage cleanup script
const fs = require('fs')
const path = require('path')

const INPUT = path.join(__dirname, '..', 'lcov.info')
const OUTPUT = path.join(__dirname, '..', 'lcov-filtered.info')

const f = fs.readFileSync(INPUT, { encoding: 'utf-8' }).toString()

const lines = []

const exclude = [
  'script/.*',
  'test/.*',
  'src/utils/.*',
  'src/diamonds/shared/libs/.*',
  'src/diamonds/shared/interfaces/.*',
  'src/diamonds/shared/facets/Diamond.*',
]

let record = false
f.split("\n").forEach(l => {
  if (l.startsWith('SF:')) {
    const excluded = exclude.find(e => !!l.match(e))
    if (!excluded) {
      lines.push('TN:')
      record = true
    }
  }

  if (record && l === 'end_of_record') {
    lines.push(l)
    record = false
  }

  if (record) {
    lines.push(l)
  }
})

fs.writeFileSync(OUTPUT, lines.join("\n"), { encoding: 'utf-8' })

console.log(`Wrote filtered LCOV to ${OUTPUT}`)

