# Change Logs

## v0.1.2 (upcoming)

 - upgrade modules


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
