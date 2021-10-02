// Generated by LiveScript 1.6.0
var fs, path, lib, uploadr;
fs = require('fs');
path = require('path');
lib = path.dirname(fs.realpathSync(__filename));
uploadr = {
  provider: function(opt){
    var provider;
    provider = require("../providers/" + opt.host);
    return new provider({
      config: opt.config
    });
  }
};
module.exports = uploadr;
