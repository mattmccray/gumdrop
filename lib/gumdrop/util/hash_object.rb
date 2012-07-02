module Gumdrop::Util

  class HashObject < Hash

    # All keys are symbols, internally
    def [](key)
      super(key.to_sym)
    end
    def []=(key, value)
      super(key.to_sym, value)
    end
  
    def method_missing(sym, *args, &block)
      if self.has_key? sym.to_s or self.has_key? sym
        self[sym]
      elsif sym.to_s.ends_with? '='
        key= sym.to_s.chop
        self[key]= args[0]
      else
        # super sym, *args, &block # ???
        nil
      end
    end

    def store(key,value)
      super(key.to_sym, value)
    end

    def merge(other_hash=nil, &block)
      unless other_hash.nil?
        super(other_hash.to_symbolized_hash, &block)
      else
        super(other_hash, &block)
      end
    end

    def merge!(other_hash=nil, &block)
      unless other_hash.nil?
        super(other_hash.to_symbolized_hash, &block)
      else
        super(other_hash, &block)
      end
    end

    def self.from(hash={})
      h= new
      h.merge!(hash)
      h
    end
  
  end

end