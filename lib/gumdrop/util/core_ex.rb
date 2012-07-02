require 'pathname'

class Hash

  def to_symbolized_hash
    new_hash= {}
    self.each {|k,v| new_hash[k.to_sym]= v }
    new_hash
  end

  def to_hash_object
    Gumdrop::Util::HashObject.from self
  end

  def ends_with?(string)
    self[0..(string.length)] == string
  end

  def starts_with?(string)
    self[0..(string.length)] == string
  end

end

class String
  
  def / (other)
    File.join self, other
  end

  def relative
    dup.relative!
  end

  def relative!
    sub! /^[\/]/, ''
    self
  end

  def expand_path(relative_to=nil)
    if (Pathname.new self).absolute?
      self
    elsif relative_to.nil?
      File.expand_path self
    else
      File.expand_path relative_to / self
    end
  end

  def path_match?(pattern)
    File.fnmatch pattern, self, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_CASEFOLD
  end

  # alias_method :starts_with?, :start_with?
  # alias_method :ends_with?, :end_with?

end


# module PathTools

#   def / (other)
#     self.join other.to_s
#   end

#   def - (other)
#     Pathname.new self.to_s.gsub(other, '')
#   end

#   def match?(other)
#     fnmatch? pattern, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_CASEFOLD
#   end

# end

# class Pathname
#   include PathTools
# end

# class String
#   def to_pathname
#     Pathname.new self
#   end
# end