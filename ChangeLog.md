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