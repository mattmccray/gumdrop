module Gumdrop::Util

  class HashObject < Hash

    # All keys are symbols, internally
    def [](key)
      super(key.to_sym)
    end
    def []=(key, value)
      if value.is_a? Hash
        value= HashObject.from value, true
      end
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

    def get(key)
      self[key]
    end
    def set(key,value=nil)
      if key.is_a? Hash
        key.each do |k,v|
          self[k]= v
        end
      else
        self[key]= value
      end
    end

    def has_key?(key)
      super key.to_sym
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

    def self.from(hash={}, recurse=true)
      h= new
      if recurse
        hash.each do |key, value|
          if value.is_a? Hash
            hash[key]= HashObject.from value
          end
        end
      end
      h.merge!(hash)
      h
    end
  
  end

end