(->
  #dep: ldpage, ldview
  #opt: 
  #  root
  #  page

  window.{}uploadr.viewer = viewer = (opt) ->
    @root = if typeof(opt.root) == \string => ld$.find(opt.root,0) else opt.root
    @evt-handler = {}
    @lc = {}
    @images = lc.images = []
    @view = view = new ldView do
      root: @root
      action: click: do
        list: ({node, evt}) ~>
          img = ld$.find node, 'img', 0
          src = img.getAttribute(\src)
          @fire \choose, {src}
      handler: do
        item: do
          list: -> lc.images or []
          handle: ({node, data}) ->
            img = ld$.find node, \img, 0
            div = ld$.find node, \div, 0
            if img.getAttribute(\src) == data.data => return
            node.style.display = \none
            node.classList.add \ld, \ld-float-btt-in
            img.onload = -> node.style.display = \block
            img.setAttribute \src, data.data
            div.style.backgroundImage = "url(#{data.data})"
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
