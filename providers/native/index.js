(function(){
  uploadr.ext.native = function(arg$){
    var files, progress, opt, data;
    files = arg$.files, progress = arg$.progress, opt = arg$.opt, data = arg$.data;
    return new Promise(function(res, rej){
      var ref$, merge, route, fd, ret, len, _;
      ref$ = opt || {}, merge = ref$.merge, route = ref$.route;
      progress({
        percent: 0,
        val: 0,
        len: len
      });
      if (merge) {
        fd = new FormData();
        files.map(function(it){
          return fd.append('file', it.file);
        });
        if (data != null) {
          fd.append('data', typeof data === 'object' ? JSON.stringify(data) : data);
        }
        return ld$.xhr(route, (ref$ = {
          method: 'POST',
          body: fd
        }, ref$.headers = opt.headers, ref$), {
          type: 'json'
        }).then(res)['catch'](rej);
      } else {
        ret = [];
        len = files.length;
        _ = function(list){
          var item, fd, ref$;
          item = list.splice(0, 1)[0];
          if (!item) {
            return res(ret);
          }
          fd = new FormData();
          fd.append('file', item.file);
          if (data != null) {
            fd.append('data', typeof data === 'object' ? JSON.stringify(data) : data);
          }
          return ld$.xhr(route, (ref$ = {
            method: 'POST',
            body: fd
          }, ref$.headers = opt.headers, ref$), {
            type: 'json',
            progress: function(it){
              return progress((it.item = item, it));
            }
          }).then(function(it){
            var o;
            ret.push(o = it[0]);
            return _(list);
          })['catch'](function(it){
            var o;
            return ret.push(o = {
              name: item.file.name,
              err: it
            });
          });
        };
        return _(files);
      }
    });
  };
}).call(this);
