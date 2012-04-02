{log}= require 'utils'


class HomeView extends Backbone.View
  className: 'home'

  src:
    template: require('./templates/home')
    styles: require('./styles/home')

  render: -> 
    @src.styles.add()
    @el.innerHTML= @src.template({})
    @


module.exports= HomeView