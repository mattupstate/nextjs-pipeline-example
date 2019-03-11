module.exports = {
  setupFiles: ['<rootDir>/jest.setup.js'],
  collectCoverage: true,
  coverageDirectory: '../coverage',
  testPathIgnorePatterns: [
    '.next/'
  ]
}
