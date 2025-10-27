<-(.apply {}) _

manager = new block.manager registry: ({ns,name,version,path,type}) ->
  path = path or if type == \block => \index.html else if type == \js => \index.js else \index.css
  "/assets/lib/#name/#{version or 'dev'}/#{path}"

page-cfg = (host) -> 
  host: host
  fetch-on-scroll: true
  limit: 9
  boundary: 100
  fetch: -> new Promise (res, rej) ->
    res [1,2,3,4,5,6,7,8,9].map ->
      {
        url: "/assets/img/sample/#{it}.jpg"
        size: Math.round(Math.random! * (1048576 * 1024))
        name: "DSC_" + "#{Math.floor(Math.random!*10000)}".padStart(4, "0") + ".jpg"
        lastModified: Date.now! - Math.round(Math.random! * 1000 * 1440 * 365)
      }

view = new ldview do
  root: document.body

Promise.resolve!
  .then ->
    bid = name: \@plotdb/uploadr
    opt = root: view.get(\uploader), data: provider: host: \native, config: route: \/api/uploadr/native
    manager.from bid, opt
  .then ->
    bid = name: \@plotdb/uploadr, path: 'viewer/index.html'
    opt = root: view.get(\viewer), data: page: page-cfg!
    manager.from bid, opt
  .then ->
    console.log "initalized."
