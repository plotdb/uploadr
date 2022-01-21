uploadr = (opt = {}) ->
  @root = if typeof(opt.root) == \string => document.querySelector(opt.root) else opt.root
  if !@root => console.warn "[uploadr] warning: no node found for root ", opt.root
  @evt-handler = {}
  @opt = {} <<< opt
  @opt.provider = opt.provider or {host: 'native', config: {route: '/d/uploadr'}}
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
      opt: @opt.provider.config
    }
      .then ~>
        @fire \upload.done, it
        return it
      .catch ~>
        @fire \upload.fail, it
        Promise.reject it

uploadr.ext = ext = {}

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
