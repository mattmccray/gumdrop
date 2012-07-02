# TODO: This will take a bit more work.
=begin

1 - Grab all the table names from master?
2 - Return a giant hash of hashes?
     - Outer hash key would be table_name, contains
     - Array of hashes for each row
     - Row hash is column_name/value pair.  

Load all the data, or should the Provider API be extended to support
returning a smart object that could query tables as they are requested?

=end
module Gumdrop::Data
  class SqliteDataProvider < Provider

    extensions :sqlite, :sqlite3, :db #db?

    def available?
      require 'sqlite3'
      true
    rescue
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
      db.execute( "select * from #{ table_name.to_s }" ) do |row|
        data << row
      end
      hash[table_name]= provider.supply_data data
    # rescue
    #   nil
    end

    def method_missing(key, *args)
      @data_hash[key]
    end

  end
end
