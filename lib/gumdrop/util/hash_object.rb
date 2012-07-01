require 'active_support/hash_with_indifferent_access'

module Gumdrop::Util

  class HashObject < Hash
    # ActiveSupport::HashWithIndifferentAccess

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
      if other_hash
        super(other_hash.to_symbolized_hash, &block)
      else
        super(other_hash, &block)
      end
    end

    def merge!(other_hash=nil, &block)
      if other_hash
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

  class ::Hash

    def to_symbolized_hash
      new_hash= {}
      self.each {|k,v| new_hash[k.to_sym]= v }
      new_hash
    end

    def to_hash_object
      HashObject.from self
    end

  end

end