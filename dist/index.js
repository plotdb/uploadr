(function(){
  var parseDate, parseSize, uploadr, ext;
  parseDate = function(d){
    if (!d) {
      return 'n/a';
    }
    return new Date(d).toLocaleString("zh-TW", {
      timeZoneName: "short",
      hour12: false
    }).replace(/[\[\]]/g, '');
  };
  parseSize = function(size){
    var s, sizes, p, ref$, ref1$;
    size == null && (size = 0);
    s = +size;
    if (!s || isNaN(s)) {
      return "0 B";
    }
    sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    p = (ref$ = Math.floor(Math.log(s) / Math.log(1024))) < (ref1$ = sizes.length) ? ref$ : ref1$;
    return (s / Math.pow(1024, p)).toFixed(1) + (sizes[p] || '');
  };
  uploadr = function(opt){
    var this$ = this;
    opt == null && (opt = {});
    this.root = typeof opt.root === 'string'
      ? document.querySelector(opt.root)
      : opt.root;
    if (!this.root) {
      console.warn("[uploadr] warning: no node found for root ", opt.root);
    }
    this.evtHandler = {};
    this.opt = import$({}, opt);
    this.opt.provider = opt.provider || {
      host: 'native',
      config: {
        route: '/d/uploadr'
      }
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
    this.init = proxise.once(function(){
      return this$._init();
    });
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
    _init: function(){
      var this$ = this;
      return Promise.resolve().then(function(){
        var lc, preview, thumbing, view;
        lc = this$.lc;
        preview = function(files){
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
                  x$.backgroundImage = "url(" + file.thumb + ")";
                  x$.width = img.width + "px";
                  x$.height = img.height + "px";
                }
                return res(import$((ref$ = {}, ref$.width = img.width, ref$.height = img.height, ref$), file));
              };
              return img.src = file.thumb;
            });
          });
          return Promise.all(promises).then(function(){
            lc.files = (lc.files || []).concat(files);
            return debounce(500);
          }).then(function(){
            view.render();
            this$.fire('preview.done');
            if (this$.lc.loader) {
              this$.lc.loader.off();
            }
            return this$.fire('file.chosen', lc.files);
          });
        };
        thumbing = function(list){
          this$.fire('preview.loading');
          if (this$.lc.loader) {
            this$.lc.loader.on();
          }
          list = Array.from(list);
          return new Promise(function(res, rej){
            var ret, _;
            ret = [];
            _ = function(list){
              var file, src, img;
              file = list.splice(0, 1)[0];
              if (!file) {
                return res(ret);
              }
              src = URL.createObjectURL(file);
              img = new Image();
              img.onerror = function(){
                var svg, f;
                svg = '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="150" viewBox="0 0 200 150">\n  <rect width="200" height="150" x="0" y="0" fill="#ccc"/>\n</svg>';
                ret.push(f = {
                  thumb: "data:image/svg+xml," + encodeURIComponent(svg),
                  file: file
                });
                preview([f]);
                return _(list);
              };
              img.onload = function(){
                var ref$, w, h, c1, ctx;
                ref$ = [img.width, img.height], w = ref$[0], h = ref$[1];
                if (w > 200) {
                  ref$ = [200, h * 200 / w], w = ref$[0], h = ref$[1];
                }
                if (h > 150) {
                  ref$ = [w * 150 / h, 150], w = ref$[0], h = ref$[1];
                }
                c1 = document.createElement("canvas");
                c1.width = w;
                c1.height = h;
                ctx = c1.getContext('2d');
                ctx.drawImage(img, 0, 0, w, h);
                return c1.toBlob(function(blob){
                  var f;
                  ret.push(f = {
                    thumb: URL.createObjectURL(blob),
                    file: file
                  });
                  preview([f]);
                  return _(list);
                });
              };
              return img.src = src;
            };
            return _(list);
          });
        };
        return this$.lc.view = view = new ldView({
          root: this$.root,
          action: {
            input: {
              input: function(arg$){
                var node, evt;
                node = arg$.node, evt = arg$.evt;
                return thumbing(node.files).then(function(files){
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
                return thumbing(evt.dataTransfer.files);
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
            loader: function(arg$){
              var node;
              node = arg$.node;
              return this$.lc.loader = new ldloader({
                root: node
              });
            }
          },
          handler: {
            file: {
              list: function(){
                return lc.files || [];
              },
              view: {
                action: {
                  click: {
                    'delete': function(arg$){
                      var ctx, idx;
                      ctx = arg$.ctx;
                      if (!~(idx = lc.files.indexOf(ctx))) {
                        return;
                      }
                      lc.files.splice(idx, 1);
                      return lc.view.render('file');
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
                    return parseSize(ctx.file.size);
                  },
                  modifiedtime: function(arg$){
                    var ctx;
                    ctx = arg$.ctx;
                    return parseDate(ctx.file.lastModified);
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
    get: function(){
      return this.lc.files;
    },
    clear: function(){
      this.lc.files.splice(0);
      return this.lc.view.render();
    },
    upload: function(){
      var this$ = this;
      return ext[this.opt.provider.host]({
        files: this.lc.files,
        progress: this.progress,
        opt: this.opt.provider.config
      }).then(function(it){
        this$.fire('upload.done', it);
        return it;
      })['catch'](function(it){
        this$.fire('upload.fail', it);
        return Promise.reject(it);
      });
    }
  });
  uploadr.ext = ext = {};
  uploadr.viewer = function(opt){
    var lc, view, this$ = this;
    this.root = typeof opt.root === 'string'
      ? document.querySelector(opt.root)
      : opt.root;
    if (!this.root) {
      console.warn("[uploadr] warning: no node found for root ", opt.root);
    }
    this.evtHandler = {};
    this.lc = lc = {};
    this.files = lc.files = [];
    this.view = view = new ldView({
      root: this.root,
      action: {
        click: {
          load: function(arg$){
            var node, evt;
            node = arg$.node, evt = arg$.evt;
            return this$.page.fetch();
          },
          listx: function(arg$){
            var node, evt, n, src;
            node = arg$.node, evt = arg$.evt;
            if (!(n = ld$.parent(evt.target, '[data-src]', node))) {
              return;
            }
            src = n.getAttribute('data-src');
            return this$.fire('choose', {
              url: src
            });
          }
        }
      },
      handler: {
        file: {
          list: function(){
            return lc.files || [];
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
                  return this$.fire('choose', ctx);
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
                return parseSize(ctx.size);
              },
              modifiedtime: function(arg$){
                var ctx;
                ctx = arg$.ctx;
                return parseDate(ctx.lastModified);
              }
            },
            handler: {
              thumb: function(arg$){
                var node, ctx;
                node = arg$.node, ctx = arg$.ctx;
                if (node._load === ctx.url) {
                  return;
                }
                node._load = ctx.url;
                node.style.opacity = 0;
                if (node.nodeName.toLowerCase() === 'img') {
                  node.setAttribute('src', ctx.url);
                  node.onload = function(){
                    return ld$.find(node.parentNode, 'div[ld=thumb]').map(function(it){
                      return it.style.opacity = 1;
                    });
                  };
                } else {
                  node.style.backgroundImage = "url(" + ctx.url + ")";
                }
                return node.setAttribute('data-src', ctx.url);
              }
            }
          }
        }
      }
    });
    this.page = opt.page instanceof paginate
      ? opt.page
      : new paginate(opt.page || {});
    this.page.on('fetch', function(it){
      var files;
      files = it.map(function(it){
        return it._id = Math.random(), it;
      });
      lc.files = lc.files.concat(files);
      view.render();
      return this$.fire('fetch', files);
    });
    this.page.on('finish', function(){
      return this$.fire('finish');
    });
    this.page.on('empty', function(){
      return this$.fire('empty');
    });
    return this;
  };
  uploadr.viewer.prototype = import$(Object.create(Object.prototype), {
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
    fetch: function(){
      return this.page.fetch();
    },
    reset: function(){
      this.page.reset();
      this.lc.files = [];
      return this.view.render();
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
