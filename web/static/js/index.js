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
        route: '/d/uploadr'
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
        route: '/d/uploadr/gcs',
        bucket: "plotdb-playground-test",
        domain: "https://storage.googleapis.com"
      }
    }
  };
  up = new uploadr({
    root: '[ld-scope=uploadr]',
    provider: providers.gcs
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
          root: node
        });
      },
      "ldcv-chooser": function(arg$){
        var node;
        node = arg$.node;
        return ldcv.chooser = new ldcover({
          root: node
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
    root: '[ld-scope=photo-viewer]',
    handler: {
      photo: {
        list: function(){
          return lc.files || [];
        },
        handle: function(arg$){
          var node, data;
          node = arg$.node, data = arg$.data;
          return node.style.backgroundImage = "url(" + data.url + ")";
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
                url: "/assets/img/sample/" + it + ".jpg"
              };
            }));
          });
        }
      }
    });
    viewer.fetch();
    return viewer.on('choose', function(it){
      ldnotify.send('success', "File \"" + it.url + "\" picked.");
      return ldcv.chooser.toggle(false);
    });
  };
  viewerMaker('[ld-scope=uploadr-viewer]', chooserroot);
  return viewerMaker('[ld-scope=uploadr-viewer2]', window);
});