require 'minitest/spec'
require 'minitest/autorun'
require 'gumdrop'
#require File.join File.dirname(__FILE__), 'diff.rb'

fixture_src_path= File.join ".", "specs", "fixtures", "source"
fixture_exp_path= File.join ".", "specs", "fixtures", "expected"

def get_test_site
  site= Gumdrop::Site.new File.join(".", "specs", "fixtures", "source", 'Gumdrop'), :quiet=>true
  site.rescan
end

def get_expected(filename)
  path= File.join ".", "specs", "fixtures", "expected", filename
  File.read path
end

describe Gumdrop::Content do
  # before do
  #   @ho= Gumdrop::HashObject.new one:"ONE", two:"TWO", three:'THREE'
  # end

  it "should process the content through all the engines specified in the file ext" do
    
    # path= File.join fixture_src_path, 'Gumdrop'
    # site= Gumdrop::Site.new path, :quiet=>true
    # site.rescan
    site= get_test_site

    path= File.join fixture_src_path, 'test.js.erb.coffee'
    content= Gumdrop::Content.new( path, site )

    path= File.join fixture_exp_path, 'test.js'
    expected= File.read path

    content= content.render()

    # puts content
    # puts expected

    content.must_equal expected
  end

  it "should relativize all absolute paths (when starts with /)" do
    site= get_test_site
    # puts site.content_hash.keys

    page= site.contents('posts/post1.html').first
    content= page.render
    expected= get_expected('posts/post1.html')
    # puts content
    content.must_equal expected

    page= site.contents('posts/post1.js').first
    content= page.render
    # puts content
    content.must_equal get_expected('posts/post1.js')

    page= site.contents('sub/sub/sub/test.html').first
    content= page.render
    # puts content
    content.must_equal get_expected('sub/sub/sub/test.html')

    page= site.contents('sub/sub/sub/test2.html').first
    content= page.render
    # puts content
    content.must_equal get_expected('sub/sub/sub/test2.html')
  end

  # it "can be created with no arguments" do
  #   Gumdrop::HashObject.new.must_be_instance_of Gumdrop::HashObject
  # end

  # it "can be used as a standard hash" do
  #   @ho[:one].must_equal "ONE"
  # end

  # it "can be used as a standard with either a sym or string key" do
  #   @ho[:two].must_equal "TWO"
  #   @ho['two'].must_equal "TWO"
  # end

  # it "can be accessed like an object" do
  #   @ho.three.must_equal "THREE"
  # end

  # it "should return nil for an unknown key" do
  #   @ho.timmy.must_be_nil
  # end

end