exports.config = {
  specs: ['./e2e/src/**/*.spec.js'],
  exclude: [],
  maxInstances: 10,
  logLevel: 'info',
  bail: 0,
  waitforTimeout: 10000,
  connectionRetryTimeout: 90000,
  connectionRetryCount: 3,
  framework: 'jasmine',
  reporters: [
    'spec',
    [
      'junit',
      {
        outputDir: './reports/e2e/wdio/junit/'
      }
    ],
    [
      'allure',
      {
        outputDir: './reports/e2e/wdio/allure/',
        disableWebdriverStepsReporting: true,
        disableWebdriverScreenshotsReporting: false
      }
    ]
  ],
  jasmineNodeOpts: {
    defaultTimeoutInterval: 60000
  },
  before: function (capabilities, specs) {
    require('@babel/register')
  },
  afterTest: function (test) {
    if (test.error !== undefined) {
      browser.takeScreenshot()
    }
  }
}
