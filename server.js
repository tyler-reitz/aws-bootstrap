const { hostname } = require('os')
const http = require('http')
const STACK_NAME = process.env.STACK_NAME || "Unknown Stack"

const MESSAGE = `Hello World from ${hostname()}\n in ${STACK_NAME}\n`
const PORT = 8080

const server = http.createServer((req, res) => {
  res.statusCode = 200
  res.setHeader('Content-Type', 'text/plain')
  res.end(MESSAGE)
})

server.listen(PORT, hostname, () => {
  console.log(`Server running at http://${hostname()}:${PORT}`)
})

