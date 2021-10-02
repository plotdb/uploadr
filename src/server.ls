require! <[fs path]>
lib = path.dirname fs.realpathSync __filename

uploadr =
  provider: (opt) ->
    provider = require("../providers/#{opt.host}")
    new provider {config: opt.config}

module.exports = uploadr
