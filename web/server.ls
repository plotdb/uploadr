require! <[fs express path colors template express-formidable]>
uploadr = require "../src/server.ls"

backend = do
  init: (opt) ->
    @app = app = express!

    app.set 'view engine', \pug
    app.use \/, express.static \static
    if opt.api => opt.api @
    console.log "[Server] Express Initialized in #{app.get \env} Mode".green

    cfg = do
      uploadr: {folder: 'static/assets/files', url: '/assets/files'}
      formidable: {multiples: true}
    app.post \/d/uploadr, express-formidable(cfg.formidable), uploadr(cfg.uploadr).route

    # server from sharedb http server or express
    server = app.listen opt.port, ->
      delta = if opt.start-time => "( takes #{Date.now! - opt.start-time}ms )" else ''
      console.log "[SERVER] listening on port #{server.address!port} #delta".cyan

config = JSON.parse(fs.read-file-sync 'config.json' .toString!)

backend.init config
template.watch.init config
