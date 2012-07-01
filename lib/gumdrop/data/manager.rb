module Gumdrop::Data
  
  class Manager

    attr_accessor :sources

    def initialize(data_path=nil)
      @sources= data_path.nil? ? {} : { '' => [data_path] }
    end

    def add_path(path, scope="")
      if @sources[scope]
        @sources[scope] << path
      else
        @sources[scope]= [path]
      end
      self
    end

    def clear
      # removed memoized data
    end

    def reset
      # clear()
      # clear @sources too
    end

  end

end