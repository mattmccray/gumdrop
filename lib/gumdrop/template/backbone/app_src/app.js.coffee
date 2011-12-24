{ log, warn }= require('utils')

class Application extends Backbone.Model

  initialize: ->
    @initializers= []
    @set isReady:no

  addInitializer: (fn)->
    if @get 'isReady'
      fn.call this, @options
    else
      @initializers.push fn

  start: (options)->
    if @get 'isReady'
      # You can only 'start' the app once!
      warn "You can only start the application once!"
      this
    else
      log "Init!"
      @trigger 'app:init:before', app:this, options:options
      for fn in @initializers
        fn.call this, options
      @trigger 'app:init:after', app:this, options:options
      delete @initializers
      @options= options
      @set isReady:yes
    this

module.exports= new Application

