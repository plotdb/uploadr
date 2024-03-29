(function(){
  var xhr, uploadr, ext;
  xhr = function(url, o, opt){
    o == null && (o = {});
    opt == null && (opt = {});
    return new Promise(function(res, rej){
      var x;
      x = new XMLHttpRequest();
      x.onreadystatechange = function(){
        var ret, e;
        if (x.readyState === XMLHttpRequest.DONE) {
          if (x.status === 200) {
            try {
              ret = opt.type === 'json'
                ? JSON.parse(x.responseText)
                : x.responseText;
            } catch (e$) {
              e = e$;
              return rej(new Error(e));
            }
            return res(ret);
          } else {
            return rej(new Error());
          }
        }
      };
      x.onloadstart = function(){
        return opt.progress({
          percent: 0,
          val: 0,
          len: 0
        });
      };
      if (opt.progress) {
        x.onprogress = function(evt){
          var ref$, val, len;
          ref$ = [evt.loaded, evt.total], val = ref$[0], len = ref$[1];
          return opt.progress({
            percent: val / len,
            val: val,
            len: len
          });
        };
      }
      x.open(o.method || 'GET', url, true);
      return x.send(o.body);
    });
  };
  uploadr = function(opt){
    var this$ = this;
    opt == null && (opt = {});
    this.root = typeof opt.root === 'string'
      ? document.querySelector(opt.root)
      : opt.root;
    this.evtHandler = {};
    this.opt = opt;
    this.ucfg = opt.uploader || {
      route: '/d/uploadr',
      host: 'native'
    };
    this.progress = function(v){
      var n, p;
      if (!(n = (v.item || (v.item = {})).node)) {
        return;
      }
      if (!(p = ld$.find(n, '[ld=progress]')[0])) {
        return;
      }
      p.style.width = v.percent * 100 + "%";
      if (v.percent >= 1) {
        return debounce(500).then(function(){
          var i;
          ld$.remove(n);
          if (~(i = this$.lc.files.indexOf(v.item))) {
            return this$.lc.files.splice(i, 1);
          }
        });
      }
    };
    this.lc = {
      files: []
    };
    this.init();
    return this;
  };
  uploadr.prototype = import$(Object.create(Object.prototype), {
    on: function(n, cb){
      var ref$;
      return ((ref$ = this.evtHandler)[n] || (ref$[n] = [])).push(cb);
    },
    fire: function(n){
      var v, res$, i$, to$, ref$, len$, cb, results$ = [];
      res$ = [];
      for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
        res$.push(arguments[i$]);
      }
      v = res$;
      for (i$ = 0, len$ = (ref$ = this.evtHandler[n] || []).length; i$ < len$; ++i$) {
        cb = ref$[i$];
        results$.push(cb.apply(this, v));
      }
      return results$;
    },
    init: function(){
      var lc, view, this$ = this;
      lc = this.lc;
      return this.lc.view = view = new ldView({
        root: this.root,
        action: {
          click: {
            upload: function(arg$){
              var node, evt;
              node = arg$.node, evt = arg$.evt;
              return this$.upload().then(function(it){
                this$.clear();
                return it;
              });
            },
            clear: function(arg$){
              var node, evt;
              node = arg$.node, evt = arg$.evt;
              return this$.clear();
            }
          },
          drop: {
            drop: function(arg$){
              var node, evt, promises;
              node = arg$.node, evt = arg$.evt;
              evt.preventDefault();
              promises = Array.from(evt.dataTransfer.files).map(function(it){
                return ldFile.fromFile(it, 'dataurl', 'utf-8');
              });
              return Promise.all(promises).then(function(it){
                lc.files = it;
                view.render();
                return this$.upload().then(function(it){
                  this$.clear();
                  return it;
                });
              });
            }
          },
          dragover: {
            drop: function(arg$){
              var node, evt;
              node = arg$.node, evt = arg$.evt;
              return evt.preventDefault();
            }
          }
        },
        init: {
          input: function(arg$){
            var node, ldf;
            node = arg$.node;
            lc.ldf = ldf = new ldFile({
              root: node,
              type: 'dataurl',
              forceEncoding: 'utf-8'
            });
            node.addEventListener('change', function(){
              return this$.fire('preview.loading');
            });
            return ldf.on('load', function(files){
              var preview, promises;
              preview = view.get('preview');
              promises = files.map(function(file){
                return new Promise(function(res, rej){
                  var img;
                  img = new Image;
                  img.onload = function(){
                    var x$, ref$;
                    if (preview) {
                      x$ = preview.style;
                      x$.backgroundImage = "url(" + files[0].result + ")";
                      x$.width = img.width + "px";
                      x$.height = img.height + "px";
                    }
                    return res(import$((ref$ = {}, ref$.width = img.width, ref$.height = img.height, ref$), file));
                  };
                  return img.src = file.result;
                });
              });
              return Promise.all(promises).then(function(){
                lc.files = files;
                return debounce(500);
              }).then(function(){
                view.render();
                return this$.fire('preview.done');
              });
            });
          }
        },
        handler: {
          file: {
            list: function(){
              return lc.files || [];
            },
            handle: function(arg$){
              var node, data, view;
              node = arg$.node, data = arg$.data;
              data.node = node;
              return view = new ldView({
                root: node,
                action: {
                  click: {
                    'delete': function(){
                      var idx;
                      node.parentNode.removeChild(node);
                      idx = lc.files.indexOf(data);
                      if (idx >= 0) {
                        return lc.files.splice(idx, 1);
                      }
                    }
                  }
                },
                handler: {
                  name: function(arg$){
                    var node;
                    node = arg$.node;
                    return node.textContent = data.file.name;
                  },
                  size: function(arg$){
                    var node;
                    node = arg$.node;
                    return node.textContent = Math.round(data.file.size / 1024) + "KB";
                  },
                  thumb: function(arg$){
                    var node;
                    node = arg$.node;
                    return node.style.backgroundImage = "url(" + data.result + ")";
                  }
                }
              });
            }
          }
        }
      });
    },
    get: function(){
      return this.lc.files;
    },
    clear: function(){
      this.lc.files.splice(0);
      return this.lc.view.render();
    },
    upload: function(){
      var this$ = this;
      return ext[this.ucfg.host]({
        files: this.lc.files,
        progress: this.progress,
        opt: this.ucfg
      }).then(function(it){
        this$.fire('upload.done', it);
        return it;
      })['catch'](function(it){
        this$.fire('upload.fail', it);
        return Promise.reject(it);
      });
    }
  });
  ext = {};
  ext.dummy = function(arg$){
    var files, progress, opt;
    files = arg$.files, progress = arg$.progress, opt = arg$.opt;
    return new Promise(function(res, rej){
      return res(files.map(function(it){
        return {
          url: "https://i.ibb.co/frf90x6/only-support.png",
          name: it.file.name
        };
      }));
    });
  };
  ext.native = function(arg$){
    var files, progress, opt;
    files = arg$.files, progress = arg$.progress, opt = arg$.opt;
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
        return xhr(route, {
          method: 'POST',
          body: fd
        }, {
          type: 'json'
        }).then(res)['catch'](rej);
      } else {
        ret = [];
        len = files.length;
        _ = function(list){
          var item, fd;
          item = list.splice(0, 1)[0];
          if (!item) {
            return res(ret);
          }
          fd = new FormData();
          fd.append('file', item.file);
          return xhr(route, {
            method: 'POST',
            body: fd
          }, {
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
              error: it
            });
          });
        };
        return _(files);
      }
    });
  };
  ext.imgbb = function(arg$){
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
        return xhr("https://api.imgbb.com/1/upload?key=" + opt.key, {
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
            error: it
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
  if (typeof module != 'undefined' && module !== null) {
    module.exports = uploadr;
  }
  if (typeof window != 'undefined' && window !== null) {
    return window.uploadr = uploadr;
  }
})();
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}