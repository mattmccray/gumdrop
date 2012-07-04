require_relative 'spec_helper'

if ENV['RUN'] != 'output'
  puts 
  puts "Output tests are NOT being run!"
  puts
  puts "To run output tests run:"
  puts "  rake test RUN=output"
  puts

else
  puts 
  puts "Testing the generated output against expectations from fixtures."
  puts


  describe "Generated Output" do

    # FIX ME: This should really be smarter, looking for missing content too.

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
