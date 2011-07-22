lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'gumdrop/version'

Gem::Specification.new do |s|
   s.name = %q{gumdrop}
   s.version = Gumdrop::VERSION
   s.platform = Gem::Platform::RUBY
   s.rubyforge_project = 'gumdrop'
   s.date = %q{2011-07-22}
   s.authors = ["Matt McCray"]
   s.email = %q{matt@elucidata.net}
   s.summary = %q{A simple cms/prototyping tool.}
   s.homepage = %q{https://github.com/darthapo/gumdrop}
   s.description = %q{A simple cms/prototyping tool.}
   s.files        = Dir.glob("{bin,lib}/**/*") + %w(License Readme.md)
   s.executables  = ['gumdrop']
   s.has_rdoc = false
   s.test_files = []
end