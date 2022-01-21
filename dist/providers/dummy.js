(function(){
  uploadr.ext.dummy = function(arg$){
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
}).call(this);
