((has_console)->
  
  # TODO: Implement all the other usual console tricks
  log_methods= if has_console
    log: ->
      console.log arguments...
    warn: ->
      console.warn arguments...
    error: ->
      console.error arguments...
    info: ->
      console.info arguments...
  else
    # Create a bunch of NOOPs
    # TODO: Decide if a fallback to non-console folks should be provided? (I'm thinking no.)
    log: -> # noop
    warn: -> # noop
    error: -> # noop
    info: -> # noop
  
  module.exports= log_methods
  module.exports.globalize= (ctx=window)->
    for nam, fn of log_methods
      ctx[name]= fn

)(window.console?)


  