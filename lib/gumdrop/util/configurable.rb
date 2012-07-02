module Gumdrop::Util

  module Configurable
    module ClassMethods

      def config_accessor(*keys)
        keys.each do |key|
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{key}; config[#{key.inspect}]; end
            def #{key}=(value); config[#{key.inspect}]= value; end
          RUBY
        end
      end

    end
    
    module InstanceMethods

      def config
        @config ||= HashObject.new
      end

      def configure(&block)
        if block.arity == 1
          block.call config
        else
          block.instance_eval &block
        end
      end

    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end

end
