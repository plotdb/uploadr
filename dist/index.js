(function(){
  var uploadr;
  uploadr = {
    ext: {},
    utils: {
      parseDate: function(d){
        if (!d) {
          return 'n/a';
        }
        return new Date(d).toLocaleString("zh-TW", {
          timeZoneName: "short",
          hour12: false
        }).replace(/[\[\]]/g, '').replace(/\s*GMT/, '');
      },
      parseSize: function(size){
        var s, sizes, p, ref$, ref1$;
        size == null && (size = 0);
        s = +size;
        if (!s || isNaN(s)) {
          return "0 B";
        }
        sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
        p = (ref$ = Math.floor(Math.log(s) / Math.log(1024))) < (ref1$ = sizes.length) ? ref$ : ref1$;
        return (s / Math.pow(1024, p)).toFixed(1) + (sizes[p] || '');
      }
    },
    i18n: {
      en: {
        "Drag & drop": "Drag & drop",
        "file(s) here": "file(s) here",
        "Name": "Name",
        "Size": "Size",
        "Modified Date": "Modified Date",
        "Add File ...": "Add File ...",
        "div": "div",
        "Upload": "Upload",
        "Clear": "Clear",
        "Close": "Close",
        "Load More": "Load More"
      },
      "zh-TW": {
        "Drag & drop": "拖拉檔案",
        "file(s) here": "至此處",
        "Name": "檔名",
        "Size": "檔案大小",
        "Modified Date": "修改時間",
        "Add File ...": "增加檔案 ...",
        "Upload": "上傳",
        "Clear": "清除",
        "Close": "關閉",
        "Load More": "載入更多"
      }
    }
  };
  uploadr.uploader = function(opt){
    var this$ = this;
    opt == null && (opt = {});
    this._ = {
      evthdr: {},
      files: [],
      opt: import$({}, opt),
      root: typeof opt.root === 'string'
        ? document.querySelector(opt.root)
        : opt.root
    };
    this._.opt.provider = opt.provider || {
      host: 'native',
      config: {
        route: '/api/uploadr'
      }
    };
    this.init = proxise.once(function(){
      return this$._init();
    });
    if (!this._.root) {
      console.warn("[@plotdb/uploadr] warning: no node found for root ", opt.root);
    }
    this.init();
    return this;
  };
  uploadr.uploader.prototype = import$(Object.create(Object.prototype), {
    on: function(n, cb){
      var this$ = this;
      return (Array.isArray(n)
        ? n
        : [n]).map(function(n){
        var ref$;
        return ((ref$ = this$._.evthdr)[n] || (ref$[n] = [])).push(cb);
      });
    },
    fire: function(n){
      var v, res$, i$, to$, ref$, len$, cb, results$ = [];
      res$ = [];
      for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
        res$.push(arguments[i$]);
      }
      v = res$;
      for (i$ = 0, len$ = (ref$ = this._.evthdr[n] || []).length; i$ < len$; ++i$) {
        cb = ref$[i$];
        results$.push(cb.apply(this, v));
      }
      return results$;
    },
    files: function(){
      return this._.files || [];
    },
    _init: function(){
      var this$ = this;
      return Promise.resolve().then(function(){
        var view;
        return this$._.view = view = new ldview({
          root: this$._.root,
          action: {
            input: {
              input: function(arg$){
                var node, evt;
                node = arg$.node, evt = arg$.evt;
                return this$.set(node.files).then(function(files){
                  var that;
                  node.value = null;
                  if (that = node.form) {
                    return that.reset();
                  }
                });
              }
            },
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
                var node, evt;
                node = arg$.node, evt = arg$.evt;
                evt.preventDefault();
                return this$.set(evt.dataTransfer.files);
              }
            },
            dragover: {
              drop: function(arg$){
                var evt;
                evt = arg$.evt;
                return evt.preventDefault();
              }
            }
          },
          init: {
            loader: function(arg$){
              var node;
              node = arg$.node;
              if (typeof ldloader != 'undefined' && ldloader !== null) {
                return this$._.loader = new ldloader({
                  root: node
                });
              }
            }
          },
          handler: {
            file: {
              list: function(){
                return this$._.files || [];
              },
              view: {
                action: {
                  click: {
                    'delete': function(arg$){
                      var ctx, idx;
                      ctx = arg$.ctx;
                      if (!~(idx = this$._.files.indexOf(ctx))) {
                        return;
                      }
                      this$._.files.splice(idx, 1);
                      return this$._.view.render('file');
                    }
                  }
                },
                text: {
                  name: function(arg$){
                    var ctx;
                    ctx = arg$.ctx;
                    return ctx.file.name;
                  },
                  size: function(arg$){
                    var ctx;
                    ctx = arg$.ctx;
                    return uploadr.utils.parseSize(ctx.file.size);
                  },
                  modifiedtime: function(arg$){
                    var ctx;
                    ctx = arg$.ctx;
                    return uploadr.utils.parseDate(ctx.file.lastModified);
                  }
                },
                handler: {
                  thumb: function(arg$){
                    var node, ctx;
                    node = arg$.node, ctx = arg$.ctx;
                    if (node.nodeName.toLowerCase() === 'img') {
                      return node.setAttribute('src', ctx.thumb);
                    } else {
                      return node.style.backgroundImage = "url(" + ctx.thumb + ")";
                    }
                  }
                }
              }
            }
          }
        });
      });
    },
    set: function(o){
      var ref$, ret, files, iterate, this$ = this;
      this.fire('preview:loading');
      if (this._.loader) {
        this._.loader.on();
      }
      ref$ = [
        [], Array.isArray(o)
          ? o
          : o.length
            ? Array.from(o)
            : [o]
      ], ret = ref$[0], files = ref$[1];
      iterate = function(){
        var file, p;
        if (!(file = files.splice(0, 1)[0])) {
          return Promise.resolve(ret);
        }
        p = new Promise(function(res, rej){
          var img;
          img = new Image();
          img.onerror = function(){
            var svg, f;
            svg = '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400">\n<rect width="400" height="400" x="0" y="0" fill="#ccc"/></svg>';
            ret.push(f = {
              thumb: "data:image/svg+xml," + encodeURIComponent(svg),
              file: file
            });
            return res(f);
          };
          img.onload = function(){
            var ref$, w, h, c1;
            ref$ = [img.width, img.height], w = ref$[0], h = ref$[1];
            if (w > 400) {
              ref$ = [400, h * 400 / w], w = ref$[0], h = ref$[1];
            }
            if (h > 400) {
              ref$ = [w * 400 / h, 400], w = ref$[0], h = ref$[1];
            }
            c1 = (ref$ = document.createElement('canvas'), ref$.width = w, ref$.height = h, ref$);
            c1.getContext('2d').drawImage(img, 0, 0, w, h);
            return c1.toBlob(function(blob){
              var f;
              ret.push(f = {
                thumb: URL.createObjectURL(blob),
                file: file
              });
              return res(f);
            });
          };
          return img.src = URL.createObjectURL(file);
        });
        return p.then(function(fobj){
          var ref$;
          ((ref$ = this$._).files || (ref$.files = [])).push(fobj);
          this$._.view.render();
          return iterate();
        });
      };
      return iterate().then(function(ret){
        this$._.view.render();
        if (this$._.loader) {
          this$._.loader.off();
        }
        this$.fire('preview:loaded');
        this$.fire('file:chosen', this$._.files);
        return ret;
      });
    },
    get: function(){
      return this._.files;
    },
    clear: function(){
      this._.files.splice(0);
      return this._.view.render();
    },
    progress: function(v){
      var n, ref$, p, this$ = this;
      if (!(n = (ref$ = v.item) != null ? ref$.node : void 8)) {
        return;
      }
      if (!(p = ld$.find(n, '[ld=progress]')[0])) {
        return;
      }
      p.style.width = v.percent * 100 + "%";
      if (v.percent < 1) {
        return;
      }
      return debounce(500).then(function(){
        var i;
        if (n.parentNode) {
          n.parentNode.removeChild(n);
        }
        if (~(i = this$._.files.indexOf(v.item))) {
          return this$._.files.splice(i, 1);
        }
      });
    },
    upload: function(){
      var this$ = this;
      return uploadr.ext[this._.opt.provider.host]({
        files: this._.files,
        progress: function(){
          return this$.progress.call(this$, arguments);
        },
        opt: this._.opt.provider.config
      }).then(function(it){
        this$.fire('upload:done', it);
        return it;
      })['catch'](function(it){
        this$.fire('upload:fail', it);
        return Promise.reject(it);
      });
    }
  });
  uploadr.viewer = function(opt){
    var this$ = this;
    this._ = {
      evthdr: {},
      files: [],
      root: typeof opt.root === 'string'
        ? document.querySelector(opt.root)
        : opt.root
    };
    if (!this._.root) {
      console.warn("[uploadr] warning: no node found for root ", opt.root);
    }
    this._.view = new ldview({
      root: this._.root,
      action: {
        click: {
          load: function(){
            return this$._.page.fetch();
          }
        }
      },
      handler: {
        file: {
          list: function(){
            return this$._.files || [];
          },
          key: function(it){
            return it._id;
          },
          view: {
            action: {
              click: {
                "@": function(arg$){
                  var ctx;
                  ctx = arg$.ctx;
                  return this$.fire('file:chosen', ctx);
                }
              }
            },
            text: {
              name: function(arg$){
                var ctx;
                ctx = arg$.ctx;
                return ctx.name || 'unnamed';
              },
              size: function(arg$){
                var ctx;
                ctx = arg$.ctx;
                return uploadr.utils.parseSize(ctx.size);
              },
              modifiedtime: function(arg$){
                var ctx;
                ctx = arg$.ctx;
                return uploadr.utils.parseDate(ctx.lastModified);
              }
            },
            handler: {
              thumb: function(arg$){
                var node, ctx, local;
                node = arg$.node, ctx = arg$.ctx, local = arg$.local;
                if (node.dataset.src === ctx.url) {
                  return;
                }
                if (node.nodeName.toLowerCase() === 'img') {
                  node.setAttribute('src', ctx.url);
                } else {
                  node.style.backgroundImage = "url(" + ctx.url + ")";
                }
                return node.dataset.src = ctx.url;
              }
            }
          }
        }
      }
    });
    this._.page = opt.page instanceof paginate
      ? opt.page
      : new paginate(opt.page || {});
    this._.page.on('fetch', function(it){
      var files, ref$;
      files = it.map(function(it){
        return it._id = Math.random().toString(36).substring(2), it;
      });
      (ref$ = this$._).files = ref$.files.concat(files);
      this$._.view.render();
      return this$.fire('fetch:fetched', files);
    });
    this._.page.on('finish', function(){
      return this$.fire('fetch:end');
    });
    this._.page.on('empty', function(){
      return this$.fire('fetch:empty');
    });
    return this;
  };
  uploadr.viewer.prototype = import$(Object.create(Object.prototype), {
    on: function(n, cb){
      var this$ = this;
      return (Array.isArray(n)
        ? n
        : [n]).map(function(n){
        var ref$;
        return ((ref$ = this$._.evthdr)[n] || (ref$[n] = [])).push(cb);
      });
    },
    fire: function(n){
      var v, res$, i$, to$, ref$, len$, cb, results$ = [];
      res$ = [];
      for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
        res$.push(arguments[i$]);
      }
      v = res$;
      for (i$ = 0, len$ = (ref$ = this._.evthdr[n] || []).length; i$ < len$; ++i$) {
        cb = ref$[i$];
        results$.push(cb.apply(this, v));
      }
      return results$;
    },
    fetch: function(){
      return this._.page.fetch();
    },
    reset: function(){
      this._.page.reset();
      this._.files = [];
      return this._.view.render();
    }
  });
  if (typeof module != 'undefined' && module !== null) {
    module.exports = uploadr;
  } else if (typeof window != 'undefined' && window !== null) {
    window.uploadr = uploadr;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
