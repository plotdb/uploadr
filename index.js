(function(){
  var uploadr;
  uploadr = {
    ext: {},
    assets: {
      thumbholder: "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="-5400 -5400 12000 12000"><rect width="12000" height="12000" x="-5400" y="-5400" fill="#ccc"/><path fill="#777" d="M1099.7 345.4v-.4a49.8 49.8 0 0 0-9.4-24.6l-.2-.2-1.2-1.5-.3-.4-1.3-1.4c0-.2-.2-.3-.3-.5a50 50 0 0 0-1.7-1.8l-300-300-1.8-1.6-.4-.4-1.5-1.2c0-.2-.2-.3-.4-.4l-1.5-1.2s-.2 0-.3-.2l-1.7-1.2A49.7 49.7 0 0 0 754.8.2h-.3A50.3 50.3 0 0 0 750 0H150a50 50 0 0 0-50 50v1100a50 50 0 0 0 50 50h900a50 50 0 0 0 50-50V350a49.7 49.7 0 0 0-.2-4.6zM800 170.7 929.3 300H800V170.7zM200 1100V100h500v250a50 50 0 0 0 50 50h250v700H200z"/></svg>')
    },
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
        "Load More": "Load More",
        "End of List": "End of List",
        "Reload": "Reload"
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
        "Load More": "載入更多",
        "End of List": "列表結尾",
        "Reload": "重新載入"
      }
    }
  };
  uploadr.uploader = function(opt){
    var k, ref$, v, this$ = this;
    opt == null && (opt = {});
    this._ = {
      evthdr: {},
      files: [],
      opt: import$({}, opt),
      accept: (opt.accept || '').split(',').map(function(it){
        return "." + it.replace('.', '');
      }),
      root: typeof opt.root === 'string'
        ? document.querySelector(opt.root)
        : opt.root,
      i18n: opt.i18n
    };
    this._.opt.provider = opt.provider || {
      host: 'native',
      config: {
        route: '/api/uploadr'
      }
    };
    if (this._.i18n) {
      for (k in ref$ = uploadr.i18n) {
        v = ref$[k];
        this._.i18n.addResourceBundle(k, "@plotdb/uploadr:uploader", v, true, true);
      }
    }
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
    i18n: function(lng){
      var this$ = this;
      if (!this._.i18n) {
        return;
      }
      return Array.from(this._.root.querySelectorAll('[t]')).map(function(node){
        var v;
        if (!(v = node.getAttribute('t'))) {
          node.setAttribute('t', v = node.textContent);
        }
        return node.textContent = this$._.i18n.t(v, {
          ns: "@plotdb/uploadr:uploader",
          lng: lng
        });
      });
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
                var node, evt, files, re;
                node = arg$.node, evt = arg$.evt;
                evt.preventDefault();
                files = Array.from(evt.dataTransfer.files);
                if (this$._.accept) {
                  re = new RegExp("." + this$._.accept.split(',').join('|') + "$");
                  files = files.filter(function(it){
                    return !!re.exec(it.name);
                  });
                }
                return this$.set(files);
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
            input: function(arg$){
              var node;
              node = arg$.node;
              if (this$._.accept) {
                return node.setAttribute('accept', this$._.accept);
              } else {
                return node.removeAttribute('accept');
              }
            },
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
      var ref$, fobjs, files, iterate, this$ = this;
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
      ], fobjs = ref$[0], files = ref$[1];
      iterate = function(){
        var file, p;
        if (!(file = files.splice(0, 1)[0])) {
          return Promise.resolve(fobjs);
        }
        p = new Promise(function(res, rej){
          var img;
          img = new Image();
          img.onerror = function(){
            var f;
            fobjs.push(f = {
              thumb: uploadr.assets.thumbholder,
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
              fobjs.push(f = {
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
    var k, ref$, v, this$ = this;
    this._ = {
      evthdr: {},
      files: [],
      running: false,
      i18n: opt.i18n,
      root: typeof opt.root === 'string'
        ? document.querySelector(opt.root)
        : opt.root
    };
    if (!this._.root) {
      console.warn("[@plotdb/uploadr] warning: no node found for root ", opt.root);
    }
    if (this._.i18n) {
      for (k in ref$ = uploadr.i18n) {
        v = ref$[k];
        this._.i18n.addResourceBundle(k, "@plotdb/uploadr:viewer", v, true, true);
      }
    }
    this._.view = new ldview({
      root: this._.root,
      action: {
        click: {
          load: function(){
            return this$.fetch();
          },
          reset: function(){
            return this$.reset();
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
        load: function(arg$){
          var node;
          node = arg$.node;
          return node.classList.toggle('d-none', !this$._.page.fetchable());
        },
        end: function(arg$){
          var node;
          node = arg$.node;
          return node.classList.toggle('d-none', !!this$._.page.fetchable());
        },
        reset: function(arg$){
          var node;
          node = arg$.node;
          return node.classList.toggle('d-none', !!this$._.page.fetchable());
        },
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
                  node.setAttribute('src', ctx.thumb);
                } else {
                  node.style.backgroundImage = "url(" + ctx.thumb + ")";
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
      var files, ps;
      files = it.map(function(it){
        return it._id = Math.random().toString(36).substring(2), it;
      });
      ps = Promise.all(files.map(function(file){
        return new Promise(function(res, rej){
          var img;
          img = new Image();
          img.onerror = function(){
            file.thumb = uploadr.assets.thumbholder;
            return res();
          };
          img.onload = function(){
            file.thumb = file.url;
            return res();
          };
          return img.src = file.url;
        });
      }));
      return ps.then(function(){
        return debounce(2000).then(function(){
          var ref$;
          (ref$ = this$._).files = ref$.files.concat(files);
          this$._.view.render();
          if (this$._.loader) {
            this$._.loader.off();
          }
          this$._.running = false;
          return this$.fire('fetch:fetched', files);
        });
      });
    });
    this._.page.on('finish', function(){
      this$._.running = false;
      return this$.fire('fetch:end');
    });
    this._.page.on('empty', function(){
      this$._.running = false;
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
      if (this._.running || !this._.page.fetchable()) {
        return;
      }
      this._.loader.on();
      this._.running = true;
      return this._.page.fetch();
    },
    reset: function(){
      var this$ = this;
      return this._.page.reset().then(function(){
        this$._.files = [];
        return this$._.view.render();
      });
    },
    i18n: function(lng){
      var this$ = this;
      if (!this._.i18n) {
        return;
      }
      return Array.from(this._.root.querySelectorAll('[t]')).map(function(node){
        var v;
        if (!(v = node.getAttribute('t'))) {
          node.setAttribute('t', v = node.textContent);
        }
        return node.textContent = this$._.i18n.t(v, {
          ns: "@plotdb/uploadr:viewer",
          lng: lng
        });
      });
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
