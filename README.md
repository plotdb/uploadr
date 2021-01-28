# @plotdb/uploadr

File upload widget base on Loading-ui. Provide following functionalities:

 * Customizable UI widget for
   - upload
   - upload progress
   - view ( image list )
 * backend adopter for express
   -


## Client Side

In client side, we will need widgets for both file uploading and file choosing.


### Installation

    npm install --save @loadingio/ldpage @loadingio/debounce.js ldview ldloader proxise @plotdb/uploadr


### Usage

include required js / css files and related dependencies ( `@loadingio/ldpage`, `@loadingio/debounce.js`, `proxise`, `ldloader` and `ldview` ), then create an `uploadr` object through its constructor:


    <link rel="stylesheet" type="text/css" href="@plotdb/uploadr/uploadr.css"/>
    <script src="@loadingio/ldpage/ldpage.min.js"></script>
    <script src="@loadingio/debounce.js/debounce.min.js"></script>
    <script src="proxise/proxise.min.js"></script>
    <script src="ldview/ldview.min.js"></script>
    <script src="@plotdb/uploadr/uploadr.min.js"></script>
    <script>
    var up = new uploadr({ ... })
    </script>

with following options:

 - `root`: root element ( or selector ) of the upload widget.
    - For DOM customization, see Customization section below.
 - `provider`: object for provider information. See Providers section below.
   - if omitted, fallback to `{route: '/d/uploadr', host: 'native'}`


For root element - if you use Pug, you can use the `uploadr-upload` mixin available in `uploadr.pug` to create the DOM needed:

    include <path-to-uploadr.pug>
    div.some-tag-to-wrap-uploader: +uploadr-upload()



### API

`uploadr` object provides following API:

  - `init` - initialize uploadr. constructor will init uploadr automatically.
  - `upload` - upload chosen files.
  - `clear` - clear chosen files.
  - `get` - get chosen files.
  - `on(name, cb)` - listen to `name` event with `cb` callback. Following events are available:
    - `preview.done`
    - `preview.loading`
    - `file.chosen`
    - `upload.done`
    - `upload.fail`


### Providers

`@plotdb/uploadr` supports uploading to different kind of file hosting services. use `provider` to choose between the providers available as below:

#### Native

upload files to local api ( provided also by `@plotdb/uploadr` )

    { host: "native", route: "<path-to-api-endpoint>" }


#### ImgBB

upload images to ImgBB via following provider config:

    { host: "imgbb", key: "api-key-to-imgbb" }


#### Other providers

You can also add provider for services you'd like to use by simply adding a function in `uploadr.ext`:

    uploadr.ext.myService = function ({files, progress, opt}) { ... }


It's you job to implement the upload mechanism with following parameters and requirements:

 - Parameters
   - `files`: Array of `{thumb, file}` object with:
     - `thumb`: thumbnail link ( blob url )
     - `file`: file object ( blob ) from input element to upload.
   - `progress({percent, val, len, item})`: function to be called when there are progress reported, with options:
     - `percent`: percent of size uploaded
     - `val`: actual bytes uploaded
     - `len`: file size
     - `item`: object in `files` array that is making progress.
   - `opt`: the provider config object.
 - provider function should always return a Promise which resolves when upload is complete.


### Widget Customization

Uploadr client library uses [ldview](https://github.com/loadingio/ldview) for UI abstraction. If you design your own upload widget, simply add following `ld` names on corresponding elements.

 - `drop`: area for dropping files to choose them.
 - `file`: `ld-each` type name. preview of chosen files. with following nested `ld` names:
   - `thumb`: element for showing preview image. should also be an `<img>` tag.
   - `progress`: upload progress indicator
   - `size`: size of chosen file.
   - `delete`: file is un-chosen when element with `delete` name is clicked.
 - `input`: `input` element with `type='file'` attribute. For manually uploading with file picker dialog.
 - `upload`: upload chosen files to server when clicked.
 - `clear`: clear all files when clicked.
 - `loader`: a `running` class will be added to element(s) with this name.


upload widget:

js:

    uploadr({
      root: 'selector-to-my-upload-scope`
      progress: ->
      uploadr: { ... }
    })


pug:

    script(src="path-to-client.js")
    +scope("my-upload-scope")
      +uploadr-list
      +uploadr-upload
      div(ld="upload") ...

picker widget:

js:

    uploadr.viewer({
      root: 'selector-to-my-viewer-scope`
      page: (ldPage instnace)
    })

pug:
    script(src="path-to-viewer.js")
    +scope("my-viewer-scope")
      +uploadr-viewer


## Widget

uploadr client use ldView to implement the dynamics of frontend elements. UI elements has been implemented in the corresponding pug mixins, you can use following mixins to take advantage of them:

 * `uploadr-list` - list of chosen files ( ld-each=`file` )
 * `uploadr-viewer` - list of uploaded files for user to pick ( ld=`list` & ld-each=`item` )
 * `uploadr-upload` - upload widget including drag & drop area (ld=`drop`) and upload button (ld=`input`)

`upload` and `clear` is not supported in mixin but you can add them in your own UI.

To use `upload`, `clear` and `uploadr-list` and `uploadr-upload`, wrap them in a ld scope element:

    +scope("my-scope")
      +uploadr-upload
      +uploadr-list
      div(ld="upload")

`uploadr-viewer` is supported in standalone scope:

    +scope("my-another-scope")
      +uploadr-viewer


## Customization

Uploadr UI uses loading-ui and bootstrap, which might not be what you need. instead, you can implement your own UI without bootstrap and loading-ui. You will still need loading-ui's javascript since uploadr uses it.

To attach the dynamics with your own ui, use following `ld` names:

 * supported by viewer.js:
   * `list` - container of listed images for choosing.
   * `item` ( ld-each ) - should be inside `list`. an image element for user to pick.


## Configuration

* viewer
  - root: element / selector for the root element of uploadr ui.
  - page: option for constructing ldPage element. see ldPage for more information.
    - items in returned list from fetch should contain at least a member `url` for showing the url of the image.


## API

* uploadr
* viewer
  - on(name, cb) - listen to `name` event with `cb` callback.


## Events

* uploadr
* viewer
  - choose

----

## Server Side

To save files locally ( or after autheticated ), you will need a server side api.

### Usage: Save Locally

`uploadr().route` accept incoming request with files payload, and save them based on hashed id into specified location. Use `express-formidable` and `uploadr(...).route` to handle files:

    cfg = { uploadr: { ... }, formidable: {multiples: true} }
    app.post \/d/uploadr, express-formidable(cfg.formidable), uploadr(cfg.uploadr).route

sample configurations:

    cfg = do
      uploadr: {folder: 'static/assets/files', url: '/assets/files'}
      formidable: {multiples: true} # formidable configs. depends on your usage

### Configurations

config uploadr with `uploadr(opt)` where opt is an object with following members:

 - `folder`: fs path for saving all files.
 - `url`: url prefix ( relative or absolute ). if omitted, fallback to `folder`
 - `adopt: (req, {url, name, id})`: post process function after files are saved.
   - if provided, will be called for each file saved.
   - options:
     - `req`: express request object
     - `name`: name of the file
     - `url`: `url` for the file
     - `id`: `id` for the file
 - `catch: (err, req, res, next)`: Promise rejection handler.
   - if omitted, fallback to `res.status(505).send()` when exception occurs.
 - `log`: log function. if omitted, fallback to `console.log`.


### API

Following are the APIs exposed by `uploadr`:

 - `handler(req, res, next)`: process req.files and return promise, resolving url, id and name as array of objects.
 - `route(req, res, next)`: wrap handler as a route which pass data to res.send, or report 500 on error.
 - `archive(opt)`: function that takes care of files
   - input: one of following ( name is optional in both case )
     - {path, name}
     - {buf, name}
   - return:
     - { name, url, id } if succeed
     - { name } otherwise


## License

MIT
