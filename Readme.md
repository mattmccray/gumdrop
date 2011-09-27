# Gumdrop

Gumdrop is a small and sweet cms/prototype tool. It can generate static html with relative paths, and includes a dev server that can be run via any rack server (including POW!).

## Create New Site

    gumdrop -c my_new_site


## Build Static HTML

    gumdrop -b

Or, you can use Rake:

    rake build


## Start Dev Server

    gumdrop -s

Or, using Rake again:

    rake serve

# Gumdrop Site Structure

This is the file structure that is generated when you run `gumdrop --create site_root`. You can change whatever you'd like under `source/`, this is just a starting point.

    site_root/
      data/
        config.yml
      lib/
        view_helpers.rb
      source/
        favicon.ico
        index.html.erb
        theme/
          screen.css.scss
          scripts/
            app.js.coffee
          styles/
            _tools.css.scss
          templates/
            site.template.erb
      Gemfile
      config.ru
      Rakefile
      

When you run `gumdrop --build` or `rake build` it will generate an `output/` folder.

    site_root/
      output/    (** GENERATED CONTENT **)
        index.html
        theme/
          screen.css
          scripts/
            app.js

You'll notice the templates and partials aren't included in the output.
