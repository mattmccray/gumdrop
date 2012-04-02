all_libs= {}

expose= (name, as)->
  all_libs[as]= lib= require(name)
  exports[as]= lib

# Listing of all the libraries

expose 'jquery', '$'
expose 'backbone', 'Backbone'
expose 'hogan', 'Hogan'
expose 'underscore', '_'

# Helper to assign all libs 
exports.globalize= (ctx=window)->
  for own name, lib of all_libs
    ctx[name]= lib unless ctx[name]?
  this
