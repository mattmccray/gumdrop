module Gumdrop::ViewHelpers
  
  # Calculate the years for a copyright
  def copyright_years(start_year, divider="&#8211;")
    end_year = Date.today.year
    if start_year == end_year
      "#{start_year}"
    else
      "#{start_year}#{divider}#{end_year}"
    end
  end
  
  def page_classes(extra="")
    %Q|#{ page.slug } #{ page.uri.gsub('/','-').gsub('.html', '') } #{ extra }|
  end
  
end