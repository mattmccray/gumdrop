# Gumdrop

Gumdrop; The sweet cms/prototyping tool.

It generates static html and includes a dev server that can be run via any
rack server (including POW!).


## Install

```bash
$ gem install gumdrop
```


## Quick Start

```bash
$ gumdrop new SITE_NAME
```

*(You can run `gumdrop help` to see a list of commands and their supported flags.)*

Gumdrop will spit out a default Gumdrop project site for you, which you can then
build by running:

```bash
$ cd SITE_NAME
$ gumdrop build
```

Bam! A static version of the site is now available in a newly created `./output`
folder.

Don't want the output there? Maybe you want it to put it in `./public` instead?
No problem. Open up the `Gumdrop` project file:

```bash
$ $EDITOR Gumdrop
```

At the top of the file you'll find a `Gumdrop.configure` block. Add this to the
top of that block:

```ruby
Gumdrop.configure do |config|

  config.output_dir= "./public"

  # ... Other stuff

end
```

Now, when you run `gumdrop build` again, it'll generate all the output into
the `./public` folder (creating it, if it doesn't exist).


## Lots More

That's enough to get you started! Poke around the code it generated to see how
it works. You can also start with a blank slate by running:

```bash
$ gumdrop new -t blank MY_BLANK_SITE
```

Gumdrop can do quite a lot and is very configurable. Be sure and read the wiki
for documentation and more examples!

[https://github.com/darthapo/gumdrop/wiki](https://github.com/darthapo/gumdrop/wiki)

## By The Power of...

Greyskull? Well, not so much. But Gumdrop core is powered by these excellent
open source projects (in alphabetical order):

* ActiveSupport
* Bundle
* Launchy
* Onfire
* Sinatra
* Tilt
* Thor 

And will, optionally, leverage these in building your site:

* sqlite3
* sprockets
* stitch
* jsmin
* slim
* haml/sass
* coffee-script
* and many, many more! (todo: gotta document 'em all!)

