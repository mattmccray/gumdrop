# require 'observable'
require 'onfire'

module Gumdrop::Util

  module Eventable
    include ::Onfire
    # include Observable

    # def fire(action, data={}, sender=self)
    #   changed
    #   notify_observers sender, action, data
    # end

    def event_block(target, send_data=false)
      fire "before_#{target}".to_sym
      data= HashObject.new
      result= data.payload= send_data ? yield(data) : yield
      fire target, data
      fire "after_#{target}".to_sym, data
      data.return_value || result
    end

    def fire(event, data=nil)
      data= if data.nil?
        HashObject.from {
          site:Gumdrop.site
        }
      elsif data.is_a? Hash
        HashObject.from(data).merge(site:Gumdrop.site)
      else
        data
      end
      event_for(event, self, data).bubble!
    end

    def clear_events
      @event_table ||= Onfire::EventTable.new
    end

  end

end