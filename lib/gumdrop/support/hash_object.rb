module Gumdrop

  class HashObject < ActiveSupport::HashWithIndifferentAccess
  
    def method_missing(sym, *args, &block)
      if self.has_key? sym
        self[sym]

      elsif sym.to_s.ends_with? '='
        key= sym.to_s.chop.to_sym
        self[key]= args[0]

      else
        # FIXME: Return super() or nil for Model#method_missing?
        # super sym, *args, &block
        nil
      end
    end
  
  end

end