lib?('all').globalize()

app= require('app')

$ ->
  app.start
    debug: true


module.exports= app
