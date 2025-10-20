(function(){
  uploadr.ext.gcs = function(arg$){
    var files, progress, opt, data;
    files = arg$.files, progress = arg$.progress, opt = arg$.opt, data = arg$.data;
    return new Promise(function(res, rej){
      var ret, len, domain, fd;
      ret = [];
      len = files.length;
      domain = opt.domain || "https://storage.googleapis.com";
      fd = new FormData();
      fd.append('count', files.length);
      if (data != null) {
        fd.append('data', typeof data === 'object' ? JSON.stringify(data) : data);
      }
      return ld$.fetch(opt.route, {
        method: 'POST',
        body: fd
      }, {
        type: 'json'
      }).then(function(tokens){
        return Promise.all(files.map(function(item, i){
          var ref$, signedUrl, id;
          ref$ = tokens[i], signedUrl = ref$.signedUrl, id = ref$.id;
          return ld$.xhr(signedUrl, {
            method: 'PUT',
            body: item.file,
            headers: {
              "Content-Type": item.file.type
            }
          }, {
            noDefaultHeaders: true,
            progress: function(it){
              return progress({
                percent: it.percent,
                item: item
              });
            }
          }).then(function(){
            return {
              name: item.file.name,
              id: id,
              url: domain + "/" + opt.bucket + "/" + id
            };
          })['catch'](function(it){
            return {
              name: item.file.name,
              err: it
            };
          });
        }));
      }).then(function(it){
        return res(it);
      })['catch'](function(it){
        return rej(it);
      });
    });
  };
}).call(this);
