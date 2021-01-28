# @plotdb/uploadr

File upload library, including:

 - [client side](#client-side) - upload widget + file list viewer ( with pug template )
 - [server side](#server-side) - API endpoint for file storing with Express



## Client Side

In client side, we will need widgets for both file uploading and file choosing. Both parts share the same basic usage as described below; other parts will be covered separatedly in following sections.


### Installation

    npm install --save @loadingio/ldpage @loadingio/debounce.js ldview ldloader proxise @plotdb/uploadr


### Usage

include required js / css files and related dependencies ( `@loadingio/ldpage`, `@loadingio/debounce.js`, `proxise`, `ldloader` and `ldview` ):

    <link rel="stylesheet" type="text/css" href="@plotdb/uploadr/uploadr.css"/>
    <script src="@loadingio/ldpage/ldpage.min.js"></script>
    <script src="@loadingio/debounce.js/debounce.min.js"></script>
    <script src="proxise/proxise.min.js"></script>
    <script src="ldview/ldview.min.js"></script>
    <script src="@plotdb/uploadr/uploadr.min.js"></script>


### Uploader

To upload files, create an `uploadr` object through its constructor:

    var up = new uploadr({ ... })

with following options:

 - `root`: root element ( or selector ) of the upload widget.
    - For DOM customization, see Customization section below.
 - `provider`: object for provider information. See Providers section below.
   - if omitted, fallback to `{route: '/d/uploadr', host: 'native'}`


For root element - if you use Pug, you can use the `uploadr` mixin available in `uploadr.pug` to create the DOM needed:

    include <path-to-uploadr.pug>
    div.some-tag-to-wrap-uploader: +uploadr("scope-name")



#### API

`uploadr` object provides following APIs:

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


#### Providers

`@plotdb/uploadr` supports uploading to different kind of file hosting services. use `provider` to choose between the providers available as below:

##### Native

upload files to local api ( provided also by `@plotdb/uploadr` )

    { host: "native", route: "<path-to-api-endpoint>" }


##### ImgBB

upload images to ImgBB via following provider config:

    { host: "imgbb", key: "api-key-to-imgbb" }


##### Other providers

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


#### Widget Customization

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


### Viewer

To view and choose files, create an `uploadr.choose` object

    uploadr.viewer({ ... });

with following options:

 - `root`: object or selector for the root element of viewer DOM.
 - `page`: a `ldPage` object ( or options for constructor ) for loading file lists.
   - items in returned list from fetch should contain at least a member `url` for showing the url of the image.


You can prepare the root element with Pug mixin `uploadr-viewer` after including required `uploadr.pug`:

    include <path-to-uploadr.pug>
    div.some-tag-to-wrap-uploader-viewer: +uploadr-viewer("scope-name")


#### API

`uploadr.viewer` object provides following APIs:

 - `on(name, cb)`: listen to event `name` with callback function `cb`. Following events are available:
   - `fetch`: when fetching new items. list of items passed as parameter.
   - `finish`: when there is no new item available.
   - `empty`: when list is empty.
   - `choose`: when an item is chosen. `cb` called with `{url}` object as parameter.
 - `fetch`: intialiate a new fetch
 - `reset`: reset pager and list.


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
