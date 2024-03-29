uploadr.ext.gcs = ({files, progress, opt, data}) -> new Promise (res, rej) ->
  ret = []
  len = files.length
  domain = opt.domain or "https://storage.googleapis.com"
  fd = new FormData!
  fd.append \count, files.length
  if data? => fd.append \data, if typeof(data) == \object => JSON.stringify(data) else data
  ld$.fetch opt.route, {method: \POST, body: fd}, {type: \json}
    .then (tokens) ->
      Promise.all(
        files.map (item,i) ->
          {signed-url, id} = tokens[i]
          ld$.xhr(
            signed-url, 
            {method: \PUT, body: item.file, headers: {"Content-Type": item.file.type}},
            {
              no-default-headers: true
              progress: -> progress {percent: it.percent, item}
            }
          )
            .then -> {name: item.file.name, id, url: "#domain/#{opt.bucket}/#{id}"}
            .catch -> {name: item.file.name, err: it}
      )
    .then -> res it
    .catch -> rej it

