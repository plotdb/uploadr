(->
  viewer = if window.{}uploadr.viewer => that else null
  uploadr = (opt = {}) ->
    @root = if typeof(opt.root) == \string => document.querySelector(opt.root) else opt.root
    if !@root => console.warn "[uploadr] warning: no node found for root ", opt.root
    @evt-handler = {}
    @opt = opt
    @ucfg = opt.uploader or {route: '/d/uploadr', host: 'native'}
    @progress = (v) ~>
      if !(n = v.{}item.node) => return
      if !(p = ld$.find n, '[ld=progress]' .0) => return
      p.style.width = "#{(v.percent * 100)}%"
      if v.percent >= 1 =>
        debounce 500 .then ~>
          ld$.remove n
          if ~(i = @lc.files.indexOf(v.item)) => @lc.files.splice(i,1)
      
    # opt.progress or (->)
    @lc = {files: []}
    @init!
    @

  uploadr.prototype = Object.create(Object.prototype) <<< do
    on: (n, cb) -> @evt-handler.[][n].push cb
    fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
    init: ->
      lc = @lc
      preview = (files) ~>
        preview = view.get(\preview)
        promises = files.map (file) -> new Promise (res, rej) ->
          img = new Image
          img.onload = ->
            if preview => preview.style
              ..backgroundImage = "url(#{file.thumb})"
              ..width = "#{img.width}px"
              ..height = "#{img.height}px"
            res {} <<< img{width, height} <<< file
          img.src = file.thumb
        Promise.all(promises)
          .then ->
            lc.files = (lc.files or []) ++  files
            debounce 500
          .then ~>
            view.render!
            @fire \preview.done
            @fire \file.chosen, lc.files

      @lc.view = view = new ldView do
        root: @root
        action: do
          input: input: ({node, evt}) ->
            thumb = (list) -> new Promise (res, rej) ->
              ret = []
              _ = (list) ->
                file = list.splice(0,1).0
                if !file =>
                  return res ret
                src = URL.createObjectURL(file)
                img = new Image!
                img.onload = ->
                  [w, h] = [img.width, img.height]
                  if w > 200 => [w, h] = [200, h * 200/w]
                  if h > 150 => [w, h] = [w * 150/h, 150]
                  c1 = document.createElement("canvas")
                  c1 <<< {width: w, height: h}
                  ctx = c1.getContext \2d
                  ctx.drawImage img, 0, 0, w, h
                  c1.toBlob (blob) ->
                    ret.push f = {thumb: URL.createObjectURL(blob), file: file}
                    preview [f]
                    _ list
                img.src = src
              _ list
            thumb Array.from(node.files)
              .then (files) ->
                if node.form => that.reset!


          click:
            upload: ({node, evt}) ~> @upload!then ~> @clear!; return it
            clear: ({node, evt}) ~> @clear!
          drop: do
            drop: ({node, evt}) ~>
              evt.preventDefault!
              @fire \preview.loading
              promises = Array.from(evt.dataTransfer.files).map -> ldFile.from-file it, \dataurl, \utf-8
              Promise.all promises
                .then ~> perview files
          dragover: do
            drop: ({node, evt}) -> evt.preventDefault!

        handler:
          file:
            list: -> lc.files or []
            handle: ({node, data}) ->
              data.node = node
              view = new ldView do
                root: node
                action: click: do
                  delete: -> 
                    node.parentNode.removeChild node
                    idx = lc.files.indexOf(data)
                    if idx >= 0 => lc.files.splice(idx, 1)
                handler: do
                  name: ({node}) -> node.textContent = data.file.name
                  size: ({node}) -> node.textContent = "#{Math.round(data.file.size / 1024)}KB"
                  thumb: ({node}) ->
                    if node.nodeName.toLowerCase! == \img =>
                      node.setAttribute \src, data.thumb
                    else node.style.backgroundImage = "url(#{data.thumb})"
    get: -> return @lc.files
    clear: -> @lc.files.splice(0); @lc.view.render!
    upload: ->
      ext[@ucfg.host] {
        files: @lc.files
        progress: @progress
        opt: @ucfg
      }
        .then ~>
          @fire \upload.done, it
          return it
        .catch ~>
          @fire \upload.fail, it
          Promise.reject it

  uploadr.ext = ext = {}
  ext.dummy = ({files, progress, opt}) -> new Promise (res, rej) ->
    res files.map -> {url: "https://i.ibb.co/frf90x6/only-support.png", name: it.file.name}

  ext.native = ({files, progress, opt}) -> new Promise (res, rej) ->
    {merge, route} = (opt or {})
    progress percent: 0, val: 0, len: len
    if merge => 
      fd = new FormData!
      files.map -> fd.append \file, it.file
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
        ld$.xhr route, {method: \POST, body: fd} <<< opt{headers}, {type: \json, progress: -> progress it <<< {item}}
          .then ->
            ret.push o = it.0
            _ list
          .catch -> ret.push o = {name: item.file.name, error: it}
      _ files

  # opt: {key}
  # e.g., {key: "97902907ac92c25e4c54b8d0b4c6eeac"}
  ext.imgbb = ({files, progress, opt}) -> new Promise (res, rej) ->
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
          ret.push o = {name: item.file.name, error: it}
          progress {percent: (len - list.length) / len, val: (len - list.length), len: len, item: o}
    _ files

  if viewer => uploadr.viewer = that
  if module? => module.exports = uploadr
  if window? => window.uploadr = uploadr
)!
