lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'gumdrop/version'

now= Time.new

Gem::Specification.new do |s|
   s.name = %q{gumdrop}
   s.version = Gumdrop::VERSION
   s.platform = Gem::Platform::RUBY
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
   
   s.add_dependency 'thor'
   s.add_dependency 'tilt'
   s.add_dependency 'active_support'
   s.add_dependency 'onfire'
   s.add_dependency 'sinatra'
   s.add_dependency 'i18n'
   s.add_dependency 'launchy'
   s.add_dependency 'bundle'

   s.add_development_dependency 'minitest'
   s.add_development_dependency 'sqlite3'
   s.add_development_dependency 'sprockets'
   s.add_development_dependency 'stitch'
   s.add_development_dependency 'jsmin'

end
