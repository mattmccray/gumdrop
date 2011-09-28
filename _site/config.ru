require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'gumdrop'

Gumdrop.config.auto_run= false
Gumdrop.config.force_reload= true
Gumdrop.run :dry_run=>true 

run Gumdrop::Server
