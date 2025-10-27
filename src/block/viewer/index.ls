module.exports =
  pkg:
    dependencies: [
    * name: "@plotdb/uploadr"
    * name: "@plotdb/uploadr", type: \css
    ]
  interface: -> @up
  init: ({root, data}) ->
    pagecfg = data?page or {}
    base = root.querySelector('[ld-scope]')
    pagecfg.host = base
    @up = new uploadr.viewer root: base, page: pagecfg
