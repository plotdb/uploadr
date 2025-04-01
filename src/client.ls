parse-date = (d) ->
  if !d => return 'n/a'
  new Date(d).toLocaleString("zh-TW", {timeZoneName: "short", hour12: false}).replace(/[\[\]]/g,'')

parse-size = (size = 0) ->
  s = +size
  if !s or isNaN(s) => return "0 B"
  sizes = <[B KB MB GB TB PB]>
  p = Math.floor(Math.log(s) / Math.log(1024)) <? sizes.length
  (s / Math.pow(1024, p)).toFixed(1) + (sizes[p] or '')

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
          if @lc.loader => @lc.loader.off!
          @fire \file.chosen, lc.files

    thumbing = (list) ~>
      @fire \preview.loading
      if @lc.loader => @lc.loader.on!
      list = Array.from(list)
      new Promise (res, rej) ->
        ret = []
        _ = (list) ->
          file = list.splice(0,1).0
          if !file =>
            return res ret
          src = URL.createObjectURL(file)
          img = new Image!
          img.onerror = ->
            svg = '''
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="150" viewBox="0 0 200 150">
              <rect width="200" height="150" x="0" y="0" fill="#ccc"/>
            </svg>
            '''
            ret.push f = {thumb: "data:image/svg+xml,#{encodeURIComponent(svg)}", file: file}
            preview [f]
            _ list
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
        loader: ({node}) ~> @lc.loader = new ldloader root: node
      handler:
        file:
          list: -> lc.files or []
          view:
            action: click:
              delete: ({ctx}) ->
                if !~(idx = lc.files.indexOf(ctx)) => return
                lc.files.splice(idx, 1)
                lc.view.render \file
            text:
              name: ({ctx}) -> ctx.file.name
              size: ({ctx}) -> parse-size ctx.file.size
              modifiedtime: ({ctx}) -> parse-date ctx.file.lastModified
            handler:
              thumb: ({node,ctx}) ->
                if node.nodeName.toLowerCase! == \img =>
                  node.setAttribute \src, ctx.thumb
                else node.style.backgroundImage = "url(#{ctx.thumb})"

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
    action: click:
      load: ({node, evt}) ~> @page.fetch!
      listx: ({node, evt}) ~>
        if !(n = ld$.parent(evt.target, '[data-src]', node)) => return
        src = n.getAttribute(\data-src)
        @fire \choose, {url: src}
    handler: do
      file: do
        list: -> lc.files or []
        key: -> it._id
        view:
          action: click: "@": ({ctx}) ~> @fire \choose, ctx
          text:
            name: ({ctx}) -> ctx.name or 'unnamed'
            size: ({ctx}) -> parse-size ctx.size
            modifiedtime: ({ctx}) -> parse-date ctx.lastModified
          handler:
            thumb: ({node, ctx}) ->
              if node._load == ctx.url => return
              node._load = ctx.url
              node.style.opacity = 0
              if node.nodeName.toLowerCase! == \img =>
                node.setAttribute \src, ctx.url
                node.onload = -> ld$.find(node.parentNode, 'div[ld=thumb]').map -> it.style.opacity = 1
              else
                node.style.backgroundImage = "url(#{ctx.url})"
              node.setAttribute \data-src, ctx.url

  @page = if opt.page instanceof paginate => opt.page else new paginate(opt.page or {})
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
