module Gumdrop
  module Callbacks
    
    # For defining callbacks
    def callback(*callback_names)
      callback_names.each do |name|
        class_eval <<-EOF
          def #{name}(*args, &block)
            if block
              @_#{name} = [] if @_#{name}.nil?
              @_#{name} << block
            elsif @_#{name} and !@_#{name}.nil?
              @_#{name}.each do |cb|
                cb.call(*args)
              end
            end
          end
          def clear_#{name}()
            @_#{name} = nil
          end
        EOF
      end
    end
  
    alias_method :callbacks, :callback
    alias_method :define_callback, :callback
    alias_method :define_callbacks, :callback
  
  end
end