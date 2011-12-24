
require 'stitch'


class Stitch::Source
  # Patch for gumdrop style filenames
  def name
    name = path.relative_path_from(root)
    name = name.dirname + name.basename(".*")
    name.to_s.gsub(".js", '')
  end
end


