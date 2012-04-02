# Gumdrop

Gumdrop is a small and sweet cms/prototype tool. It can generate static html with relative paths, and includes a dev server that can be run via any rack server (including POW!).

## Install

    gem install gumdrop

# Quick Ref

### Create New Site

    gumdrop --create my_new_site

Shorter syntax:

    gumdrop -c my_new_site

### Create New Site From Template

    gumdrop -c my_new_site -t backbone


### Build Static HTML

    gumdrop -b

Or, you can use Rake:

    rake build


### Start Dev Server

    gumdrop -s

Or, using Rake again:

    rake serve

### Saving The Current Site As A Local Template

    gumdrop -t my_template

You can then create new sites based on your local template:

    gumdrop -c my_new_from_my_template -t my_template

Local templates are stored under `~/.gumdrop/templates/`.


# Gumdrop Site Structure

*NOTE:* The following is based on the `default` template, the structure is configurable based on your needs.

This is the file structure that is generated when you run `gumdrop --create site_root`. You can change whatever you'd like under `source/`, this is just a starting point.

    site_root/
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
      Gumdrop
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

# Gumdrop File

Gumdrop looks for a file named `Gumdrop` to indicate the root project folder. It'll walk up the directory structure looking for one, so you can run Gumdrop commands from sub-folders.

The `Gumdrop` file is where you configure your site, generate dynamic content, assign view_helpers and more.

Have a look at the file here: https://github.com/darthapo/gumdrop/blob/master/templates/default/Gumdrop

# Need To Document:

- Proxy support
- Stitch
- "Dynamic" pages
- Data support
- Content filters
- Partials
- Config and using in pages
- Project Templates
