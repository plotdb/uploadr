(function(it){
  return it();
})(function(){
  var lc, providers, up, ldcv, view, count, viewer;
  lc = {
    files: []
  };
  providers = {
    native: {
      host: 'native',
      route: '/d/uploadr'
    },
    imgbb: {
      host: 'imgbb',
      key: "97902907ac92c25e4c54b8d0b4c6eeac"
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
  view = new ldView({
    root: document.body,
    init: {
      "ldcv-uploadr": function(arg$){
        var node;
        node = arg$.node;
        return ldcv.uploadr = new ldCover({
          root: node
        });
      }
    },
    action: {
      click: {
        "toggle-uploader": function(){
          return ldcv.uploadr.toggle();
        }
      }
    }
  });
  view = new ldView({
    root: '[ld-scope=viewer]',
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
  count = 0;
  viewer = new uploadr.viewer({
    root: '[ld-scope=image-viewer]',
    page: {
      host: window,
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
  return viewer.page.fetch();
});