# @plotdb/uploadr

A file upload library for modern web apps.

 - [Client Side](#client-side): Upload widget, file list viewer ( with a Pug template ) and provider adapters.
 - [Server side](#server-side): API endpoint for file storage with Express


## Installation

Install @plotdb/uploadr via npm, along with its dependencies:

    npm install --save @plotdb/uploadr @loadingio/ldquery


and following dependencies for widgets, optionally only if you use builtin widgets:

    npm install --save @loadingio/paginate @loadingio/debounce.js ldview ldloader proxise


## Client Side

In a browser context, we need 2 parts:

 - uploader for a specific provider
 - widgets for both file uploading and file choosing

Before using, you need to include required files; for using without widgets, include main lib and @loadingio/ldquery:


    <script src="path/to/@loadingio/ldquery/index.min.js"></script>
    <script src="path/to/@plotdb/uploadr/index.min.js"></script>


and dependencies if you want to use with widgets:

    <link rel="stylesheet" type="text/css" href="@plotdb/uploadr/uploadr.css"/>
    <script src="path/to/@loadingio/ldquery/index.min.js"></script>
    <script src="path/to/@loadingio/paginate/index.min.js"></script>
    <script src="path/to/@loadingio/debounce.js/index.min.js"></script>
    <script src="path/to/proxise/index.min.js"></script>
    <script src="path/to/ldview/index.min.js"></script>
    <script src="path/to/@plotdb/uploadr/index.min.js"></script>


additionally, include a specific provider. For example, `native` provider:

    <script src="@plotdb/uploadr/providers/native/index.min.js"></script>

For more information about provider, check the [Provider section](#providers) below.


### Usage, without widgets

Upload with a specific provider is simple. For example, upload with the native provider:

    uploadr.ext.native({
      files: [{file: blobToUpload}, ...]
      progress: function ({percent, val, len, item}) { ... }
      opt: {route: "path-to-your-native-provider-api-endpoint"}
    })

While @plotdb/uploadr provides upload widgets, in this case no UI is involved. If this is all what you need and don't need uploadr widgets, you can skip to the [Providers section](#providers) below. Check `no-ui/` page under demo site for a working example of uploading without widgets.


### Usage, with widgets

Uploadr widget provides a headless controller based on ldview so you can design your own widgets, yet a pair of Pug mixin as a predefined HTML template within a pug file are also available for you to use. Additionally, `@plotdb/block` modules corresponding to viewer and uploader are also available.

To upload files via the uploadr viewer, create an `uploadr.uploader` object through its constructor:

    var up = new uploadr.uploader({ ... })

with the following options:

 - `root`: root element ( or selector ) of the upload widget.
    - To customize widget, see [Widget Customization section](#widget-customization) below.
 - `provider`: object for provider information
   - For detailed usage, see [Providers section](#providers) below.
   - if omitted, falls back to `{config: {route: '/api/uploadr'}, host: 'native'}`


For root element - if you use Pug, you can use the `uploadr-uploader` mixin available in `uploadr.pug` to create the DOM needed:

    include <path-to-uploadr.pug>
    div.some-tag-to-wrap-uploader: +uploadr-uploader("scope-name")

Or, create a `uploadr.viewer` object to browse and choose files:

    var up = new uploadr.viewer({ ... })

with the following options:

 - `root`: root element ( or selector ) of the upload widget.
    - To customize widget, see [Widget Customization section](#widget-customization) below.
 - `page`: an object for configuration for fetching new content.
   - this object wil be passed to `@loadingio/paginate`. See `@loadingio/paginate` for documentation.
   - items in returned list from fetch should contain at least a member `url` for showing the URL of the image.

Similar to `uploadr.uploader`, a mixin `uploadr-viewer` is available by including `uploadr.pug`:

    include <path-to-uploadr.pug>
    div.some-tag-to-wrap-uploader-viewer: +uploadr-viewer("scope-name")


Feel free to wrap uploader or viewer in dialogs or popups. See demo site for more examples.


### API

`uploadr.uploader` object provides following APIs:

  - `init` - initialize uploadr, return a promise that resolves when initialized.
    - constructor initializes uploadr automatically.
    - simply use `init.then( ... )` to ensure initialized.
  - `upload` - upload chosen files.
  - `clear` - clear chosen files.
  - `get` - get chosen files.
  - `on(name, cb)` - listen to `name` event with `cb` callback. Following events are available:
    - `preview:loading`
    - `preview:loaded`
    - `file:chosen`
    - `upload:done`
    - `upload:fail`

`uploader.viewer` object provides following APIs:

  - `fetch` - force fetching new content.
  - `reset` - reset viewer content
  - `on(name, cb)` - listen to `name` event with `cb` callback. Following events are available:
    - `file:chosen`: when an item is chosen. `cb` called with `{url}` object as parameter.
    - `fetch:fetched`: when fetching new items. list of items passed as parameter.
    - `fetch:end`:  when there is no new item available.
    - `fetch:empty`:  when list is empty.


### Providers

`@plotdb/uploadr` supports uploading to different kinds of file hosting services. use `provider` to choose from the available providers below.

To use a provider, you should make sure to

 - client side: initialize `uploadr` with proper provider configurations
 - server side: ensure to add API endpoint if needed.

To upload without UI ( Uploadr Viewer ), use the client-side providers directly, available via:

    uploadr.ext["<provider-name>"]

Client side providers are functions accepting an object with the following fields:

 - `files`: Array of files to upload. Items for each file are objects with the following fields:
   - `thumb`: thumbnail URL
   - `file`: corresponding file object
 - `progress(opt)`: progress event handler accepting an opt object with the following fields:
   - `percent`: progress. 0 ~ 1
   - `item`: uploading item object with the same structure as described in `files`.
 - `opt`: corresponding configs described in sections of each provider below.
 - `data`: additional data passed via the `data` field ( accessible via `req.fields.data` on the server side )

For example, to upload a file to Google Cloud Storage:

    uploader.ext.gcs({
      files: [{file: new File(["hello"], "hello.txt", {type: "plain/text"})],
      progress: function(opt) { console.log(opt.percent); },
      opt: {bucket: "my-gcs-bucket"}
    });

It always return a Promise resolved with a list of object with fields listed in the `Other Providers` section, check it for more information.


Provider configurations are described below.


#### Native

Upload files to a local API endpoint. include `providers/native/index.min.js` then:

    new uploadr({provider: { host: "native", config: { ... }}});

where the config contains:

 - `route`: API endpoint


#### ImgBB

Upload images to ImgBB. Include `providers/imgbb/index.min.js` then:

    new uploadr({provider: { host: "imgbb", config: { ... }}});

where the config contains:

 - `key`: imgbb API key for uploading images.


#### GCS ( Google Cloud Storage )

Upload files to Google Cloud Storage directly from browser. Include `providers/gcs/index.min.js` then initialize with:

    new uploadr({provider: {host: "gcs", config: { ... }}});

where the config contains:

 - `bucket`: bucket name in your google cloud storage to hold your files.
 - `domain`: domain name to access your files (including schema ).
   - if omitted, falls back to `https://storage.googleapis.com`
   - this is for previewing / downloading files.
 - `route`: server route to request signed URL for uploading files.
   - if omitted, falls back to `/d/uploadr/gcs`.


#### Dummy

Dummy provider doesn't upload files anywhere - it just responds with a dummy result. Include `providers/dummy/index.min.js` then:

    new uploadr({provider: { host: "dummy" }})

and there is no config for dummy provider.


#### Other providers

You can also add provider for services you'd like to use by simply adding a function in `uploadr.ext`:

    uploadr.ext.myService = function ({files, progress, opt}) { ... }


It's your job to implement the upload mechanism with the following parameters and requirements:

 - Parameters
   - `files`: Array of `{thumb, file}` object with:
     - `thumb`: thumbnail link ( blob URL )
     - `file`: file object ( blob ) from input element to upload.
   - `progress({percent, val, len, item})`: function to be called when progress is reported, with options:
     - `percent`: percent of size uploaded
     - `val`: actual bytes uploaded
     - `len`: file size
     - `item`: object in `files` array that is making progress.
   - `opt`: the provider config object.
   - `data`: additional data to pass to server.
     - packed by `FormData` and accessible through `req.fields.data` as string when using `express-formidable`.
     - need to manually parse to JSON in server, if a JSON object is passed from client.
 - A provider function should always return a Promise that resolves a list of objects when upload is finished.
   - resolved object in list should contain the following members:
     - `id`: unique ID for this file.
     - `name`: name of this file. falls back to ID if omitted.
     - `url`: URL for previewing this file.
     - `download-url`: URL for downloading this file. falls back to `url` if omitted.
     - `size`: file size. optional
     - `err`: information if uploading of this file failed.


### Widget Customization

Uploadr client library uses [ldview](https://github.com/loadingio/ldview) for UI abstraction. If you design your own upload widget, simply add the following `ld` names on corresponding elements.

Here is for uploader:

 - `drop`: area for dropping files to choose them.
 - `file`: `ld-each` type name. preview of chosen files. with the following nested `ld` names:
   - `thumb`: element for showing preview image. should also be an `<img>` tag.
   - `progress`: upload progress indicator
   - `name`: name of the chosen file.
   - `size`: size of the chosen file.
   - `modifiedtime`: modified time of the chosen file.
   - `delete`: file is un-chosen when element with `delete` name is clicked.
 - `input`: `input` element with `type='file'` attribute. For manually uploading with file picker dialog.
 - `upload`: upload chosen files to server when clicked.
 - `clear`: clear all files when clicked.
 - `loader`: a `running` class will be added to element(s) with this name.

and here is for viewer:

 - `file`: same with uploadr, along with the selector under `file`.
 - `load`: a DOM element triggering additional load when clicking.
 - `loader`: a `running` class will be added to element(s) with this name.



## Server Side

To save files locally ( or after authenticated ), you will need a server-side API. Depending on how you store uploaded files, the implementation will vary. These implementations are separated into different modules called `provider`.


### Common Usage

    up = uploadr.provider {host: 'native', config: { .. /* provider specific config */ .. } }
    app.post \path, express-formidable({multiples: true}), up.getUploadRouter!
    # note: not all providers implemented getDownloadRouter for now.
    app.get \path/:id, express-formidable({multiples: true}), up.getDownloadRouter!

Configuration:

 - `host`: provider name, such as `native`, `gcs`.
 - `config`: provider configuration. check doc for each provider below for more information.

Additionally:
 - `express-formidable({multiples: true})` is for passing form data. it depends on how you will use `uploadr` and can be tweaked accordingly.
 - `uploadr.provider` always provides following two APIs:
   - `getUploadRouter`: its interface depends on provider's implementation. For example:
     - provider `native` reads and stores files listed in `req.files`
     - provider `gcs` reads optional `req.body.name` field.
   - `getDownloadRouter`: always read `req.params.id` for identifying files to download.


### adopt

`adopt` is available as a config in all providers. `adopt` function is used to track a file, and by default do nothing, left to users to implement. it should be an object providing the following two member functions:

 - `upload(req, ret)` - called when we expect a file storing slot is created.
 - `download(req, ret)` - called before file is served to user.

where the return value should be an object with the following fields:

 - `name`: filename
 - `id`: file ID, provided by provider.
 - `url`: optional. available for native provider.

both function should return a promise. `adopt` can be used to

 - return a rejected promise to prevent the file from being uploaded or downloaded
 - track uploads / downloads

The following is an example of using `adopt` in native provider:

    up = uploader.provider({
      host: 'native', config: {
        adopt: {
          upload: function() { ... },
          download: function() { ... }
        }
      }
    })


### Native Provider

Native provider accepts incoming request with files payload, and save them using a hashed ID into a specified location. Use `express-formidable` and `uploadr(...).route` to handle files:

    up = uploader.provider {host: 'native', config: { ... }}
    app.post \/d/uploadr, express-formidable({multiples: true}), up.getUploadRouter!

Example configurations:

    {folder: 'static/assets/files', url: '/assets/files'}


#### Configurations

Configure the native provider with the following options:

 - `config`: the native provider specific configs, including:
   - `folder`: fs path for saving all files. if omitted, fall back to `uploads`
   - `url`: URL prefix ( relative or absolute ). if omitted, falls back to `folder`
 - `adopt: (req, {name, path, url, id})`: post process function after files are saved.
   - if provided, will be called for each file saved.
   - options:
     - `req`: express request object
     - `name`: name of the file
     - `path`: optional. `path` for the file in file system
     - `url`: optional. `url` for accessing this file
     - `id`: `id` for the file
 - `catch: (err, req, res, next)`: Promise rejection handler.
   - if omitted, falls back to `res.status(505).send()` when exception occurs.
 - `log`: log function. if omitted, falls back to `console.log`.


#### APIs

Following are the APIs exposed by native provider:

 - `handler(req, res, next)`: process req.files and return a promise that resolves with an array of `{url, id ,name}`.
 - `router(req, res, next)`: wrap handler as a route that passes data to res.send, or report 500 on error.
 - `archive(opt)`: function that takes care of files
   - input: one of following ( name is optional in both case )
     - {path, name}
     - {buf, name}
   - return:
     - { name, url, id } if successful
     - { name } otherwise


### GCS Provider

The GCS provider ( for Google Cloud Storage ) doesn't store files on the local server so there is no file passed to server. Instead, a URL is returned to the client for uploading / downloading files to an assigned bucket in Google cloud storage.

Basic usage is similar to native provider:

    up = uploader.provider {host: 'gcs', config: { ... }}
    app.post \/d/uploadr, express-formidable({multiples: true}), up.getUploadRouter!


#### Configurations

 - `config`: GCS config including following fields:
   - `projectId`: project ID. e.g., `sample-id`
   - `keyFilename`: path to your private key file for accessing specific project. e.g., `sample-prk.json`
   - `bucket`: bucket name. e.g., `sample-bucket`
   - `limit`: maximal amount of files in one shot. default 10 if omitted.

#### CORS Note

Before you can upload file via browser directly to Google Cloud Storage, you have to set CORS policy with gsutil:

    gsutil cors set cors.json gs://<your-bucket-name>

Sample content of `cors.json`:

    [{
      "maxAgeSeconds": 3600,
      "method": ["GET", "HEAD", "PUT"],
      "origin": ["http://localhost:3005"],
      "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"]
    }]


## License

MIT
