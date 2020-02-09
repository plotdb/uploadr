require! <[fs fs-extra path crypto imgtype]>

uploadr = (opt = {}) ->
  folder = opt.folder or \uploads
  rooturl = opt.url or folder

  # input: one of following ( name is optional in both case )
  #  - {path, name}
  #  - {buf, name}
  # return:
  #  - { name, url, id } if succeed
  #  - { name } otherwise
  archive = (obj = {}) ->
    p = new Promise (res, rej) ->
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
              des = path.join(dir, md5)
              url = path.join(rooturl, t1, t2, md5)
              if ext => [des,url] = ["#des.#ext", "#url.#ext"]
              <- fs.exists des, _
              if it => res {url, name, id: md5}
              (e, b) <- fs-extra.ensure-dir dir, _
              if e => return res {name}
              (e, b) <- fs.write-file des, buf, _
              if e => return res {name}
              res {url, name, id: md5}
        .catch -> res {name}
    p.then (ret) ->
      (if opt.adopt => opt.adopt(ret) else Promise.resolve!)
        .then -> return ret

  # accept req.files and req.fields. formidable can help us generating these.
  # we will leave the multipart parsing to user.
  # for example:
  #   app.post \/d/uploadr, express-formidable({multiples:true}), uploadr.route
  route = (req, res) ->
    files = req.files.file
    files = if !files => [] else if Array.isArray(files) => files else [files]
    Promise.all files.map archive
      .then -> res.send it
      .catch -> console.log it; res.status(500).send!
  return { route, archive }

module.exports = uploadr
