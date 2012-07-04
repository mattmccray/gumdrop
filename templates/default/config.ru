Encoding.default_external = 'UTF-8'

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
  Bundler.require if File.exists?('Gemfile')
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'gumdrop'

#require 'rack/static'
#use Rack::Static, :urls => ["/media"], :root => "source"
#use Rack::Static, :urls => ["/theme/images"], :root => "source"


run Gumdrop::Server
