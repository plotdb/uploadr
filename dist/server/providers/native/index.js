(function(){
  var fs, fsExtra, path, crypto, imgtype, providerNative;
  fs = require('fs');
  fsExtra = require('fs-extra');
  path = require('path');
  crypto = require('crypto');
  imgtype = require('imgtype');
  providerNative = function(opt){
    opt == null && (opt = {});
    this.opt = opt;
    this.config = opt.config || {};
    this.adopt = opt.adopt || {
      upload: function(){
        return Promise.resolve();
      },
      download: function(){
        return Promise.resolve();
      }
    };
    this.folder = this.config.folder || 'uploads';
    this.rooturl = this.config.url || this.folder;
    this.log = opt.log || function(it){
      return console.log(it);
    };
    this['catch'] = opt['catch'] || null;
    return this;
  };
  providerNative.prototype = import$(Object.create(Object.prototype), {
    /**
     * save upload files in local directory.
     * @param {Object} obj - information of the file to save, in `{buf, name}` or `{path, name, target}` format:
         - `path`: file path ( full path, including filename )
         - `name`: name for the file ( in remote system ). optional
         - `buf`: file content, as a Buffer objcet. `path` is omitted if `buf` is given.
         - `target`: concetp for either purpose, category. put in specific subfolder. default `main`.
     * @return {Promise} - resolving `{name,url,id}` if succeed, otherwise `{name}` only.
         - `name`: name for the file
         - `url`: url of the file from which we can access it
         - `id`: unique id for this file
     */
    archive: function(obj){
      var this$ = this;
      obj == null && (obj = {});
      return new Promise(function(res, rej){
        var ref$, name, target, promise;
        ref$ = [obj.name || '', obj.target || 'main'], name = ref$[0], target = ref$[1];
        promise = obj.buf
          ? Promise.resolve(obj.buf)
          : new Promise(function(res, rej){
            return fs.readFile(obj.path, function(e, buf){
              if (e) {
                return rej(e);
              } else {
                return res(buf);
              }
            });
          });
        return promise.then(function(buf){
          var hk, t1, t2, dir;
          hk = crypto.createHash('sha256').update(buf).digest('hex') + "-" + buf.length.toString(36);
          t1 = hk.substring(0, 5);
          t2 = hk.substring(5, 10);
          hk = hk.substring(10);
          dir = path.join(this$.folder, target, t1, t2);
          return imgtype(buf).then(function(arg$){
            var ext, des, url, ref$;
            ext = arg$.ext;
            des = path.join(dir, hk);
            url = path.join(this$.rooturl, target, t1, t2, hk);
            if (ext) {
              ref$ = [des + "." + ext, url + "." + ext], des = ref$[0], url = ref$[1];
            }
            return fs.exists(des, function(it){
              if (it) {
                res({
                  url: url,
                  name: name,
                  id: hk
                });
              }
              return fsExtra.ensureDir(dir, function(e, b){
                if (e) {
                  throw e;
                }
                return fs.writeFile(des, buf, function(e, b){
                  if (e) {
                    throw e;
                  }
                  return res({
                    path: des,
                    url: url,
                    name: name,
                    id: hk
                  });
                });
              });
            });
          });
        })['catch'](function(err){
          this$.log(err);
          return res({
            name: name
          });
        });
      });
    }
    /**
     * accept req.files and req.fields to save files.
       User should use express-formidable to prepare those fields and multipart parsing.
       for example:
           app.post \/d/uploadr/native, express-formidable({multiples:true}), new uploadr.native!get-router!
     * @param {Request} req - express request object
     * @param {Response} res - express response object
     * @param {Function} next - express next function.
     * @return {Promise}
     */,
    router: function(req, res, next){
      var this$ = this;
      return this.handler({
        opt: {},
        req: req,
        res: res
      }).then(function(it){
        return res.send(it);
      })['catch'](function(err){
        if (this$['catch']) {
          return this$['catch'](err, req, res, next);
        } else {
          this$.log(err);
          return res.status(500).send();
        }
      });
    }
    /**
      * internal function to handle requests. 
      */,
    handler: function(o){
      var req, res, cfg, files, this$ = this;
      o == null && (o = {});
      req = o.req, res = o.res;
      cfg = o.opt || {};
      files = (req.files || {}).file;
      files = !files
        ? []
        : Array.isArray(files)
          ? files
          : [files];
      if (cfg && cfg.target) {
        files = files.map(function(it){
          return it.target = cfg.target, it;
        });
      }
      return Promise.all(files.map(function(it){
        return this$.archive(it).then(function(ret){
          return this$.adopt.upload(req, ret).then(function(){
            return ret;
          });
        });
      }));
    },
    getUploadRouter: function(){
      var this$ = this;
      return function(req, res, next){
        return this$.router(req, res, next);
      };
    }
  });
  module.exports = providerNative;
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
