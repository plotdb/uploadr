<-(->it!) _

uploadr.ext.dummy = ({files, progress, opt}) -> new Promise (res, rej) ->
  res files.map -> {url: "https://i.ibb.co/frf90x6/only-support.png", name: it.file.name}

