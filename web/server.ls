require! <[fs express path @plotdb/colors @plotdb/srcbuild express-formidable open]>
#uploadr = require "../src/server.ls"
dir = path.join(fs.realpathSync(__dirname))

uploadr-gcs = require path.join(dir, "../src/providers/gcs/server.ls")
uploadr-native = require path.join(dir, "../src/providers/native/server.ls")

backend = do
  init: (opt) ->
    @app = app = express!

    app.set 'view engine', \pug
    app.use \/, express.static path.join(dir, \static)
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
      open "http://localhost:#{server.address!port}"
      process.chdir dir
      srcbuild.lsp {base: '.'}

config = JSON.parse(fs.read-file-sync path.join(dir, 'config.json') .toString!)

backend.init config
