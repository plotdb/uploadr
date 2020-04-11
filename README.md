# ldUpload

File Upload Widget base on Loading-ui. Provide following functionalities:

 * Customizable UI widget for 
   - upload
   - upload progress
   - view ( image list )
 * backend adopter for express
   - 



## Usage

upload widget: 

js:
```
    uploadr({
      root: 'selector-to-my-upload-scope`
      progress: ->
      uploadr: { ... }
    })
```


pug:
```
    script(src="path-to-client.js")
    +scope("my-upload-scope")
      +uploadr-list
      +uploadr-upload
      div(ld="upload") ...
```

picker widget:

js:
```
    uploadr.viewer({
      root: 'selector-to-my-viewer-scope`
      page: (ldPage instnace)
    })
```

pug:
```
    script(src="path-to-viewer.js")
    +scope("my-viewer-scope")
      +uploadr-viewer
```


## Widget

uploadr client use ldView to implement the dynamics of frontend elements. UI elements has been implemented in the corresponding pug mixins, you can use following mixins to take advantage of them:

 * `uploadr-list` - list of chosen files ( ld-each=`file` )
 * `uploadr-viewer` - list of uploaded files for user to pick ( ld=`list` & ld-each=`item` )
 * `uploadr-upload` - upload widget including drag & drop area (ld=`drop`) and upload button (ld=`input`)

`upload` and `clear` is not supported in mixin but you can add them in your own UI.

To use `upload`, `clear` and `uploadr-list` and `uploadr-upload`, wrap them in a ld scope element:

```
  +scope("my-scope")
    +uploadr-upload
    +uploadr-list
    div(ld="upload")
```

`uploadr-viewer` is supported in standalone scope:

```
  +scope("my-another-scope")
    +uploadr-viewer
```


## Customization

Uploadr UI uses loading-ui and bootstrap, which might not be what you need. instead, you can implement your own UI without bootstrap and loading-ui. You will still need loading-ui's javascript since uploadr uses it.

To attach the dynamics with your own ui, use following `ld` names:

 * supported by client.js:
   * `upload` - upload chosen files when clicked.
   * `clear` - clear chosen files when clicked.
   * `drop` - an area to accept drag and drop of files.
   * `input` - an input element with type `file`.
   * `file` ( ld-each ) - list of chosen files, before upload. With following `ld` names as children:
     - thumb - preview of chosen file.
     - name - name of chosen file.
     - size - size of chosen file.
     - delete - remove this file when clicking.
     - progress - element using its visual appearance to show the upload progress of this file.
 * supported by viewer.js:
   * `list` - container of listed images for choosing.
   * `item` ( ld-each ) - should be inside `list`. an image element for user to pick.


## Configuration
* uploadr
  - root: element / selector for the root element of uploadr ui.
  - uploader: an object containing information for backend api"
    * native:
      ```
      { host: "native", route: "<path-to-api-endpoint>" }
      ```
    * imgbb:
      ```
      { host: "imgbb", key: "api-key-to-imgbb" }
    extend `uploadr.ext` to add more backend adapter.
  - progress({percent, val, len}): upload progress information 
    - percent: 0 ~ 1, 1 means finished.
    - val: current progress
    - len: expected total progress
* viewer
  - root: element / selector for the root element of uploadr ui.
  - page: option for constructing ldPage element. see ldPage for more information.
    - items in returned list from fetch should contain at least a member `url` for showing the url of the image.


## API
* uploadr
  - init - initialize uploadr.
  - upload - upload chosen files.
  - clear - clear chosen files.
  - get - get chosen files.
  - on(name, cb) - listen to `name` event with `cb` callback.
* viewer
  - on(name, cb) - listen to `name` event with `cb` callback.


## Events

* uploadr
  - preview.done
  - preview.loading
  - file.chosen
  - upload.done
  - upload.fail
* viewer
  - choose



## Server Usage and Configuration

```
    cfg = do
      uploadr: do
        folder: '...'
        url: '...'
        adopt: (req, {url, name, id}) -> new Promise (res, rej) -> ...
        catch: (err, req, res, next) -> ...
      formidable: {multiples: true}

    app.post \/d/uploadr, express-formidable(cfg.formidable), uploadr(cfg.uploadr).route
```

uploadr exposes following APIs:

 * handler(req, res, next): process req.files and return promise, resolving url, id and name as array of objects.
 * route(req, res, next): wrap handler as a route which pass data to res.send, or report 500 on error.
 * archive(opt): function that takes care of files
   - input: one of following ( name is optional in both case )
     - {path, name}
     - {buf, name}
   - return:
     - { name, url, id } if succeed
     - { name } otherwise


## License

MIT
