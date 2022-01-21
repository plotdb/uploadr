(function(){
  var suuid, storage, retry, providerGcs;
  suuid = require('@plotdb/suuid');
  storage = require('@google-cloud/storage');
  retry = function(count, cb){
    return cb()['catch'](function(it){
      if (count > 0) {
        return retry(count - 1, cb);
      } else {
        return Promise.reject(it);
      }
    });
  };
  providerGcs = function(opt){
    var ref$;
    opt == null && (opt = {});
    this.opt = import$({}, opt);
    this.config = opt.config || {};
    this.adopt = opt.adopt || {
      upload: function(){
        return Promise.resolve();
      },
      download: function(){
        return Promise.resolve();
      }
    };
    this.bucket = this.config.bucket;
    this.gcs = new storage.Storage({
      bucket: (ref$ = this.config).bucket,
      projectId: ref$.projectId,
      keyFilename: ref$.keyFilename
    });
    return this;
  };
  providerGcs.prototype = import$(Object.create(Object.prototype), {
    /**
      * get a link to upload file.
      * @param {String} id - optional. unique id for this file
          - use a randomly generated suuid if omitted
          - overwrite the old file if id was used before.
      * @param {String} name - optional. 
      * @return {Promise} - resolve url for uploading
      */
    upload: function(req, opt){
      var ref$, name, id, this$ = this;
      opt == null && (opt = {});
      ref$ = [opt.name || 'unnamed', opt.id], name = ref$[0], id = ref$[1];
      return Promise.resolve().then(function(){
        if (!id) {
          return retry(10, function(){
            var id;
            return this$.adopt.upload(req, {
              name: name,
              id: id = suuid()
            }).then(function(){
              return {
                name: name,
                id: id
              };
            });
          });
        } else {
          return this$.adopt.upload(req, {
            name: name,
            id: id
          }).then(function(){
            return {
              name: name,
              id: id
            };
          });
        }
      }).then(function(arg$){
        var id;
        id = arg$.id;
        return this$.getUrl({
          id: id,
          action: 'write'
        }).then(function(signedUrl){
          return {
            id: id,
            signedUrl: signedUrl
          };
        });
      });
    }
    /**
      * get download link for a file corresponding to a given id
      * @param {Object} obj - {id, expires}
          - `id`: file id. this id is generated when upload.
          - `expires`: unix eopch time to expire this link after generated.
      * @return {Promise} - resolve url for downloading
      */,
    download: function(req, opt){
      var ref$;
      opt == null && (opt = {});
      this.adopt.download(req, {
        id: opt.id
      });
      return this.getUrl((ref$ = {
        action: 'read'
      }, ref$.id = opt.id, ref$.expires = opt.expires, ref$)).then(function(signedUrl){
        return {
          signedUrl: signedUrl,
          id: id
        };
      });
    }
    /**
      * internal api
      */,
    getUrl: function(opt){
      var payload;
      opt == null && (opt = {});
      if (!opt.id) {
        return Promise.reject();
      }
      payload = import$({
        expires: Date.now() + 2 * 60 * 1000,
        action: 'read',
        version: 'v4'
      }, opt);
      return this.gcs.bucket(this.bucket).file(opt.id).getSignedUrl({
        expires: payload.expires,
        action: payload.action,
        version: payload.version
      }).then(function(it){
        return it[0];
      });
    },
    getUploadRouter: function(){
      var this$ = this;
      return function(req, res, next){
        var count, ref$;
        if (isNaN(count = +(req.fields || (req.fields = {})).count || 1)) {
          count = 1;
        }
        count <= (ref$ = this$.config.limit || 10) || (count = ref$);
        return Promise.all((function(){
          var i$, to$, results$ = [];
          for (i$ = 0, to$ = count; i$ < to$; ++i$) {
            results$.push(i$);
          }
          return results$;
        }()).map(function(){
          return this$.upload(req, {});
        })).then(function(it){
          return res.send(it);
        });
      };
    },
    getDownloadRouter: function(){
      var this$ = this;
      return function(req, res, next){
        return this$.download(req, {}).then(function(it){
          return res.status(302).redirect(it.signedUrl);
        });
      };
    }
  });
  module.exports = providerGcs;
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
