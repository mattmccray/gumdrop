require_relative 'spec_helper'

describe Gumdrop::Renderer do

  it 'should be instantiatable' do
    r= Gumdrop::Renderer.new
    r.wont_be_nil
  end

end
