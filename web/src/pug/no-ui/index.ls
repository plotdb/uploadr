list = []
view = new ldview do
  root: document.body
  action:
    change: upload: ({node}) ->
      # Core Upload Mechanism Here.
      (ret) <- uploadr.ext.native {
        files: Array.from(node.files).map (file) -> {file}
        progress: ({percent, val, len}) -> console.log percent, val, len
        opt: route: \/api/uploadr/native # this depends on how backend is implemented. check `web/server.ls`
      } .then _
      ret = ret.map -> {url: it.url, name: it.name, key: Math.random!toString(36)substring(2)}
      list.push(...ret)
      view.render \list
  handler:
    list:
      list: -> list
      key: -> it.key
      view:
        handler: img: ({node, ctx}) -> node.src = ctx.url
        text: name: ({ctx}) -> ctx.name or 'untitled'
