require! <[suuid]>

retry = (count, cb) -> cb!catch -> if count > 0 => retry((count - 1), cb) else return Promise.reject(it)

provider-gcs = (opt={}) ->
  @opt = {} <<< opt
  @config = opt.config
  @adopt = opt.adopt or {upload: (->Promise.resolve!), download: (->Promise.resolve!)}
  @bucket = opt.bucket
  @

provider-gcs = Object.create(Object.prototype) <<< do
  set-config: (o={}) -> @config = o
  /**
    * get a link to upload file.
    * @param {String} id - optional. unique id for this file
        - use a randomly generated suuid if omitted
        - overwrite the old file if id was used before.
    * @param {String} name - optional. 
    * @return {Promise} - resolve url for uploading
    */
  upload: (req, opt = {}) ->
    name = opt.name or 'unnamed'
    Promise.resolve!
      .then ~>
        if !opt.id => retry 10, -> @adopt.upload req, {name, id: suuid!}
        else @adopt.upload req, {name, id}
      .then ({id}) ~> @get-url {id, action: \write}

  /**
    * get download link for a file corresponding to a given id
    * @param {Object} obj - {id, expires}
        - `id`: file id. this id is generated when upload.
        - `expires`: elapsed time (in ms) to expire this link after generated.
    * @return {Promise} - resolve url for downloading
    */
  download: (req, opt = {}) ->
    @adopt.download req, opt{id}
    @get-url {action: \read} <<< opt{id, expires}

  /**
    * internal api
    */
  get-url: (opt = {}) ->
    if !opt.id => return Promise.reject!
    payload = {expires: (Date.now! + 2 * 60 * 1000), action: \read, version: \v4} <<< opt{expires, action}
    gcs
      .bucket @bucket
      .file opt.id
      .getSignedUrl payload
      .then -> it.0

  get-upload-router: -> (req, res, next) ~> @upload req, {}
  get-download-router: -> (req, res, next) ~> @download req, {}


module.exports = provider-gcs
