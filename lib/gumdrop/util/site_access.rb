module Gumdrop::Util
  module SiteAccess
    include Eventable    
    include Loggable

    def site
      Gumdrop.site
    end

    # for event bubbling
    def parent
      site
    end

  end
end