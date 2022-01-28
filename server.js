const { hostname } = require('os')
const http = require('http')
const https = require('https')
const fs = require('fs')

const STACK_NAME = process.env.STACK_NAME || "Unknown Stack"
const PORT = 8080
const HTTPSPORT = 8443
const httpsKey = '../keys/key.pem'
const httpsCert = '../keys/cert.pem'

if (fs.existsSync(httpsKey) && fs.existsSync(httpsCert)) {
  console.log('Starting https server')
  const MESSAGE = `Hello HTTPS World from ${hostname()}\n in ${STACK_NAME}\n`
  const options = { key: fs.readFileSync(httpsKey), cert: fs.readFileSync(httpsCert) }
  const server = https.createServer(options, (req, res) => {
    res.statusCode = 200
    res.setHeader('Content-Type', 'text/plain')
    res.end(MESSAGE)
  })

  server.listen(HTTPSPORT, hostname, () => {
    console.log(`Server running at https://${hostname()}:${PORT}`)
  })
} else {
  console.log('Could not find certificate/key')
}
