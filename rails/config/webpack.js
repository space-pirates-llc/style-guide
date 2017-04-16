const webpack = require("webpack");

module.exports = {
  entrypoints: ['app/frontends/application.js'],

  webpack: {
    plugins: [
      new webpack.optimize.DedupePlugin(),
      new webpack.optimize.AggressiveMergingPlugin(),
      new webpack.optimize.UglifyJsPlugin({
        compress: {
          warnings: false
        },
        sourceMap: true
      })
    ],
    module: {
      loaders: [
        { test: /\.json$/, loader: 'json' },
        {
          test: /\.js$/,
          exclude: /node_modules/,
          loader: 'babel-loader',
          query: {
            presets: ['env']
          }
        }
      ]
    }
  }
};
