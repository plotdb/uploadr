require! <[@plotdb/suuid @google-cloud/storage]>

retry = (count, cb) -> cb!catch -> if count > 0 => retry((count - 1), cb) else return Promise.reject(it)

provider-gcs = (opt={}) ->
  @opt = {} <<< opt
  @config = opt.config or {}
  @adopt = opt.adopt or {upload: (->Promise.resolve!), download: (->Promise.resolve!)}
  @bucket = @config.bucket
  @gcs = new storage.Storage @config
  @

provider-gcs.prototype = Object.create(Object.prototype) <<< do
  /**
    * get a link to upload file.
    * @param {String} id - optional. unique id for this file
        - use a randomly generated suuid if omitted
        - overwrite the old file if id was used before.
    * @param {String} name - optional. 
    * @return {Promise} - resolve url for uploading
    */
  upload: (req, opt = {}) ->
    [name,id] = [(opt.name or 'unnamed'), opt.id]
    Promise.resolve!
      .then ~>
        if !id => retry 10, ~> @adopt.upload req, {name, id: (id = suuid!)} .then -> {name, id}
        else @adopt.upload req, {name, id} .then -> {name, id}
      .then ({id}) ~>
        @get-url {id, action: \write}
          .then (signed-url) -> {id, signed-url}

  /**
    * get download link for a file corresponding to a given id
    * @param {Object} obj - {id, expires}
        - `id`: file id. this id is generated when upload.
        - `expires`: unix eopch time to expire this link after generated.
    * @return {Promise} - resolve url for downloading
    */
  download: (req, opt = {}) ->
    @adopt.download req, opt{id}
    @get-url {action: \read} <<< opt{id, expires}
      .then (signed-url) -> {signed-url, id}

  /**
    * internal api
    */
  get-url: (opt = {}) ->
    if !opt.id => return Promise.reject!
    payload = ({expires: (Date.now! + 2 * 60 * 1000), action: \read, version: \v4} <<< opt)
    @gcs
      .bucket @bucket
      .file opt.id
      .getSignedUrl payload{expires, action, version}
      .then -> it.0

  get-upload-router: -> (req, res, next) ~>
    Promise.all([0 til (req.{}body.count or 1)].map ~> @upload req, {}).then -> res.send it
  get-download-router: -> (req, res, next) ~> @download req, {} .then -> res.status(302).redirect it.signed-url


module.exports = provider-gcs
