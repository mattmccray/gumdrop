require_relative 'spec_helper'

unless ENV['RUN'] == 'output_only'
  
describe Gumdrop::Content do
  
  it "must be instantiated with a file path" do
    content = content_for_source('test.html')
    content.wont_be_nil
  end

  it "it does not care if it is a real path or not" do
    content = content_for_source('test.html')
    content.wont_be_nil
  end

  describe 'generated?' do

    it "true if it was created with a generator" do
      content = content_for_source('test.html', generated:true)
      content.generated?.must_equal true
    end

  end

  describe 'ignore?' do

    it "false by default" do
      content = content_for_source('test.html')
      content.ignore?.must_equal false
    end

    it "true if ignored(true) called" do
      content = content_for_source('test.html')
      content.ignore?.must_equal false
      content.ignore true
      content.ignore?.must_equal true
      content.ignore false
      content.ignore?.must_equal false
    end

  end

  describe 'binary?' do

    it "true if bin file" do
      content = content_for_source('image.png')
      content.binary?.must_equal true
    end

    it "false if text file" do
      content = content_for_source('test.html')
      content.binary?.must_equal false
    end

  end

  describe 'exists?' do

    it "return true for existing files" do
      content = content_for_source('test.html')
      exist= content.exists?
      exist.must_equal true
    end
    it "return false for missing files" do
      content = content_for_source('missing.html')
      content.must_be_nil

      # Should a file magically disappear
      content= Gumdrop::Content.new('crap.head.html')
      exist= content.exists?
      exist.must_equal false
    end
    it "return true for generated files" do
      content = content_for_source('crap.html', generated:true)
      exist= content.exists?
      exist.must_equal true
    end

  end

  describe 'body()' do

    it "returns file contents for non binary files" do
      content= content_for_source 'test.html'
      expected= File.read(fixture_src('test.html.erb'))
      content.body.must_be_sorta_like expected
    end

    it "returns nil for binary files" do
      content= content_for_source 'image.png'
      content.body.must_be_nil
    end

    it "returns block content when provided" do
      content= Gumdrop::Content.new '', nil do
        "Hello"
      end
      content.body.must_equal 'Hello'
    end

  end

end

end
