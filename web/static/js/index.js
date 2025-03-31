(function(it){
  return it();
})(function(){
  var lc, providers, up, ldcv, view, viewerMaker;
  lc = {
    files: []
  };
  providers = {
    native: {
      host: 'native',
      config: {
        route: '/api/uploadr/native'
      }
    },
    imgbb: {
      host: 'imgbb',
      config: {
        key: "97902907ac92c25e4c54b8d0b4c6eeac"
      }
    },
    gcs: {
      host: 'gcs',
      config: {
        route: '/api/uploadr/gcs',
        bucket: "plotdb-playground-test",
        domain: "https://storage.googleapis.com"
      }
    }
  };
  up = new uploadr({
    root: '[ld-scope=uploadr]',
    provider: providers.native
  });
  up.on('upload.done', function(it){
    lc.files = lc.files.concat(it);
    ldcv.uploadr.toggle(false);
    return view.render();
  });
  ldcv = {};
  view = new ldview({
    root: document.body,
    init: {
      "ldcv-uploadr": function(arg$){
        var node;
        node = arg$.node;
        return ldcv.uploadr = new ldcover({
          root: node,
          resident: true
        });
      },
      "ldcv-chooser": function(arg$){
        var node;
        node = arg$.node;
        return ldcv.chooser = new ldcover({
          root: node,
          resident: true
        });
      }
    },
    action: {
      click: {
        "toggle-uploader": function(){
          return ldcv.uploadr.toggle();
        },
        "toggle-chooser": function(){
          return ldcv.chooser.toggle();
        }
      }
    }
  });
  view = new ldview({
    root: '[ld-scope=file-viewer]',
    handler: {
      empty: function(arg$){
        var node, ctx;
        node = arg$.node, ctx = arg$.ctx;
        return node.classList.toggle('d-none', !!lc.files.length);
      },
      file: {
        list: function(){
          return lc.files || [];
        },
        key: function(it){
          return it.id || it.key;
        },
        view: {
          handler: {
            "@": function(arg$){
              var node, ctx;
              node = arg$.node, ctx = arg$.ctx;
              if (/.(jpg|jpeg|png|gif|webp)$/.exec(ctx.name)) {
                return node.style.backgroundImage = "url(" + ctx.url + ")";
              } else {
                return node.textContent = ctx.name;
              }
            }
          }
        }
      }
    }
  });
  viewerMaker = function(root, host){
    var viewer;
    viewer = new uploadr.viewer({
      root: root,
      page: {
        host: host,
        fetchOnScroll: true,
        limit: 9,
        boundary: 100,
        fetch: function(){
          return new Promise(function(res, rej){
            return res([1, 2, 3, 4, 5, 6, 7, 8, 9].map(function(it){
              return {
                url: "/assets/img/sample/" + it + ".jpg",
                size: Math.round(Math.random() * (1048576 * 1024)),
                name: "DSC_" + (Math.floor(Math.random() * 10000) + "").padStart(4, "0") + ".jpg",
                lastModified: Date.now() - Math.round(Math.random() * 1000 * 1440 * 365)
              };
            }));
          });
        }
      }
    });
    viewer.fetch();
    return viewer.on('choose', function(f){
      ldnotify.send('success', "File \"" + f.name + "\" picked.");
      return ldcv.chooser.toggle(false);
    });
  };
  viewerMaker('[ld-scope=uploadr-viewer]', chooserroot);
  return viewerMaker('[ld-scope=uploadr-viewer2]', document.body);
});