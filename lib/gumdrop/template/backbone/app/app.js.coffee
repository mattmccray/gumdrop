{ log, warn }= require('utils')


class Application extends Backbone.Router
  
  views: {}
  
  routes:
    '': 'home'
  

  home: ->
    @views.home = new (require('views/home')) unless @views.home?
    $('body').html @views.home.render().el



  constructor: ->
    @initializers= []
    @isReady= no
    super
  
  addInitializer: (fn)->
    if @isReady
      fn.call this, @options
    else
      @initializers.push fn
    this

  start: (options)->
    if @isReady
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
      @isReady= yes
      Backbone.history.start pushState:(@options.pushState)
      log "Ready."
    this


module.exports= new Application
