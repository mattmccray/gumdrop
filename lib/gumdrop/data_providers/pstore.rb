module Gumdrop::Data
  class PStoreDataProvider < Provider

    extension :pstore

    def available?
      require 'pstore'
      true
    rescue LoadError
      false
    end

    def data_for(filepath)
      data={}
      store= PStore.new(filepath)
      store.transaction true do 
        store.roots.each do |root|
          data[root]= store[root]
        end
      end
      supply_data data
    end

  end
end
