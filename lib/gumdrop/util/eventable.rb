require 'onfire'

module Gumdrop::Util

  module Eventable
    include ::Onfire

    def event_block(target)
      fire "before_#{target}".to_sym
      data= HashObject.new
      result= data.payload= yield(data)
      fire target, data
      fire "after_#{target}".to_sym, data
      ret_val= data.return_value || result
      data.clear()
      ret_val
    end

    def fire(event, data=nil)
      data= case
        when data.nil?
          HashObject.from site:Gumdrop.site
        when data.is_a?(Hash)
          HashObject.from(data).merge site:Gumdrop.site 
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