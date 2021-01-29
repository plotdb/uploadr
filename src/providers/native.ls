require! <[fs fs-extra path crypto imgtype]>

provider-native = (opt = {}) ->
  @opt = opt
  @adopt = opt.adopt or {upload: (->Promise.resolve!), download: (->Promise.resolve!)}
  @folder = opt.folder or \uploads
  @rooturl = opt.url or folder
  @log = opt.log or (-> console.log it)
  @catch = opt.catch or null
  @

provider-native.prototype = Object.create(Object.prototype) <<< do
  /**
   * save upload files in local directory.
   * @param {Object} obj - information of the file to save, in `{buf, name}` or `{path, name, target}` format:
       - `path`: file path ( full path, including filename )
       - `name`: name for the file ( in remote system ). optional
       - `buf`: file content, as a Buffer objcet. `path` is omitted if `buf` is given.
       - `target`: concetp for either purpose, category. put in specific subfolder. default `main`.
   * @return {Promise} - resolving `{name,url,id}` if succeed, otherwise `{name}` only.
       - `name`: name for the file
       - `url`: url of the file from which we can access it
       - `id`: unique id for this file
   */
  archive: (obj={}) -> new Promise (res, rej) ~>
    [name, target] = [(obj.name or ''), (obj.target or 'main')]
    promise = (
      if obj.buf => Promise.resolve(obj.buf)
      else new Promise (res, rej) -> fs.read-file obj.path, (e, buf) -> if e => rej e else res buf
    )
    promise
      .then (buf) ~>
        # use sha256(buf) + buf.length instead of md5(buf) for lower chance of collision
        hk = crypto.createHash('sha256').update(buf).digest('hex') + "-" + (buf.length).toString(36)
        t1 = hk.substring(0, 5)
        t2 = hk.substring(5, 10)
        hk = hk.substring(10)
        dir = path.join(@folder, target, t1, t2)
        imgtype(buf)
          .then ({ext}) ~>
            des = path.join(dir, hk)
            url = path.join(@rooturl, target, t1, t2, hk)
            if ext => [des,url] = ["#des.#ext", "#url.#ext"]
            <- fs.exists des, _
            if it => res {url, name, id: hk}
            (e, b) <- fs-extra.ensure-dir dir, _
            if e => throw e
            (e, b) <- fs.write-file des, buf, _
            if e => throw e
            res {path: des, url, name, id: hk}
      .catch (err) ~>
        log err
        res {name}

  /**
   * accept req.files and req.fields to save files.
     User should use express-formidable to prepare those fields and multipart parsing.
     for example:
         app.post \/d/uploadr/native, express-formidable({multiples:true}), new uploadr.native!get-router!
   * @param {Request} req - express request object
   * @param {Response} res - express response object
   * @param {Function} next - express next function.
   * @return {Promise}
   */
  router: (req, res, next) ->
    @handler({opt: {}, req, res})
      .then -> res.send it
      .catch (err) ~>
        if @catch => @catch(err, req, res, next)
        else
          @log err
          res.status(500).send!

  /**
    * internal function to handle requests. 
    */
  handler: (o = {}) ->
    {req, res} = o
    cfg = o.opt or {}
    files = (req.files or {}).file
    files = if !files => [] else if Array.isArray(files) => files else [files]
    if cfg and cfg.target => files = files.map -> it <<< {target: cfg.target}
    Promise.all files .map ~> @archive(it).then((ret) ~> @adopt.upload(req, ret) .then -> ret)

  get-upload-router: -> (req, res, next) ~> @router req, res, next

module.exports = provider-native
