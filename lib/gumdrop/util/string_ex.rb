require 'pathname'

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

end