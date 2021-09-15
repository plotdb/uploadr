<-(->it!) _

lc = {files: []}

providers = do
  native: host: \native, config: {route: \/d/uploadr}
  imgbb: host: \imgbb, config: {key: "97902907ac92c25e4c54b8d0b4c6eeac"}
  gcs: host: \gcs, config: {
    route: \/d/uploadr/gcs
    bucket: "plotdb-playground-test"
    domain: "https://storage.googleapis.com"
  }

up = new uploadr do
  root: '[ld-scope=uploadr]'
  provider: providers.gcs

up.on \upload.done, ->
  lc.files ++= it
  ldcv.uploadr.toggle false
  view.render!

ldcv = {}
view = new ldview do
  root: document.body
  init:
    "ldcv-uploadr": ({node}) -> ldcv.uploadr = new ldcover root: node
    "ldcv-chooser": ({node}) -> ldcv.chooser = new ldcover root: node
  action: click:
    "toggle-uploader": -> ldcv.uploadr.toggle!
    "toggle-chooser": -> ldcv.chooser.toggle!

view = new ldview do
  root: '[ld-scope=photo-viewer]'
  handler: do
    photo: do
      list: -> lc.files or []
      handle: ({node, data}) ->
        node.style.backgroundImage = "url(#{data.url})"

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
          {url: "/assets/img/sample/#{it}.jpg"}
  viewer.fetch!
  viewer.on \choose, ->
    ldnotify.send \success, """File "#{it.url}" picked."""
    ldcv.chooser.toggle false

viewer-maker '[ld-scope=uploadr-viewer]', chooserroot
viewer-maker '[ld-scope=uploadr-viewer2]', window
