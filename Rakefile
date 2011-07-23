$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "gumdrop/version"
 
desc "builds gem"
task :build do
  system "gem build gumdrop.gemspec"
end
 
desc "releases gem"
task :release => :build do
  system "gem push gumdrop-#{Gumdrop::VERSION}.gem"
end

desc "installs gem"
task :install => :build do
  system "gem install gumdrop-#{Gumdrop::VERSION}"
end

desc "uninstalls gem"
task :uninstall do
  system "gem uninstall gumdrop"
end
