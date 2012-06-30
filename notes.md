# General

Gumdrop is based on personal and project code from several years ago. It's been slowly updated and improved over time. But I've not been able to give it a lot of sustained effort to get it where I want it.

Since I started, Jekyl, MiddleMan, and other static site tools have been released. While they are all good in their own ways, each miss something that I want. The main difference, at this point in time, are generators. I want to have a static site, but still have data-driven pages.

Anyway, this is just a place for me to put down my thoughts on what I want to do to get it servicable as a 1.0 candidate:


# Architectural Changes

- Rendering should be abstracted from Content objects
- Building should be abstracted from Site object
- Generators should be able to unload themselves and any pages they created
- There should be discreet ways of knowing whether a Content object is renderable or not (other than file ext)
- DSL generators should accept a name, and optional base_path (applied to all generated page paths)
- Callbacks should have the site var in scope
- Reporting/logging needs to be abstracted from Site and all dependant objects (Loggable module?)
- Project Templates should be abstracted from CLI::Internal (and External) into a module
- Make `DataManager` more OO -- abstract data providers. Each provider would specifiy the file extensions they handle.
- Bundler.require site.config.env.to_sym

## Nice to Haves

- Server should be able to selectively render individual content without rescanning/building the whole tree

# Impl Notes

## Content

- Content objects can know their `level` based on their `full_path` (basically count the slashes)

```rb
contentA = Content.new "source/page.html.erb"
contentB = Content.new "source/logo.png"

contentA.binary? #=> false
contentB.binary? #=> true
```

Possible `binary?` method (from ptools):

```rb
class Content
  def initialize(source_path, generator=nil, &block)
    @source_path= source_path
    @filename= File.basename(source_path)
    @generator=generator
    @block= block
    # etc...
  end

  def binary?(file)
    @is_binary ||= begin
      s = (File.read(file, File.stat(file).blksize) || "").split(//)
      ((s.size - s.grep(" ".."~").size) / s.size.to_f) > 0.30
    end
  end

  def generated?
    !@generator.nil?
  emd

  def body # Memoize this?
    if @block
      @block.call
    else
      File.read @source_path
    end
  end
end
```

## Events/Observable

Use Observable internally?

```ruby
module Eventable
  include Observable

  def fire(action, data={}, sender=self)
    changed
    notify_observers(sender, action, data)
  end
end

# Usage
class MyClass
  includes Eventable

  def execute
    fire :my_action, ex:'data'
  end
end

```

Listeners would always have the same signature:

```ruby
class Listener
  def update(sender, action, data)
    puts "(#{ sender.inspect }) #{action}: #{ data.inspect }"
  end
end
```
Have the site listen and bubble the events?

```ruby
class Site
  includes Eventable

  def # wherever
    renderer= HtmlRenderer.new
    renderer.add_observer self
    renderer.draw # whatever

    #done
    renderer.delete_observers
  end

  def update(sender, action, data)
    fire action, data, sender
  end
end
```

## Rendering

```rb

class RenderContext
  include ViewHelpers

  attr_reader :content, :site, :state
  # attr_writer :content, :renderer

  def initialize(content, renderer, parent_context=nil)
    @content= content
    @renderer= renderer
    @site= renderer.site
    @state= {}
    @parent= parent_context
  end

  def render(*args) # Not exactly sure yet
    content= # extract/lookup a content object from args
             # maybe allow relative lookups from content?
    @renderer.draw_partial content
  end

  def get(key)
    @state[key]
  end

  def set(key, value)
    @state[key]= value
  end

  def method_missing(*stuff)
    # try to get/set from @state
    # else try to get from @parent unless @parent.nil?
    # else try and get it from @content
    # else return nil ???
  end
end

class Renderer
  includes Eventable

  attr_reader :site, :context

  def initialize(site)
    @site= site
  end

  def draw(content, opts={})
    return nil if content.binary?
    @context= RenderContext.new site, content, self
    output= _render_content content, opts
    fire :render, content:content, output:output
    output
  end

  def draw_partial(content, opts={})
    return nil if content.binary?
    opts.defaults! no_layout:true
    _sub_context content
      output= _render_content content, opts
      fire :render_partial, content:content, output:output
    _revert_context
    output
  end

private

  def _render_content(content, opts)
    output= content.body
    _render_pipeline(content.filename).each do |template|
      output= _render_text output, template
    end
    output- _render_layout output unless opts[:no_layout]
    output
  end

  def _render_text(text, tmpl, opts)
    # Tilt Code
    tmpl.new(opts).render(text) # pass opts on through?
  end

  def _render_layout(text)
    # Look for @context[:layout] or site.config.default_template
  end

  def _render_pipeline(path)
    # path.split('.') # then sort out how to:
    # return an array of Tilt templates based on file exts
    []
  end

  def _sub_context(content)
    @old_context= @context
    @context= Context.new site, content, self, @old_context
  end

  def _revert_context
    @context = @old_context
  end
end


```

## Building

```ruby
class Builder
  include Eventable

  attr_accessor :site, :renderer

  def initialize(site=nil, renderer=nil)
    @site= site
    @renderer= renderer.nil? ? Renderer.new(site) : renderer
  end

  def execute()
    fire :build_start
    site.contents.each do |content|
      if content.binary?
        _copy content.src_path => _output_path(content)
      else
        output = renderer.draw content
        _write output => _output_path(content)
      end
    end
    fire :build_end
  rescue => ex
    fire :exception, source:self, ex:ex
  end

private

  def _copy(files)
    files.each_pair do |from,to|
      # File.write code
      fire :copy, from:from, to:to
    end
  end

  def _write(files)
    files.each_pair do |text,to|
      # File.write code
      fire :write, from:from, to:to
    end
  end
end


# Usage
site= Gumdrop.local_site #=> Site
renderer= HtmlRenderer.new
builder= Builder.new site, renderer
builder.execute()
```

# Logging via Events?

- Only two levels? `:info` and `:warn`? Or add `:error`

```ruby
# Mixin to your class:
module Loggable
  
  # Assumes Eventable? or:
  # include Eventable

  def log(level, msg=nil)
    if msg.nil?
      msg= level
      level= :info
    end
    fire :log, level:level, message:msg
  end

  def warn(msg)
    log :warn, msg
  end

end

# Loggers
class ConsoleLogger
  def initialize(levels, format='%<level>s : %<message>s')
    @listen_for= levels
    @format= format
  end
  def update(sender, action, data)
    if action == :log
      if @listen_for.include? data.level
        data[:sender]= sender.to_s
        data[:time]= Time.new
        puts sprintf(@format, data)
      end
    end
  end
end
```

Or maybe not... I think maybe this:

```ruby
module Loggable
  def log
    Gumdrop.logger
  end
end

module Gumdrop
  class << self
    attr_accessor :logger
  end
end
```


