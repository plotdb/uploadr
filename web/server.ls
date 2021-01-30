require! <[fs express path colors template express-formidable]>
#uploadr = require "../src/server.ls"
uploadr-gcs = require "../src/providers/gcs.ls"
uploadr-native = require "../src/providers/native.ls"

backend = do
  init: (opt) ->
    @app = app = express!

    app.set 'view engine', \pug
    app.use \/, express.static \static
    if opt.api => opt.api @
    console.log "[Server] Express Initialized in #{app.get \env} Mode".green

    cfg = do
      uploadr: 
        gcs: do
          projectId: \playground
          keyFilename: \key/playground.json
          bucket: \plotdb-playground-test
        native: do
          folder: 'static/assets/files'
          url: '/assets/files'
      formidable: {multiples: true}
    up-gcs = new uploadr-gcs {config: cfg.uploadr.gcs}
    up-native = new uploadr-native {config: cfg.uploadr.native}
    app.post \/api/uploadr/gcs, express-formidable(cfg.formidable), up-gcs.get-upload-router!
    app.post \/api/uploadr/native, express-formidable(cfg.formidable), up-native.get-upload-router!

    # server from sharedb http server or express
    server = app.listen opt.port, ->
      delta = if opt.start-time => "( takes #{Date.now! - opt.start-time}ms )" else ''
      console.log "[SERVER] listening on port #{server.address!port} #delta".cyan

config = JSON.parse(fs.read-file-sync 'config.json' .toString!)

backend.init config
template.watch.init config
