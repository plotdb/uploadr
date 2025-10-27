uploadr.ext.native = ({files, progress, opt, data}) -> new Promise (res, rej) ->
  {merge, route} = (opt or {})
  progress percent: 0, val: 0, len: len
  if merge =>
    fd = new FormData!
    files.map -> fd.append \file, it.file
    if data? => fd.append \data, if typeof(data) == \object => JSON.stringify(data) else data
    ld$.xhr route, ({method: \POST, body: fd} <<< opt{headers}), {type: \json}
      .then res
      .catch rej
  else =>
    ret = []
    len = files.length
    _ = (list) ~>
      item = list.splice(0, 1).0
      if !item => return res ret
      fd = new FormData!
      fd.append \file, item.file
      if data? => fd.append \data, if typeof(data) == \object => JSON.stringify(data) else data
      ld$.xhr route, {method: \POST, body: fd} <<< opt{headers}, {type: \json, progress: -> progress it <<< {item}}
        .then ->
          ret.push o = it.0
          _ list
        .catch -> ret.push o = {name: item.file.name, err: it}
    _ files
