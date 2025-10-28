module.exports =
  pkg:
    dependencies: [
    * name: \@loadingio/debounce.js
    * name: \proxise
    * name: \ldview
    * name: \ldloader
    * name: \@loadingio/paginate
    * name: "@plotdb/uploadr"
    * name: "@plotdb/uploadr", type: \css
    ]
  interface: -> @up
  init: ({root, data, i18n, ctx}) ->
    # to reduce difficulty of using this module, we add resource bundles for users here,
    # and do i18n transformation for them.
    # this usually is the job of the user, so this may not be a best practice
    i18n.on \languageChanged, ~> @._instance.transform \i18n
    i18n.addResourceBundles ctx.uploadr.i18n
    @._instance.transform \i18n
    base = root.querySelector('[ld-scope]')
    @up = new uploadr.uploader root: base, provider: (data?provider or {}), accept: data?accept or ''
