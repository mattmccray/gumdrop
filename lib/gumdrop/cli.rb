
require 'trollop'

opts = Trollop::options do
  banner ""
  banner <<-EOS
  Gumdrop v#{ Gumdrop::VERSION }
  The simple, static, CMS.
  
  Examples:
      gumdrop --create my_new_site --template backbone
    Is the same as:
      gumdrop -c my_new_site -t backbone
  
  Options:
EOS
  opt :verbose,"Verbose output"
  opt :debug,  "Enable debugging output"
  opt :quiet,  "No output"
  opt :create, "Create a gumdrop project", :type=>String
    opt :template, "Specify template to use for new project (default || backbone)", :type=>String, :default=>'default'
  opt :build,  "Build HTML output"
  opt :server, "Runs development server"
    opt :port, "Specifies port to run server on", :type=>:int
end

# Trollop::die :volume, "must be non-negative" if opts[:volume] < 0
# Trollop::die :file, "must exist" unless File.exist?(opts[:file]) if opts[:file]

unless opts[:create_given] or opts[:build_given] or opts[:server_given]
  Trollop::die "You must specify one of --create --build --server"
end


if opts[:create_given]
  require 'fileutils'
  here= File.dirname(__FILE__)
  there= File.expand_path( opts[:create] )
  template_name = opts[:template]
  
  if File.file? there
    puts "You cannot specify a file as the target!" 
  elsif !File.directory? there
    FileUtils.mkdir_p there
  end
  
  if File.directory? File.join(here, 'template', template_name)
    # FileUtils.cp_r Dir[File.join(here, "template", template_name, "*")], there
    puts "Creating gumdrop project based on #{template_name} template at #{there}"
    FileUtils.cp_r File.join(here, "template", template_name, "."), there
    puts "Done."
  else
    puts "Invalid template '#{template_name}'!"
  end
  
elsif opts[:build_given]
  Gumdrop.run(opts)

elsif opts[:server_given]
  Gumdrop.config.auto_run= true
  Gumdrop::Server

else
  require 'pp'
  puts "Unknown options"
  pp opts
end
