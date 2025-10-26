<-(->it!) _

lc = {files: []}

providers = do
  native: host: \native, config: {route: \/api/uploadr/native}
  imgbb: host: \imgbb, config: {key: "97902907ac92c25e4c54b8d0b4c6eeac"}
  gcs: host: \gcs, config: {
    route: \/api/uploadr/gcs
    bucket: "plotdb-playground-test"
    domain: "https://storage.googleapis.com"
  }

up = new uploadr do
  root: '[ld-scope=uploadr]'
  provider: providers.native

up.on \upload.done, ->
  lc.files ++= it
  ldcv.uploadr.toggle false
  view.render!

ldcv = {}
view = new ldview do
  root: document.body
  init:
    "ldcv-uploadr": ({node}) -> ldcv.uploadr = new ldcover root: node, resident: true
    "ldcv-chooser": ({node}) -> ldcv.chooser = new ldcover root: node, resident: true
  action: click:
    "toggle-uploader": -> ldcv.uploadr.toggle!
    "toggle-chooser": -> ldcv.chooser.toggle!

view = new ldview do
  root: '[ld-scope=file-viewer]'
  handler:
    empty: ({node, ctx}) ~> node.classList.toggle \d-none, !!lc.files.length
    file:
      list: -> (lc.files or [])
      key: -> it.id or it.key
      view: handler: "@": ({node, ctx}) ->
        if /.(jpg|jpeg|png|gif|webp)$/.exec(ctx.name) =>
          node.style.backgroundImage = "url(#{ctx.url})"
        else
          node.textContent = ctx.name

viewer-maker = (root, host) ->
  viewer = new uploadr.viewer do
    root: root
    page:
      host: host
      fetch-on-scroll: true
      limit: 9
      boundary: 100
      fetch: -> new Promise (res, rej) ->
        res [1,2,3,4,5,6,7,8,9].map ->
          {
            url: "/assets/img/sample/#{it}.jpg"
            size: Math.round(Math.random! * (1048576 * 1024))
            name: "DSC_" + "#{Math.floor(Math.random!*10000)}".padStart(4, "0") + ".jpg"
            lastModified: Date.now! - Math.round(Math.random! * 1000 * 1440 * 365)
          }

  viewer.fetch!
  viewer.on \choose, (f) ->
    ldnotify.send \success, """File "#{f.name}" picked."""
    ldcv.chooser.toggle false

viewer-maker '[ld-scope=uploadr-viewer]', chooserroot
viewer-maker '[ld-scope=uploadr-viewer2]', document.body
