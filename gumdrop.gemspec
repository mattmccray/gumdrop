lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'gumdrop/version'

now= Time.new

Gem::Specification.new do |s|
   s.name = %q{gumdrop}
   s.version = Gumdrop::VERSION
   s.platform = Gem::Platform::RUBY
   s.license = 'MIT'
   s.rubyforge_project = 'gumdrop'
   s.has_rdoc = false
   s.date = now.strftime("%Y-%m-%d")

   s.authors = ["Matt McCray"]
   s.email = %q{matt@elucidata.net}
   s.summary = %q{The sweet 'n simple cms and prototyping tool.}
   s.homepage = %q{https://github.com/darthapo/gumdrop}
   s.description = %q{The sweet 'n simple cms and prototyping tool for creating static html websites and webapps.}

   s.files         = `git ls-files`.split("\n")
   s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
   s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
   s.require_paths = ["lib"]
   
   s.add_dependency 'thor', '0.15.4'
   s.add_dependency 'tilt', '1.3.3'
   # s.add_dependency 'tilt', '1.4.0'
   s.add_dependency 'activesupport', '3.0.0'
   s.add_dependency 'onfire', '0.2.0'
   s.add_dependency 'sinatra', '1.3.2'
   s.add_dependency 'i18n', '0.6.0'
   s.add_dependency 'launchy', '0.4.0'
   # s.add_dependency 'bundler', ''
   # s.add_dependency 'sprockets', '2.4.3'
   # s.add_dependency 'sprockets', '2.10.0'
   # s.add_dependency 'stitch', '0.1.6'
   # s.add_dependency 'stitch-rb', '0.0.8'
   # s.add_dependency 'jsmin', '1.0.1'
   # s.add_dependency 'json', '~> 1.7.7'

   s.add_development_dependency 'minitest', '3.2.0'
   s.add_development_dependency 'sqlite3', '1.3.6'
   
end
