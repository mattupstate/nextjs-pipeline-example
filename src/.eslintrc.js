module.exports = {
  'env': {
    'browser': true,
    'es6': true
  },
  'settings': {
    'react': {
      'version': 'detect'
    }
  },
  'extends': [
    'standard',
    'plugin:react/recommended',
    'plugin:security/recommended'
  ],
  'globals': {
    'Atomics': 'readonly',
    'SharedArrayBuffer': 'readonly'
  },
  'parserOptions': {
    'ecmaFeatures': {
      'jsx': true
    },
    'ecmaVersion': 2018,
    'sourceType': 'module'
  },
  'plugins': [
    'react',
    'jest',
    'security'
  ],
  'rules': {
    'react/react-in-jsx-scope': 0
  },
  'overrides': [
    {
      'env': {
        'jest': true
      },
      'files': ['*.test.js']
    }
  ]
}
