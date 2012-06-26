require 'minitest/spec'
require 'minitest/autorun'
require 'gumdrop'

describe Gumdrop::Content do
  # before do
  #   @ho= Gumdrop::HashObject.new one:"ONE", two:"TWO", three:'THREE'
  # end

  it "should process the content through all the engines specified in the file ext" do
    
    path= File.join ".", "specs", "fixtures", 'Gumdrop'
    site= Gumdrop::Site.new path

    path= File.join ".", "specs", "fixtures", 'test.js.erb.coffee'
    content= Gumdrop::Content.new( path, site )

    path= File.join ".", "specs", "fixtures", 'expected-test.js'
    expected= File.read path

    content= content.render()

    # puts content
    # puts expected

    content.must_equal expected

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