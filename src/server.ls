require! <[fs fs-extra path crypto imgtype]>

uploadr = (opt = {}) ->
  folder = opt.folder or \uploads
  rooturl = opt.url or folder

  # input: one of following ( name is optional in both case )
  #  - {path, name, target}
  #  - {buf, name}
  # return:
  #  - { name, url, id } if succeed
  #  - { name } otherwise
  archive = (obj = {}) -> new Promise (res, rej) ->
    name = obj.name or ''
    promise = (
      if obj.buf => Promise.resolve(obj.buf)
      else new Promise (res, rej) -> fs.read-file obj.path, (e, buf) -> if e => rej e else res buf
    )
    promise
      .then (buf) ->
        md5 = crypto.createHash(\md5).update(buf).digest(\hex)
        t1 = md5.substring(0, 3)
        t2 = md5.substring(3, 6)
        dir = path.join(folder, t1, t2)
        imgtype(buf)
          .then ({ext}) ->
            des = if target => path.join(dir, target, md5) else path.join(dir, md5)
            url = if target => path.join(rooturl, target, t1, t2, md5) else path.join(rooturl, t1, t2, md5)
            if ext => [des,url] = ["#des.#ext", "#url.#ext"]
            <- fs.exists des, _
            if it => res {url, name, id: md5}
            (e, b) <- fs-extra.ensure-dir dir, _
            if e => return res {name}
            (e, b) <- fs.write-file des, buf, _
            if e => return res {name}
            res {url, name, id: md5}
      .catch -> res {name}

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
