require_relative 'spec_helper'

describe Gumdrop::Util::HashObject do
  before do
    @ho= Gumdrop::Util::HashObject.from one:"ONE", two:"TWO", three:'THREE'
  end

  it "can be created with no arguments" do
    Gumdrop::Util::HashObject.new.must_be_instance_of Gumdrop::Util::HashObject
  end

  it "can be used as a standard hash" do
    @ho[:one].must_equal "ONE"
  end

  it "can be used as a standard hash with either a sym or string key" do
    @ho[:two].must_equal "TWO"
    @ho['two'].must_equal "TWO"

    @ho[:two]= "two"
    @ho[:two].must_equal "two"
    @ho['two'].must_equal "two"

    @ho['two']= "too"
    @ho[:two].must_equal "too"
    @ho['two'].must_equal "too"
  end

  it "can be accessed like an object" do
    @ho.three.must_equal "THREE"
  end

  it "can be assigned like an object" do
    @ho.stuff= 'junk'
    @ho.stuff.must_equal "junk"
    @ho[:stuff].must_equal "junk"
    @ho['stuff'].must_equal "junk"
  end

  it "should return nil for an unknown key" do
    @ho.timmy.must_be_nil
    @ho[:timmy].must_be_nil
    @ho['timmy'].must_be_nil
  end

  it "should store keys as symbols" do
    @ho.first= 1
    @ho[:second]= 2
    @ho['third']= 4
    @ho.store 'fourth', 4
    @ho.keys.each do |key|
      assert key.class == Symbol, "key isn't a symbol"
    end
  end

  it "should store keys as symbols when merge too" do
    @ho.merge!({ "fifth"=>5 })
    @ho.keys.each do |key|
      assert key.class == Symbol , "key isn't a symbol"
    end
  end

  it "extends Hash with to_symbolized_hash" do
    h= {"one"=>1, "two"=>2}.to_symbolized_hash
    h.keys.each do |key|
      assert key.class == Symbol , "key isn't a symbol"
    end
  end

  it "extends Hash with to_hash_object" do
    ho= { "fifth"=>5 }.to_hash_object
    ho.must_be_instance_of Gumdrop::Util::HashObject
    ho.fifth.must_equal 5
  end

end
