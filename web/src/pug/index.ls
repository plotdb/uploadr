<-(->it!) _

i18ncfg = lng: \zh-TW

<- i18next.init(i18ncfg).then _
lc = {files: []}
ldcv = {}
inline = {}
widget = {}
panel = tab: \default

page-cfg = (host) -> 
  host: host
  fetch-on-scroll: true
  limit: 10
  boundary: 100
  fetch: -> new Promise (res, rej) ~>
    if @offset > 9 => return res []
    res [1,2,3,4,5,6,7,8,9,10].map (idx) ->
      if idx == 10 =>
        return {
          url: "/assets/img/sample/10.pdf"
          size: Math.round(Math.random! * (1048576 * 1024))
          name: "sample-file-name" + "#{Math.floor(Math.random!*10000)}".padStart(4, "0") + ".pdf"
          lastModified: Date.now! - Math.round(Math.random! * 1000 * 1440 * 365)
        }
      else
        return {
          url: "/assets/img/sample/#{idx}.jpg"
          size: Math.round(Math.random! * (1048576 * 1024))
          name: "DSC_" + "#{Math.floor(Math.random!*10000)}".padStart(4, "0") + ".jpg"
          lastModified: Date.now! - Math.round(Math.random! * 1000 * 1440 * 365)
        }

providers = do
  native: host: \native, config: {route: \/api/uploadr/native}
  imgbb: host: \imgbb, config: {key: "97902907ac92c25e4c54b8d0b4c6eeac"}
  gcs: host: \gcs, config: {
    route: \/api/uploadr/gcs
    bucket: "plotdb-playground-test"
    domain: "https://storage.googleapis.com"
  }

view = new ldview do
  root: document.body
  init:
    inline: ({node}) ->
      base = node.querySelector('[ld-scope]')
      name = base.getAttribute \ld-scope
      inline[name] = node
      ret = if /viewer/.exec(name) => new uploadr.viewer root: base, page: page-cfg(base), i18n: i18next
      else new uploadr.uploader root: base, provider: providers.native, accept: '', i18n: i18next
      ret.i18n!
      ret.on \file:chosen, (obj) -> console.log "choose: ", obj
      widget{}inline[name] = ret
    ldcv: ({node}) ->
      base = node.querySelector('[ld-scope]')
      name = base.getAttribute \ld-scope
      ldcv[name] = new ldcover root: node
      ret = if /viewer/.exec(name) => new uploadr.viewer root: base, page: page-cfg(base), i18n: i18next
      else new uploadr.uploader root: base, provider: providers.native, i18n: i18next
      ret.i18n!
      (({ret, ldcv}) ->
        (obj) <- ret.on \file:chosen, _
        console.log "choose: ", obj
        ldcv.set obj
      )({ret, ldcv: ldcv[name]})
      widget{}ldcv[name] = ret
  handler:
    panel: ({node}) -> node.classList.toggle \d-none, panel.tab != node.dataset.name
  action: click:
    lng: ({node}) ->
      i18next.changeLanguage node.dataset.lng
      for type,obj of widget => for k,v of obj => v.i18n!
    "toggle-ldcv": ({node}) ->
      name = node.dataset.name
      widget{}ldcv[name].fetch!
      ldcv[name].toggle!
    "toggle-inline": ({node}) ->
      name = node.dataset.name
      for k,v of inline => v.classList.toggle \d-none, true
      panel.tab = name
      view.render \panel
