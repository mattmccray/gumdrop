module Gumdrop::Data
  class PStoreDataProvider < Provider

    extension :pstore

    def available?
      require 'pstore'
      true
    rescue
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
      to_open_structs data
    end

  end
end
