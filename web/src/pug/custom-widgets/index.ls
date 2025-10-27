view = new ldview do
  root: document.body
  init:
    uploadr: ({node}) ->
      up = new uploadr root: node, provider: host: \native, config: route: \/api/uploadr/native
      <- up.init!then _
    "uploadr-viewer": ({node}) ->
      up = new uploadr.viewer do
        root: node
        page:
          host: null
          fetch-on-scroll: true
          limit: 9
          boundary: 100
          fetch: -> new Promise (res, rej) ~>
            opt = {type: \json, json: {offset: @offset}}
            ld$.fetch "/api/uploadr/native/list", {method: \POST}, opt
              .then (r=[]) ->
                console.log r
                res r.map (f) ->
                  url: f.url
                  size: f.size
                  name: f.name
                  lastModified: f.createdtime
