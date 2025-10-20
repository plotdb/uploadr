(function(){
  uploadr.ext.imgbb = function(arg$){
    var files, progress, opt;
    files = arg$.files, progress = arg$.progress, opt = arg$.opt;
    return new Promise(function(res, rej){
      var ret, len, _;
      ret = [];
      len = files.length;
      progress({
        percent: 0,
        val: 0,
        len: len
      });
      _ = function(list){
        var item, fd;
        item = list.splice(0, 1)[0];
        if (!item) {
          return res(ret);
        }
        fd = new FormData();
        fd.append('image', item.file);
        return ld$.xhr("https://api.imgbb.com/1/upload?key=" + opt.key, {
          method: 'POST',
          body: fd
        }, {
          type: 'json'
        }).then(function(it){
          var o;
          if (!(it && it.data && it.status === 200)) {
            return Promise.reject(it);
          }
          ret.push(o = {
            url: it.data.display_url,
            name: item.file.name,
            id: it.data.id,
            raw: it.data
          });
          progress({
            percent: (len - list.length) / len,
            val: len - list.length,
            len: len,
            item: o
          });
          return _(list);
        })['catch'](function(it){
          var o;
          ret.push(o = {
            name: item.file.name,
            err: it
          });
          return progress({
            percent: (len - list.length) / len,
            val: len - list.length,
            len: len,
            item: o
          });
        });
      };
      return _(files);
    });
  };
}).call(this);
