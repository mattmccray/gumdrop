{log}= require 'utils'


class HomeView extends Backbone.View
  className: 'home'

  template: require('./templates/home')
  styles: require('./styles/home')

  render: -> 
    log @styles
    @styles.add()
    @el.innerHTML= @template({})
    @


module.exports= HomeView