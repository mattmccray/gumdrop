# v1.1.2
- Added helper for checksums, good for:
- Added cache busting support for uris. e.g. "/theme/screen.css?v=HASHHERE445435435ETC"
- Added support for `Gumdrop#no_render(*paths)`. Treats all matched paths as binary.
- Fixed sprockets load_paths issue.

# v1.1.1
- Cleaned up dependencies.
- Some performance and memory optimizations.

# v1.1.0
- Added `Gumdrop.prepare(&block)`, it's a good time to apply data transformations.
- Added Content#dirname.
- Fixed `base_path` for file based generators.
- Updated site templates.
- Optionally prepare yaml data from content.
- Lock version numbers of deps in gemspec
- No longer do a binary check on files when running `uris` command.
- Added support for caching partials (good for static partials used in layouts).
- Fixed dev server bug where it would rescan on every request.
- Fixed relativing urls in partials.
- Re-enabled support for `content_for` and `content_for?` to rendering context (known to work for ERb).
- Re-enabled support for `Gumdrop::Util::Pager`.
- Re-enabled support for `page` in rendering context.
 
# v1.0.3
- Fixed markdown and textile view_helpers.
- `Dir.chdir` to `site.root`. (should be able to run gumdrop in any folder of a Gumdrop project)
- Added support for launching the browser when starting the dev server.
- You may now override the dev server port on the cli as well.
- Disabled automatic `bundle install` when a new project is created. It's annoying.

# v1.0.2
- `gumdrop new` will automatically run `bundle install` so the project site is ready to go.
- Using kramdown in default template.
- Bugfix: Windows regression, in data providers.

# v1.0.1
- Moved `watch` feature from gem CLI to example in Gumdrop site file. (Because the listen gem does not, in fact, work on every platform out of the box -- At least, not in a way that's usable in a library like this -- Gumdrop needs to support Windows, so listen is gone from core.)
- Fixed local reference to gumdrop gem in the default tempalte Gemfile.

# v1.0.0
- Complete internel rearchitecture. Good stuff.
- Gumdrop files are now straight ruby that's loaded by gumdrop. You can do any typical ruby kind of things are the root level without having any scope surprises (Gumdrop will have been loaded).
- New event system. `Gumdrop.on :event_name {|e| }` Events:
  - `:build`
  - `:scan`
  - `:generate`
  - `:render`
  - `:render_item`
- All the events have :before_* and :after_* versions too.
- Removed content filters. You can now listen for the :render_item event and set event.data.return_value to change content post-render (layout will have been applied)
- New DataProviders: csv, xml and sqlite3

# v0.8.0
- Leveraging Thor for new CLI support.
- Added watch command to watch filesystem and auto-compile.
- You can now add commands to the gumdrop command for your site. Use `tasks` block in Gumdrop file.
- Report rendering errors better.
- Code cleanup and reorganization.
- Generators keep track of generated content.
- Bugfix: Files without layouts won't throw an exception.
- New subdued output mode, cli '-s' flag

# v0.7.5
- Gumdrop dev server will serve up files from output_dir if the file isn't found in the source tree.
- Added new template: blank
- Coerces content into UTF-8, if it can, when relativizing paths (to work around encoding bugs).
- Content class defers a lot of stuff from the initializer (for slightly faster startup).
- Changed site.node_tree to site.content_hash. More representative of what it is.
- Paths aren't relativized for pages that set force_absolute

# v0.7.4
- All rendered content (including layouts) will relativize paths starting with / on href="" and src="" for html files. Can be set to array of file exts to process at `config.relative_paths_for= ['.html']` or sett to process all files `config.relative_paths_for= :all` or turned off entirely by `config.relative_paths= false`
- Proxy server is disabled by default. Enable it `configure.proxy = true`

# v0.7.3
- Bugfix: Correctly runs content through multiple processors (when multiple are specified in the filename. ie: test.js.erb.coffee gets sent through CoffeeScript then erb)

# v0.7.2
- Now supports :packr as a type of compression for stitch/sprockets (be sure it's in your Gemfile)
- Cleaned up generator internals

# v0.7.1
- Ignore/skip (greylist/blacklist) will now include/skip generated content too.
- Quiet mode will actually be quiet.
- Made build log output more consistent.

# v0.7.0
- Initial support for sprockets js generator.

# v0.6.4
- Callbacks are cleared on each `Site#rescan()` to prevent duplicates.
- Callback blocks are called with `site` as the parameter.
- Added `Gumdrop.change_log`.
- Added on_before* event for scan, generate, and render.

# v0.6.3
- Added `generated` flag to Content object
- Added `config` to Generator context
- Added callbacks to site build process. Callbacks:
    - on_start
    - on_scan
    - on_generate
    - on_render
    - on_end
- Dev server doesn't check last build time for static assets.

# v0.6.2
- Consolidated stitch support code into single file
- Bugfix: Generates better relative paths for Content objects
- Cleaned up paths in Content
- Updated project templates

# v0.6.1
- Content filters are run for dev server requests now too.
- Added config.env, defaults to 'production' (override from cli with -e)

# v0.6
- Extracted Gumdrop::Build into Gumdrop::Site. Removed static Gumdrop#site.

# v0.5.2
- DeferredLoader changed to DataManager
- Added YamlDoc support to data collections -- a data format (.yamldoc) that strips YAML front matter and puts the content under the key 'content', or it will use a custom key from the front matter if the value of the pair is '_YAMLDOC_'
- Templates are stored under their short name and full path now.
- skip/ignore (blacklist and greylist) now use File.fnmatch instead of starts_with? for matching paths

# v0.5.1
- Bugfix: dev server was rescanning source files multiple times per pages load if build time exceeded 2 seconds... Will now wait 10 seconds before rescanning source.

# v0.5
- Gumdrop projects now require a `Gumdrop` file at the root -- contents are what you used to put in lib/site.rb.
- Added new `configure` and `view_helpers` methods for use in `Gumdrop` site file.
- Smarter CLI, knows when you're in a gumdrop site or not.
- Local templates supported for new sites (looks under ~/.gumdrop/templates)
- You can list installed templates using `gumdrop --list`
- You can install the current site as a local template using `gumdrop -t new_template_name` in a site folder.
- Data folder path is now configurable: `Gumdrop.config.data_dir` or `set :data_dir, "PATH"`
- Added `data.site` and `data.site_all` to `DefferedLoader`. Useful for listing all non-grey-listed files or all files.
- Data will now load from data/COLLECTION_NAME/*.json or .yaml or .yml. Loads as an array array of all entries, adds a key '_id' that's the base filename.
- Initial `redirect` options for use in generate blocks.
- Extra stitch generator options:
    - `compress` takes `:jsmin`, `:yuic`, or `:uglify` now. (`true` defaults to `:jsmin`)
    - `obfuscate: true|false` -- Sets munging/mangling for compressors that support it.
    - `keep_src: true|false` -- Creates a second filename with :source_postfix added to the end of the filename
    - `source_postfix: "-src"` 

# v0.4
- Added support for special dev proxy at /-proxy/ENDPOINT_URL -- Useful for working with external (non-CORS) apis/websites. Enabled by default. To disable, set Gumdrop.config.proxy_enabled= false

# v0.3.10
- Added 'ignore' dsl command -- keeps the node in the memory, but doesn't render/copy it on build.

# v0.3.9
- Bugfix: Filenames won't break if the have extra '.' in them... For realz this time. *ahem*

# v0.3.8
- Bugfix: Filenames won't break if the have extra '.' in them.

# v0.3.7
- Added lib_dir and source_dir to config for more customization possibilities
- Added blacklisting example to templates

# v0.3.6
- Correctly added deps to gemspec for i18n and bundle. *ahem*
- Version bump

# v0.3.5
- Updated gemspec to include bundle and i18n dependencies
- Updated backbone template to build minified version by default

# v0.3.4
- Fixed a bug in the default template
- Added custom Stitch compilers for hogan, css/sass, and serenade files.
- Added -r --reload switches to commandline to force reloading on server, per request.

# v0.3.3
- Updated Backbone template to include a default view (and some core bugfixes)

# v0.3.2
- Removed references to 'twitter' from cli message.

# v0.3.1
- Early version of a backbone (webapp) site template

# v0.3
- Better logging support
- Removed twitter-bootstrap template
- Initial support for stitch-rb via a `stitch` generator command.

# v0.2.17
- Updated syntax to Ruby 1.9
- Tweaked template Rakefile(s)
- Added some initial specs

# v0.2.16
- Added option to specify output folder, still defaults to "output"
- Bugfix: content wasn't looking for layouts right, causing exception

# v0.2.15
- Fixed minor regression.
- CLI now will report gumdrop version when show help.

# v0.2.14
- Added new template type: twitter
- Added cli option -t / --template to specify default or twitter template when creating a new project

# v0.2.13
- Adding content_filters for altering rendered output -- BUILD ONLY!
- Tweaks to template site

# v0.2.12
- Added textile view_helper
- Allow paths prefixed with "/" in uri()
- Context#render will now look for templates too
- Fixed content_for(key, &block) in slim -- not tested in any other template engines -- be sure and use '=' tag: = content_for :sidebar do

# v0.2.11
- Updated server to reload on .css and .js file requests too.

# v0.2.10
- Update default template to use slim layouts
- Fixed a bug in uri when creating a path to "/"

# v0.2.9
- Added ability to force absolute url's from uri helper. set force_absolute in template

# v0.2.8
- Added better support for site reloading in server

# v0.2.7
- Added support for `yield` in templates
- Added support for content_for -- only tested in SLIM

# v0.2.6
- Update pager_for to accept a symbol or an array

# v0.2.5
- New feature: Generators, from source tree or centreally in lib/site.rb
- Server can reload the entire site for each request, by default this feature is off
- Added Pager class for creating tumblr-like pagesets

# v0.2.4
- Modernized Sinatra usage. Added an example site (just boilerplate at this point).

# v0.2.3
- Updated code to use autoload. Added primary dependencies to the gemspec. Version bump.

# v0.2.2
- Fixed bug where partials weren't rendered via the dev server.

# v0.2.1
- Initial release. Yay!
