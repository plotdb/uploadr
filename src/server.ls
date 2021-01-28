require! <[fs fs-extra path crypto imgtype]>

uploadr = (opt = {}) ->
  folder = opt.folder or \uploads
  rooturl = opt.url or folder
  log = opt.log or (-> console.log it)

  # input: one of following ( name is optional in both case )
  #  - {path, name, target}
  #    - target: specific subfolder, if needed
  #  - {buf, name}
  # return:
  #  - { name, url, id } if succeed
  #  - { name } otherwise
  archive = (obj = {}) -> new Promise (res, rej) ->
    [name, target] = [(obj.name or ''), (obj.target or 'main')]
    promise = (
      if obj.buf => Promise.resolve(obj.buf)
      else new Promise (res, rej) -> fs.read-file obj.path, (e, buf) -> if e => rej e else res buf
    )
    promise
      .then (buf) ->
        # use sha256(buf) + buf.length instead of md5(buf) for lower chance of collision
        hk = crypto.createHash('sha256').update(buf).digest('hex') + "-" + (buf.length).toString(36)
        t1 = hk.substring(0, 5)
        t2 = hk.substring(5, 10)
        hk = hk.substring(10)
        dir = path.join(folder, target, t1, t2)
        imgtype(buf)
          .then ({ext}) ->
            des = path.join(dir, hk)
            url = path.join(rooturl, target, t1, t2, hk)
            if ext => [des,url] = ["#des.#ext", "#url.#ext"]
            <- fs.exists des, _
            if it => res {url, name, id: hk}
            (e, b) <- fs-extra.ensure-dir dir, _
            if e => throw e
            (e, b) <- fs.write-file des, buf, _
            if e => throw e
            res {url, name, id: hk}
      .catch (err) ->
        log err
        res {name}

  # accept req.files and req.fields. formidable can help us generating these.
  # we will leave the multipart parsing to user.
  # for example:
  #   app.post \/d/uploadr, express-formidable({multiples:true}), uploadr.route
  route = (req, res, next) ->
    handler({opt: {}, req, res})
      .then -> res.send it
      .catch (err) ->
        if opt.catch => opt.catch(err, req, res, next);
        else
          console.log err
          res.status(500).send!

  handler = (o = {}) ->
    {req, res} = o
    cfg = o.opt or {}
    files = (req.files or {}).file
    files = if !files => [] else if Array.isArray(files) => files else [files]
    if cfg and cfg.target => files = files.map -> it <<< {target: cfg.target}
    promises = files
      .map archive
      .map ->
        it.then (ret) ->
          (if opt.adopt => opt.adopt(req, ret) else Promise.resolve!)
            .then -> return ret
    Promise.all promises

  return { handler, route, archive }

module.exports = uploadr
