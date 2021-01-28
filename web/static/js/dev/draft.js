(function(){
  var uploadr;
  uploadr = function(opt){
    var local, ldcv, ldld, ui, show, view3, uploader, uploadFile, view2, view;
    local = {};
    ldcv = new ldCover({
      root: '.ldcv'
    });
    ldld = new ldLoader({
      root: '.ldcv .ld-over-full-inverse'
    });
    ui = function(opt){
      var ref$, empty, multiple;
      ref$ = import$({
        empty: true,
        multiple: false
      }, opt), empty = ref$.empty, multiple = ref$.multiple;
      ['list', 'add'].map(function(it){
        return view.get(it).classList.toggle('d-none', empty);
      });
      ['upload'].map(function(it){
        return view.get(it).classList.toggle('d-none', !empty);
      });
      ['single'].map(function(it){
        return view.get(it).classList.toggle('d-none', multiple);
      });
      return ['multiple'].map(function(it){
        return view.get(it).classList.toggle('d-none', !multiple);
      });
    };
    show = function(list){
      local.images = (list || []).filter(function(it){
        return it && !(it instanceof ldError);
      });
      return view3.render();
    };
    view3 = new ldView({
      root: '[ld-scope=gallery]',
      handler: {
        image: {
          list: function(){
            return local.images;
          },
          handle: function(arg$){
            var node, data, view;
            node = arg$.node, data = arg$.data;
            return view = new ldView({
              root: node,
              handler: {
                thumb: function(arg$){
                  var node;
                  node = arg$.node;
                  return node.style.backgroundImage = "url(" + data.url + ")";
                },
                name: function(arg$){
                  var node;
                  node = arg$.node;
                  node.textContent = data.id;
                  return node.setAttribute('href', data.url);
                }
              }
            });
          }
        }
      }
    });
    uploader = {
      dummy: function(arg$){
        var fd;
        fd = arg$.fd;
        return {
          url: "https://i.ibb.co/frf90x6/only-support.png",
          id: "VMRxBqn"
        };
      },
      native: function(arg$){
        var fd;
        fd = arg$.fd;
        return ld$.fetch('/d/uploadr', {
          method: 'POST',
          body: fd
        }, {
          type: 'json'
        }).then(function(it){
          return console.log(it);
        });
      },
      imgbb: function(arg$){
        var fd;
        fd = arg$.fd;
        return ld$.fetch('https://api.imgbb.com/1/upload?key=', {
          method: 'POST',
          body: fd
        }, {
          type: 'json'
        }).then(function(it){
          if (!(it && it.data && it.status === 200)) {
            return Promise.reject(it);
          }
          return {
            url: it.data.display_url,
            id: it.data.id,
            raw: it.data
          };
        })['catch'](function(e){
          return new ldError(e);
        });
      }
    };
    uploadFile = function(files){
      var fd;
      ldld.on();
      fd = new FormData();
      files.map(function(it){
        return fd.append('file', it.file);
      });
      return uploader.native({
        fd: fd
      })['finally'](function(){
        return ldld.off();
      });
    };
    view2 = new ldView({
      root: document,
      handler: {
        files: {
          list: function(){
            return local.files || [];
          },
          handle: function(arg$){
            var node, data, view;
            node = arg$.node, data = arg$.data;
            ld$.find(node, '.btn', 0).addEventListener('click', function(){
              var idx;
              node.parentNode.removeChild(node);
              idx = local.files.indexOf(data);
              if (idx >= 0) {
                local.files.splice(idx, 1);
              }
              if (local.files.length === 0) {
                return ui({
                  empty: true,
                  multiple: false
                });
              }
            });
            return view = new ldView({
              root: node,
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
    return view = new ldView({
      root: document,
      handler: {
        drop: function(arg$){
          var node;
          node = arg$.node;
          node.addEventListener('drop', function(e){
            e.preventDefault();
            return Array.from(e.dataTransfer.files).map(function(it){
              return console.log(it);
            });
          });
          return node.addEventListener('dragover', function(e){
            return e.preventDefault();
          });
        },
        input: function(arg$){
          var node, ldf;
          node = arg$.node;
          local.ldf = ldf = new ldFile({
            root: node,
            type: 'dataurl',
            forceEncoding: 'utf-8'
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
                  x$ = preview.style;
                  x$.backgroundImage = "url(" + files[0].result + ")";
                  x$.width = img.width + "px";
                  x$.height = img.height + "px";
                  return res(import$((ref$ = {}, ref$.width = img.width, ref$.height = img.height, ref$), file));
                };
                return img.src = file.result;
              });
            });
            return Promise.all(promises).then(function(){
              local.files = files;
              ui({
                empty: !local.files.length,
                multiple: local.files.length > 1
              });
              return view2.render();
            });
          });
        },
        cancel: function(arg$){
          var node;
          node = arg$.node;
          return node.addEventListener('click', function(){
            if (!local.files) {
              ldcv.toggle();
              return;
            }
            local.files = null;
            return ui({
              empty: true,
              multiple: false
            });
          });
        },
        add: function(arg$){
          var node;
          node = arg$.node;
          return node.addEventListener('click', function(){
            return uploadFile(local.files).then(function(it){
              return ldcv.set(it);
            });
          });
        },
        upload: function(){},
        preview: function(){},
        toggle: function(arg$){
          var node;
          node = arg$.node;
          return node.addEventListener('click', function(){
            return ldcv.get().then(function(it){
              return show(it);
            })['catch'](function(){});
          });
        }
      }
    });
  };
  uploadr.prototype = Object.create(Object.prototype);
  window.uploadr = uploadr;
  return uploadr();
})();
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}