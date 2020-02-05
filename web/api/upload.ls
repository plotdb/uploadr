require! <[fs fs-extra path crypto]>

# Image Format: Beginning Bytes
# TIF : SU : 49 49
#     : TU : 4D 4D
# BMP : Qk : 42 4D
# JPG : /9 : FF D8 FF EO ( Starting 2 Byte will always be same)
# PNG : iV : 89 50 4E 47
# GIF : R0 : 47 49 46 38
# SVG :    : "<?xml" or "<svg", with possibly space ahead.
#     : PD : 3C 3F  "<?"
#     : PH : 3C 73  "<s"
#     : ID : 20 3C  " <"
#     : IC : 20 20  "  "

typemap = do
  base64: {
    "Qk": \bmp, "/9": \jpg, "iV": \png, "R0": \gif,
    "SU": \tif, "TU": \tif
    "ID": \svg, "PD": \svg, "PH": \svg, "IC": \svg
  }
  byte: {
    16973: \bmp, 65496: \jpg, 35152: \png, 18249: \gif
    18761: \tif, 19789: \tif
    15423: \svg, 15475: \svg, 8252: \svg, 8224: \svg
  }

imgtype = (d) ->
  if typeof(d) == \string => typemap.base64[d.substring(0,2)]
  else if (d instanceof Buffer) => typemap.byte[d.0 * 0x100 + d.1]
  else return null

archive = ({buf}) -> new Promise (res, rej) ->
  md5 = crypto.createHash(\md5).update(buf).digest(\hex)
  t1 = md5.substring(0, 3)
  t2 = md5.substring(3, 6)
  dir = path.join(\assets, t1, t2)
  des = path.join(dir, md5)
  <- fs.exists des, _
  if it => res {url: des, md5}
  <- fs-extra.ensure-dir dir, _
  <- fs.write-file des, buf, _
  res {path: des, md5}

handler = (req, res) ->
  if !(req and req.files and req.files.image) => return 
  path = req.files.image.path
  archive {buf: fs.read-file(req.files.image.path)}
    .then -> res.send it

# sample code
# archive {buf: fs.read-file-sync('support.png')}
#   .then -> console.log it

module.exports = {handler, archive, imgtype}
