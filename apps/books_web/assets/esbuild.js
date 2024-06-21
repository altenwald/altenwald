import esbuild from 'esbuild'
import babel from 'esbuild-plugin-babel'
import {sassPlugin} from 'esbuild-sass-plugin'

// Decide which mode to proceed with
let mode = 'build'
let base_opts = {}
process.argv.slice(2).forEach((arg) => {
  if (arg === '--watch') {
    mode = 'watch'
    base_opts = {
      watch: true,
      sourcemap: 'inline'
    }
  } else if (arg === '--deploy') {
    mode = 'deploy'
    base_opts = {
      minify: true
    }
  }
})

// Define esbuild options + extras for watch and deploy
let opts = {
  entryPoints: [
    'js/app.js',
    'js/admin.js',
    'css/app.scss',
    'css/admin.scss',
    'css/stripe.scss'
  ],
  bundle: true,
  logLevel: 'info',
  // target: 'es2016',
  platform: "node",
  outdir: '../priv/static/assets',
  plugins: [sassPlugin(), babel({
    filter: /js$/,
    namespace: '',
    config: {
      sourceMaps: "inline",
      presets: []
    } // babel config here or in babel.config.json
  })],
  // splitting: true,
  format: "esm",
  loader: {
    '.ttf': 'file',
    '.png': 'file',
    '.eot': 'file',
    '.svg': 'file',
    '.woff': 'file',
    '.woff2': 'file',
  },
  ... base_opts
}

// Start esbuild with previously defined options
// Stop the watcher when STDIN gets closed (no zombies please!)
esbuild.build(opts).then((result) => {
  if (mode === 'watch') {
    process.stdin.pipe(process.stdout)
    process.stdin.on('end', () => { result.stop() })
  }
}).catch((error) => {
  process.exit(1)
})
