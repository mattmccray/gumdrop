module Gumdrop::Data
  class SqliteDataProvider < Provider

    extensions :sqlite, :sqlite3, :db

    def available?
      require 'sqlite3'
      true
    rescue LoadError
      false
    end

    def data_for(filepath)
      @db= SQLite3::Database.new( filepath )
      @live= SqliteLiveData.new @db, self
    end

  end

  class SqliteLiveData
    attr_reader :db, :provider

    def initialize(db, provider)
      @db= db
      @provider= provider
      @data_hash= Hash.new &method(:load_data_for)
    end

    def load_data_for(hash, table_name)
      data=[]
      db.results_as_hash = true
      db.execute( "select * from #{ table_name.to_s };" ) do |row|
        data << row.reject {|key,col| key.is_a? Fixnum }
      end
      hash[table_name]= provider.supply_data data
    end

    def method_missing(key, *args)
      @data_hash[key]
    end

  end
end
