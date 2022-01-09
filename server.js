const { hostname } = require('os')
const http = require('http')

const MESSAGE = `Hello World from ${hostname()}\n`
const PORT = 8080

const server = http.createServer((req, res) => {
  res.statusCode = 200
  res.setHeader('Content-Type', 'text/plain')
  res.end(MESSAGE)
})

server.listen(PORT, hostname, () => {
  console.log(`Server running at http://${hostname()}:${PORT}`)
})

