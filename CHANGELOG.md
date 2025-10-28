# Change Logs

## v0.5.0

 - breaking changes
   - rewrite widget code
     - tweak style
     - tweak DOM structure
     - tweak APIs and Events
   - tweak uploadr object structure:
     - Use `uploadr.viewer` and `uploadr.uploader` for widgets, `uploadr.ext` for providers.
 - rewrite all demostration page
 - update document
 - add block-based widgegt
 - support file extension limitation
 - add loader in viewer
 - support thumb placeholder for non-image files
 - i18n support
 - native provider: check and fallback file ext used


## v0.4.5

 - fix issue: `index.pug` isn't found when accessing via `@plotdb/uploadr/index.pug`. move it to server.


## v0.4.4

 - rename `publish` script to `release`


## v0.4.3

 - update publish script


## v0.4.2

 - remove publish script


## v0.4.1

 - add exports path for server-side providers


## v0.4.0

 - put provider js files into separated path
 - use `exports` to implement server / client code separation


## v0.3.0

 - migrate from `ldpage` to `@loadingio/paginate`, leading to breaking changes.
 - support attributes in client pug mixin
 - support file-based file uploading instead of image-based uploading
 - add i18n data


## v0.2.2

 - toggle loader only if loader exists.
 - tweak server provider syntax for require


## v0.2.1

 - fix bug: server inclusion path incorrect, leading provider creation failure
 - upgrade modules


## v0.2.0

 - source and dist file renamed.
 - wrap client js with transpiler instead of doing it ourselves
 - upgrade modules
 - release with compact directory structure
 - add `style` in `package.json`
 - add `main` and `browser` field in `package.json`.
 - further minimize generated js file with mangling and compression
 - patch test code to make it work with upgraded modules


## v0.1.3

 - support additional data passed to server when uploading
 - add limit on upload file amount for GCS provider


## v0.1.2

 - upgrade modules
 - fix bug: @log instead of log in native server provider
 - fix bug: incorrect parentheses for Promise.all in native server provider
 - fix bug: should passin full opt object to provider in server entry point `dist/server.js`
 - tweak gcs provider option to better align spec.


## v0.1.1

 - add missing server file


## v0.1.0

 - server
   - use `SHA256` + file size instead of `md5` to lower chance of file name collision.
   - add `log` option
   - make `target` default `main` if not specified
   - log error if occurred
 - build
   - upgrade modules and remove runtime warnings: `stylus`
   - add missing dev modules: `colors`, `express`, `fs-extra`
   - use npx to replace relative path to execute commadns
   - let dev server accesss `src/server.ls` instead of copying it to `web/api` folder.
   - use `assets/lib/uploadr/dev/` instead of `assets/lib/uploadr`
 - remove useless options and codes
 - re-write `uploadr` and `uploadr-viewer` module
 - use `view` directive instead of `handler` to prevent duplicate `ldview` object creation
 - support `loader` directly with `ldloader`
 - better README 
 - tweak demo page
 - merge client side `uploadr.viewer` and `uploadr` script.
 - image fade in
 - unify ld naming for `uploadr` and `uploadr.viewer`
 - add additional events in `uploadr.viewer`
 - add APIs to control ldPage in `uploadr.viewer`.
 - add chooser demo
 - reorg src and dist directory.
 - add gcs provider
