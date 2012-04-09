
require 'trollop'

banner_text= <<-EOS

Gumdrop v#{ Gumdrop::VERSION }
The simple, sweet, static CMS.

EOS

opts = Trollop::options do
  banner banner_text

  opt :verbose,"Verbose output"
  opt :debug,  "Enable debugging output"
  opt :quiet,  "No console output"

  if Gumdrop.in_site_folder?
    banner <<-EOS

Examples:
  gumdrop --build
  gumdrop -b
  gumdrop --new Post
  gumdrop --server
  gumdrop -s -p 8080 -r

Options:
EOS
    opt :build,  "Build HTML output"
      opt :environment, "Specify config.env", :type=>String, :default=>'production'
    opt :new, "Create new data item (specify collection name)", :type=>String
    opt :server, "Runs development server"
      opt :port, "Specifies port to run server on", :type=>:int
      opt :reload, "Force reloading on dev server"
    opt :template, "Create local template from this site (specify template name)", :type=>String
  else
    banner <<-EOS

Examples:
  gumdrop --create my_site
  gumdrop -c new_site --template backbone

Options:
EOS
    opt :create, "Create a gumdrop project", :type=>String
    opt :template, "Template to create new project from", :type=>String, :default=>'default'
    opt :list, "List available templates"
  end

end

# NO COMMANDS GIVEN

unless opts[:create_given] or opts[:build_given] or opts[:server_given] or opts[:new_given] or opts[:template_given] or opts[:list_given]
  puts banner_text
  Trollop::die "No commands specified"
end

Gumdrop::DEFAULT_OPTIONS[:env]= opts[:environment] || 'production'

# BUILD

if opts[:build_given]
  puts banner_text unless opts[:quiet_given]
  Gumdrop.run(opts)


# SERVER

elsif opts[:server_given]
  puts banner_text unless opts[:quiet_given]
  Gumdrop::Server


# LIST TEMPLATES

elsif opts[:list_given]
  # List templates
  puts banner_text unless opts[:quiet_given]
  here= File.dirname(__FILE__)
  lib_dir= File.expand_path File.join(here, '../../templates', '*')
  user_dir=  File.expand_path File.join("~", ".gumdrop", "templates", "*")
  puts "Gem Templates:"
  Dir[lib_dir].each do |name|
    puts "  #{File.basename name}" if File.directory?(name)
  end
  puts "Local Templates:"
  Dir[user_dir].each do |name|
    puts "  #{File.basename name}" if File.directory?(name)
  end


# NEW DATA COLLECTION ITEM

elsif opts[:new_given]
  puts banner_text unless opts[:quiet_given]
  puts "Not implemented yet..."


# CREATE NEW SITE

elsif opts[:create_given]
  puts banner_text unless opts[:quiet_given]

  require 'fileutils'
  here= File.dirname(__FILE__)
  lib_root= File.expand_path File.join(here, '../../')
  user_gumdrop_dir=  File.expand_path File.join("~", ".gumdrop")
  there= File.expand_path( opts[:create] )
  template_name = opts[:template]
  
  if File.file? there
    puts "You cannot specify a file as the target!" 
  elsif !File.directory? there
    FileUtils.mkdir_p there
  end
  
  # from gem...
  if File.directory? File.join(lib_root, 'templates', template_name)
    # FileUtils.cp_r Dir[File.join(here, "template", template_name, "*")], there
    puts "Creating gumdrop project (from template:#{template_name})"
    puts "  #{there}"
    FileUtils.cp_r File.join(lib_root, "templates", template_name, "."), there
    puts "Done."

  # local template...
  elsif File.directory? File.join(user_gumdrop_dir, 'templates', template_name)
    # FileUtils.cp_r Dir[File.join(here, "template", template_name, "*")], there
    puts "Creating gumdrop project (from local template:#{template_name})"
    puts "  #{there}"
    FileUtils.cp_r File.join(user_gumdrop_dir, "templates", template_name, "."), there
    puts "Done."

  else
    puts "Invalid template '#{template_name}'!"
  end


# SAVE CURRENT SITE AS TEMPLATE

elsif opts[:template_given]
  # Save as template...
  puts banner_text unless opts[:quiet_given]
  template= opts[:template]
  template_path = File.expand_path File.join('~', '.gumdrop', 'templates', template)
  if File.exists? template_path
    puts "A template named '#{template}' already exists!"
  else
    require 'fileutils'
    puts "Creating template:  #{template}"
    puts "  ~/.gumdrop/templates/#{template}"
    site_root= Gumdrop.site_folder
    FileUtils.mkdir_p File.dirname(template_path)
    FileUtils.cp_r File.join(site_root, "."), template_path
    puts "Done."
  end
  

# UNKNOWN COMMAND

else
  puts banner_text
  require 'pp'
  puts "Unknown options"
  pp opts
end
