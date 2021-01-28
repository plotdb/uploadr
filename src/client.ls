<-(->it!) _

uploadr = (opt = {}) ->
  @root = if typeof(opt.root) == \string => document.querySelector(opt.root) else opt.root
  if !@root => console.warn "[uploadr] warning: no node found for root ", opt.root
  @evt-handler = {}
  @opt = {} <<< opt
  @opt.provider = opt.provider or {route: '/d/uploadr', host: 'native'}
  @progress = (v) ~>
    if !(n = v.{}item.node) => return
    if !(p = ld$.find n, '[ld=progress]' .0) => return
    p.style.width = "#{(v.percent * 100)}%"
    if v.percent >= 1 =>
      debounce 500 .then ~>
        ld$.remove n
        if ~(i = @lc.files.indexOf(v.item)) => @lc.files.splice(i,1)
  @lc = {files: []}
  @init = proxise.once ~> @_init!
  @init!
  @

uploadr.prototype = Object.create(Object.prototype) <<< do
  on: (n, cb) -> @evt-handler.[][n].push cb
  fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
  _init: -> Promise.resolve!then ~>
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
          @lc.loader.off!
          @fire \file.chosen, lc.files

    thumbing = (list) ~>
      @fire \preview.loading
      @lc.loader.on!
      list = Array.from(list)
      new Promise (res, rej) ->
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

    @lc.view = view = new ldView do
      root: @root
      action: do
        input: input: ({node, evt}) ->
          thumbing node.files
            .then (files) ->
              node.value = null
              if node.form => that.reset!

        click:
          upload: ({node, evt}) ~> @upload!then ~> @clear!; return it
          clear: ({node, evt}) ~> @clear!
        drop: do
          drop: ({node, evt}) ~>
            evt.preventDefault!
            thumbing evt.dataTransfer.files
        dragover: do
          drop: ({node, evt}) -> evt.preventDefault!
      init: do
        loader: ({node}) ~> @lc.loader = new ldLoader root: node
      handler:
        file:
          list: -> lc.files or []
          view:
            action: click:
              delete: ({context}) ->
                if !~(idx = lc.files.indexOf(context)) => return
                lc.files.splice(idx, 1)
                lc.view.render \file
            handler:
              name: ({node,context}) -> node.textContent = context.file.name
              size: ({node,context}) -> node.textContent = "#{Math.round(context.file.size / 1024)}KB"
              thumb: ({node,context}) ->
                if node.nodeName.toLowerCase! == \img =>
                  node.setAttribute \src, context.thumb
                else node.style.backgroundImage = "url(#{context.thumb})"

  get: -> return @lc.files
  clear: -> @lc.files.splice(0); @lc.view.render!
  upload: ->
    ext[@opt.provider.host] {
      files: @lc.files
      progress: @progress
      opt: @opt.provider
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

uploadr.viewer = (opt) ->
  @root = if typeof(opt.root) == \string => document.querySelector(opt.root) else opt.root
  if !@root => console.warn "[uploadr] warning: no node found for root ", opt.root
  @evt-handler = {}
  @lc = lc = {}
  @files = lc.files = []
  @view = view = new ldView do
    root: @root
    action: click: do
      list: ({node, evt}) ~>
        if !(n = ld$.parent(evt.target, '[data-src]', node)) => return
        src = n.getAttribute(\data-src)
        @fire \choose, {url: src}
    handler: do
      file: do
        list: -> lc.files or []
        key: -> it._id
        view:
          text:
            size: ({context}) ->
            name: ({context}) ->
          handler:
            thumb: ({node, context}) ->
              if node._load == context.url => return
              node._load = context.url
              node.style.opacity = 0
              if node.nodeName.toLowerCase! == \img =>
                node.setAttribute \src, context.url
                node.onload = -> ld$.find(node.parentNode, 'div[ld=thumb]').map -> it.style.opacity = 1
              else
                node.style.backgroundImage = "url(#{context.url})"
              node.setAttribute \data-src, context.url

  @page = if opt.page instanceof ldPage => opt.page else new ldPage(opt.page or {})
  @page.init!
  @page.on \fetch, ~>
    files = it.map -> it <<< {_id: Math.random!}
    lc.files ++= files
    view.render!
    @fire \fetch, files
  @page.on \finish, ~> @fire \finish
  @page.on \empty, ~> @fire \empty
  @

uploadr.viewer.prototype = Object.create(Object.prototype) <<< do
  on: (n, cb) -> @evt-handler.[][n].push cb
  fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
  fetch: -> @page.fetch!
  reset: ->
    @page.reset!
    @lc.files = []
    @view.render!

if module? => module.exports = uploadr
else if window? => window.uploadr = uploadr
