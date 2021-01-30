<-(->it!) _

# opt: {key}
# e.g., {key: "97902907ac92c25e4c54b8d0b4c6eeac"}
uploadr.ext.imgbb = ({files, progress, opt}) -> new Promise (res, rej) ->
  ret = []
  len = files.length
  progress percent: 0, val: 0, len: len
  _ = (list) ~>
    item = list.splice(0, 1).0
    if !item => return res ret
    fd = new FormData!
    fd.append \image, item.file
    ld$.xhr(
      "https://api.imgbb.com/1/upload?key=#{opt.key}",
      {method: \POST, body: fd}
      {type: \json}
    )
      .then ->
        if !(it and it.data and it.status == 200) => return Promise.reject(it)
        ret.push o = {url: it.data.display_url, name: item.file.name, id: it.data.id, raw: it.data}
        progress {percent: (len - list.length) / len, val: (len - list.length), len: len, item: o}
        _ list
      .catch ->
        ret.push o = {name: item.file.name, err: it}
        progress {percent: (len - list.length) / len, val: (len - list.length), len: len, item: o}
  _ files

