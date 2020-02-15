(->
  #dep: ldpage, ldview
  #opt: 
  #  root
  #  page

  window.{}uploadr.viewer = viewer = (opt) ->
    @root = if typeof(opt.root) == \string => ld$.find(opt.root,0) else opt.root
    if !@root => console.warn "[uploadr] warning: no node found for root ", opt.root
    @evt-handler = {}
    @lc = lc = {}
    @images = lc.images = []
    @view = view = new ldView do
      root: @root
      action: click: do
        list: ({node, evt}) ~>
          if !(n = ld$.parent(evt.target, '[data-src]', node)) => return
          src = n.getAttribute(\data-src)
          @fire \choose, {url: src}
      handler: do
        item: do
          list: -> lc.images or []
          handle: ({node, data}) ->
            img = ld$.find node, \img, 0
            div = ld$.find node, \div, 0
            if img.getAttribute(\src) == data.url => return
            node.setAttribute \data-src, data.url
            node.style.display = \none
            img.onload = -> node.style.display = \block
            img.setAttribute \src, data.url
            div.style.backgroundImage = "url(#{data.url})"
    @page = new ldPage opt.page
    @page.init!
    @page.on \fetch, ->
      lc.images ++= it
      view.render!
    @

  viewer.prototype = Object.create(Object.prototype) <<< do
    on: (n, cb) -> @evt-handler.[][n].push cb
    fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
)!
