uploadr =
  ext: {}
  assets:
    thumbholder: "data:image/svg+xml,#{encodeURIComponent('''<svg xmlns="http://www.w3.org/2000/svg" viewBox="-5400 -5400 12000 12000"><rect width="12000" height="12000" x="-5400" y="-5400" fill="#ccc"/><path fill="#777" d="M1099.7 345.4v-.4a49.8 49.8 0 0 0-9.4-24.6l-.2-.2-1.2-1.5-.3-.4-1.3-1.4c0-.2-.2-.3-.3-.5a50 50 0 0 0-1.7-1.8l-300-300-1.8-1.6-.4-.4-1.5-1.2c0-.2-.2-.3-.4-.4l-1.5-1.2s-.2 0-.3-.2l-1.7-1.2A49.7 49.7 0 0 0 754.8.2h-.3A50.3 50.3 0 0 0 750 0H150a50 50 0 0 0-50 50v1100a50 50 0 0 0 50 50h900a50 50 0 0 0 50-50V350a49.7 49.7 0 0 0-.2-4.6zM800 170.7 929.3 300H800V170.7zM200 1100V100h500v250a50 50 0 0 0 50 50h250v700H200z"/></svg>''')}"
  utils:
    parse-date: (d) ->
      if !d => return 'n/a'
      new Date(d).toLocaleString("zh-TW", {timeZoneName: "short", hour12: false})
        .replace(/[\[\]]/g,'').replace(/\s*GMT/,'')
    parse-size: (size = 0) ->
      s = +size
      if !s or isNaN(s) => return "0 B"
      sizes = <[B KB MB GB TB PB]>
      p = Math.floor(Math.log(s) / Math.log(1024)) <? sizes.length
      (s / Math.pow(1024, p)).toFixed(1) + (sizes[p] or '')
  i18n:
    en:
      "Drag & drop": "Drag & drop"
      "file(s) here": "file(s) here"
      "Name": "Name"
      "Size": "Size"
      "Modified Date": "Modified Date"
      "Add File ...": "Add File ..."
      "div": "div"
      "Upload": "Upload"
      "Clear": "Clear"
      "Close": "Close"
      "Load More": "Load More"
    "zh-TW":
      "Drag & drop": "拖拉檔案"
      "file(s) here": "至此處"
      "Name": "檔名"
      "Size": "檔案大小"
      "Modified Date": "修改時間"
      "Add File ...": "增加檔案 ..."
      "Upload": "上傳"
      "Clear": "清除"
      "Close": "關閉"
      "Load More": "載入更多"

uploadr.uploader = (opt = {}) ->
  @_ =
    evthdr: {}, files: []
    opt: {} <<< opt
    accept: (opt.accept or '').split(',').map(->".#{it.replace('.','')}")
    root: if typeof(opt.root) == \string => document.querySelector(opt.root) else opt.root
  @_.opt.provider = opt.provider or {host: \native, config: route: \/api/uploadr}
  @init = proxise.once ~> @_init!
  if !@_.root => console.warn "[@plotdb/uploadr] warning: no node found for root ", opt.root
  @init!
  @

uploadr.uploader.prototype = Object.create(Object.prototype) <<< do
  on: (n, cb) -> (if Array.isArray(n) => n else [n]).map (n) ~> @_.evthdr.[][n].push cb
  fire: (n, ...v) -> for cb in (@_.evthdr[n] or []) => cb.apply @, v
  files: -> @_.files or []
  _init: -> Promise.resolve!then ~>
    @_.view = view = new ldview do
      root: @_.root
      action:
        input: input: ({node, evt}) ~>
          (files) <~ @set node.files .then _
          node.value = null
          if node.form => that.reset!
        click:
          upload: ({node, evt}) ~> @upload!then ~> @clear!; return it
          clear: ({node, evt}) ~> @clear!
        drop: drop: ({node, evt}) ~>
          evt.preventDefault!
          files = Array.from(evt.dataTransfer.files)
          if @_.accept =>
            re = new RegExp("\." + @_.accept.split(',').join(\|) + "$")
            files = files.filter -> !!re.exec(it.name)
          @set files
        dragover: drop: ({evt}) -> evt.preventDefault!
      init: loader: ({node}) ~> if ldloader? => @_.loader = new ldloader root: node
      handler:
        input: ({node}) ~>
          if @_.accept => node.setAttribute \accept, @_.accept
          else node.removeAttribute \accept
        file:
          list: ~> @_.files or []
          view:
            action: click:
              delete: ({ctx}) ~>
                if !~(idx = @_.files.indexOf(ctx)) => return
                @_.files.splice idx, 1
                @_.view.render \file
            text:
              name: ({ctx}) -> ctx.file.name
              size: ({ctx}) -> uploadr.utils.parse-size ctx.file.size
              modifiedtime: ({ctx}) -> uploadr.utils.parse-date ctx.file.lastModified
            handler:
              thumb: ({node,ctx}) ->
                if node.nodeName.toLowerCase! == \img => node.setAttribute \src, ctx.thumb
                else node.style.backgroundImage = "url(#{ctx.thumb})"
  set: (o) ->
    @fire \preview:loading
    if @_.loader => @_.loader.on!
    [fobjs, files] = [[], if Array.isArray(o) => o else if o.length => Array.from(o) else [o]]
    iterate = ~>
      if !(file = files.splice(0,1).0) => return Promise.resolve fobjs
      p = new Promise (res, rej) ->
        img = new Image!
        img.onerror = ->
          fobjs.push f = {thumb: uploadr.assets.thumbholder, file}
          res f
        img.onload = ->
          [w, h] = [img.width, img.height]
          if w > 400 => [w, h] = [400, h * 400/w]
          if h > 400 => [w, h] = [w * 400/h, 400]
          c1 = document.createElement(\canvas) <<< width: w, height: h
          c1.getContext(\2d).drawImage img, 0, 0, w, h
          (blob) <- c1.toBlob _
          fobjs.push f = {thumb: URL.createObjectURL(blob), file}
          res f
        img.src = URL.createObjectURL(file)
      (fobj) <~ p.then _
      @_.[]files.push fobj
      @_.view.render!
      return iterate!
    (ret) <~ iterate!then _
    @_.view.render!
    if @_.loader => @_.loader.off!
    @fire \preview:loaded
    @fire \file:chosen, @_.files
    return ret
  get: -> @_.files
  clear: -> @_.files.splice(0); @_.view.render!
  progress: (v) ->
    if !(n = v.item?node) => return
    if !(p = ld$.find n, '[ld=progress]' .0) => return
    p.style.width = "#{(v.percent * 100)}%"
    if v.percent < 1 => return
    <~ debounce 500 .then _
    if n.parentNode => n.parentNode.removeChild n
    if ~(i = @_.files.indexOf v.item) => @_.files.splice i, 1
  upload: ->
    uploadr.ext[@_.opt.provider.host] {
      files: @_.files
      progress: ~> @progress.call @, arguments
      opt: @_.opt.provider.config
    }
      .then ~>
        @fire \upload:done, it
        return it
      .catch ~>
        @fire \upload:fail, it
        Promise.reject it


uploadr.viewer = (opt) ->
  @_ =
    evthdr: {}, files: [], running: false
    root: if typeof(opt.root) == \string => document.querySelector(opt.root) else opt.root
  if !@_.root => console.warn "[uploadr] warning: no node found for root ", opt.root
  @_.view = new ldview do
    root: @_.root
    action: click: load: ~> @fetch!
    init: loader: ({node}) ~> if ldloader? => @_.loader = new ldloader root: node
    handler:
      file:
        list: ~> @_.files or []
        key: -> it._id
        view:
          action: click: "@": ({ctx}) ~> @fire \file:chosen, ctx
          text:
            name: ({ctx}) -> ctx.name or 'unnamed'
            size: ({ctx}) -> uploadr.utils.parse-size ctx.size
            modifiedtime: ({ctx}) -> uploadr.utils.parse-date ctx.lastModified
          handler:
            thumb: ({node, ctx, local}) -> 
              if node.dataset.src == ctx.url => return
              if node.nodeName.toLowerCase! == \img => node.setAttribute \src, ctx.thumb
              else node.style.backgroundImage = "url(#{ctx.thumb})"
              node.dataset.src = ctx.url
  @_.page = if opt.page instanceof paginate => opt.page else new paginate(opt.page or {})
  @_.page.on \fetch, ~>
    # @loadingio/paginate always fire fetch even if empty or finish, and is before them.
    # if this is not the case, we may have to check if _.running is still on here.
    files = it.map -> it <<< {_id: Math.random!toString(36)substring(2)}
    ps = Promise.all files.map (file) ~> new Promise (res, rej) ~>
      img = new Image!
      img.onerror= -> file.thumb = uploadr.assets.thumbholder; res!
      img.onload = -> file.thumb = file.url; res!
      img.src = file.url
    <~ ps.then _
    <~ debounce 2000 .then _
    @_.files ++= files
    @_.view.render!
    if @_.loader => @_.loader.off!
    @_.running = false
    @fire \fetch:fetched, files
  @_.page.on \finish, ~> @_.running = false; @fire \fetch:end
  @_.page.on \empty, ~> @_.running = false; @fire \fetch:empty
  @

uploadr.viewer.prototype = Object.create(Object.prototype) <<< do
  on: (n, cb) -> (if Array.isArray(n) => n else [n]).map (n) ~> @_.evthdr.[][n].push cb
  fire: (n, ...v) -> for cb in (@_.evthdr[n] or []) => cb.apply @, v
  fetch: ->
    if @_.running => return
    @_.loader.on!
    @_.running = true
    @_.page.fetch!
  reset: ->
    @_.page.reset!
    @_.files = []
    @_.view.render!

if module? => module.exports = uploadr
else if window? => window.uploadr = uploadr
