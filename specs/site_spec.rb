require_relative 'spec_helper'
unless ENV['RUN'] == 'output_only'

describe Gumdrop::Site do

  it 'should be configured with default settings' do
    site= site_for_source
    site.config.wont_be_nil
  end

  it 'should have accessors for paths' do
    site= site_for_source
    site.config.source_dir.wont_be_nil
    site.config.source_dir.must_equal '.'
    site.source_dir.wont_be_nil
    site.source_dir.must_equal site.config.source_dir

    site.output_dir.wont_be_nil
    site.output_dir.must_equal '../output'

    site.data_dir.wont_be_nil
    site.data_dir.must_equal './data'
  end

  it 'should allow changing config settings' do
    site= site_for_source
    site.source_dir.must_equal '.'
    site.source_dir.must_equal site.config.source_dir

    site.config.source_dir= './crap'
    site.config.source_dir.must_equal './crap'
    site.source_dir.must_equal site.config.source_dir
  end

  it 'should allow listening for events' do
    site= site_for_source
    scanned= 0
    site.on :scan do |event|
      scanned += 1
    end
    site.clear true
    site.scan true
    scanned.must_equal 1
  end

  it 'should allow listening for events from Gumdrop too' do
    site= site_for_source
    scanned= 0
    Gumdrop.site.clear true
    Gumdrop.site.on :scan do |event|
      scanned += 1
    end
    Gumdrop.on :before_scan do |event|
      scanned += 1
    end
    Gumdrop.on :scan do |event|
      scanned += 1
    end
    Gumdrop.on :after_scan do |event|
      scanned += 1
      #puts "#{event.data[:payload]} Items Scanned"
    end
    Gumdrop.site.scan
    scanned.must_equal 4
  end

  # it 'should allow changing config settings via block' do
  #   site= site_for_source
  #   site.source_dir.must_equal './source'
  #   site.source_dir.must_equal site.config.source_dir

  #   Gumdrop::Site.configure do |c|
  #     c.source_dir= './junk'
  #   end

  #   site.config.source_dir.must_equal './junk'
  #   site.source_dir.must_equal site.config.source_dir
  # end

end
end