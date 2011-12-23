require 'minitest/spec'
require 'minitest/autorun'
require 'gumdrop'

describe Gumdrop::HashObject do
  before do
    @ho= Gumdrop::HashObject.new one:"ONE", two:"TWO", three:'THREE'
  end

  it "can be created with no arguments" do
    Gumdrop::HashObject.new.must_be_instance_of Gumdrop::HashObject
  end

  it "can be used as a standard hash" do
    @ho[:one].must_equal "ONE"
  end

  it "can be used as a standard with either a sym or string key" do
    @ho[:two].must_equal "TWO"
    @ho['two'].must_equal "TWO"
  end

  it "can be accessed like an object" do
    @ho.three.must_equal "THREE"
  end

  it "should return nil for an unknown key" do
    @ho.timmy.must_be_nil
  end

end