var path = require('path')

module.exports = {
  entry: path.resolve(__dirname, 'examples', 'simpleServer.js'),

  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'simpleServer.js'
  },

  target: 'node',

  resolve: {
    modules: [
      path.join(__dirname, 'src'),
      path.join(__dirname, 'examples'),
      'node_modules'
    ],
    extensions: ['.js', '.elm']
  },

  module: {
    rules: [{
      test: /\.elm$/,
      exclude: [/elm-stuff/, /node_modules/],
      use: {
        loader: 'elm-webpack-loader',
        options: {
          debug: true,
          warn: true
        }
      }
    }]
  }
};
