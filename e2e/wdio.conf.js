const { createServer } = require('http')
const next = require('next')
const { config } = require('./wdio.shared.conf')

/*
Manage a Next.js server programatically so it can be started and stopped as
part of the end-to-end test suite lifecycle when developing locally.
*/
const app = next({ dir: './src' })
const server = createServer(app.getRequestHandler())

config.runner = 'local'
config.baseUrl = 'http://localhost:3000/'
config.services = ['selenium-standalone']
config.capabilities = [
  {
    maxInstances: 1,
    browserName: 'chrome'
  }
]

config.onPrepare = function (config, capabilities) {
  return app.prepare().then(() => {
    server.listen(3000)
  })
}

config.onComplete = function (exitCode, config, capabilities, results) {
  server.close()
}

exports.config = config
