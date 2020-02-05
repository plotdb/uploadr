(->
  ldUpload = (opt) ->
    local = {}
    ldcv = new ldCover root: '.ldcv'
    ldld = new ldLoader root: '.ldcv .ld-over-full-inverse'
    ui = (opt) ->
      {empty,multiple} = {empty: true, multiple: false} <<< opt
      <[list add]>.map -> view.get(it).classList.toggle \d-none, empty
      <[upload]>.map -> view.get(it).classList.toggle \d-none, !empty
      <[single]>.map -> view.get(it).classList.toggle \d-none, multiple
      <[multiple]>.map -> view.get(it).classList.toggle \d-none, !multiple

    show = (list) ->
      local.images = (list or []).filter -> it and !(it instanceof ldError)
      view3.render!

    view3 = new ldView root: '[ld-scope=gallery]', handler: do
      image: do
        list: -> local.images
        handle: ({node, data}) ->
          view = new ldView root: node, handler: do
            thumb: ({node}) ->
              node.style.backgroundImage = "url(#{data.url})"
            name: ({node}) ->
              node.textContent = data.id
              node.setAttribute \href, data.url

    uploader = do
      dummy: ({fd}) -> {url: "https://i.ibb.co/frf90x6/only-support.png", id: "VMRxBqn"}
      imgbb: ({fd}) ->
        ld$.fetch(
          'https://api.imgbb.com/1/upload?key=97902907ac92c25e4c54b8d0b4c6eeac',
          {method: \POST, body: fd}
          {type: \json}
        )
          .then ->
            if !(it and it.data and it.status == 200) => return Promise.reject(it)
            {url: it.data.display_url, id: it.data.id, raw: it.data}
          .catch (e) -> return new ldError(e)

    upload-file = (files) ->
      ldld.on!
      promises = files.map (file) -> 
        fd = new FormData!
        fd.append \image, file.file
        uploader.imgbb {fd}
        #uploader.dummy {fd}
      Promise.all(promises) .finally -> ldld.on!

    view2 = new ldView root: document, handler: do
      files:
        list: -> local.files or []
        handle: ({node, data}) ->
          ld$.find(node, '.btn',0).addEventListener \click ->
            node.parentNode.removeChild node
            idx = local.files.indexOf(data)
            if idx >= 0 => local.files.splice(idx, 1)
            if local.files.length == 0 => ui empty: true, multiple: false 
          view = new ldView root: node, handler: do
            name: ({node}) -> node.textContent = data.file.name
            size: ({node}) -> node.textContent = "#{Math.round(data.file.size / 1024)}KB"
            thumb: ({node}) -> node.style.backgroundImage = "url(#{data.result})"

    view = new ldView root: document, handler: do
      input: ({node}) ->
        local.ldf = ldf = new ldFile root: node, type: \dataurl, force-encoding: \utf-8
        ldf.on \load, (files) ~>
          preview = view.get(\preview)
          promises = files.map (file) -> new Promise (res, rej) ->
            img = new Image
            img.onload = ->
              preview.style
                ..backgroundImage = "url(#{files.0.result})"
                ..width = "#{img.width}px"
                ..height = "#{img.height}px"
              res {} <<< img{width, height} <<< file
            img.src = file.result
          Promise.all(promises).then ->
            local.files = files
            ui empty: !local.files.length, multiple: (local.files.length > 1)
            view2.render!
      cancel: ({node}) ->
        node.addEventListener \click, ->
          if !local.files => ldcv.toggle!; return
          local.files = null
          ui empty: true, multiple: false
      add: ({node}) -> node.addEventListener \click, ->
        upload-file local.files .then -> ldcv.set it
      upload: ->
      preview: ->

      toggle: ({node}) -> node.addEventListener \click, ->
        ldcv.get!
          .then -> show it
          .catch ->

  ldUpload.prototype = Object.create(Object.prototype) <<< {}
  window.ldUpload = ldUpload
  ldUpload!
)!
