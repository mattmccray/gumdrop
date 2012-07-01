require_relative 'spec_helper'

if ENV['RUN'] != 'output' and ENV['RUN'] != 'output_only'
  puts 
  puts "Output tests are NOT being run!"
  puts
  puts "To run output tests run:"
  puts "  RUN=output rake test"
  puts "or:"
  puts "  RUN=output_only rake test"
  puts

else
  describe "Generated Output" do

    it "output should be expected" do
      site_for_source()
      Gumdrop.build
      Dir[ Gumdrop.site.output_path / "**" / "*"].each do |output_path|
        next if File.directory?(output_path)
        rel= (output_path.gsub Gumdrop.site.output_path, '')[1..-1]
        expected_path= fixture_exp rel
        # puts " --> #{rel}"
        assert FileUtils.identical?(output_path, expected_path), "#{rel} is different than expected"
      end
    end

  end
end
