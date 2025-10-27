module.exports =
  pkg:
    dependencies: [
    * name: "@plotdb/uploadr"
    * name: "@plotdb/uploadr", type: \css
    ]
  interface: -> @up
  init: ({root, data}) ->
    base = root.querySelector('[ld-scope]')
    @up = new uploadr.uploader root: base, provider: (data?provider or {})
