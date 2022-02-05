require! <[fs path]>
lib = path.dirname fs.realpathSync __filename

uploadr =
  provider: (opt) ->
    provider = require(path.join(lib, "providers", opt.host))
    new provider opt

module.exports = uploadr
