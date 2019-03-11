const { config } = require('./wdio.shared.conf')

config.hostname = 'hub'
config.path = '/wd/hub'
config.port = 4444
config.baseUrl = 'http://webapp/'

config.capabilities = [
  {
    maxInstances: 1,
    browserName: 'firefox'
  },
  {
    maxInstances: 1,
    browserName: 'chrome'
  }
]

exports.config = config
