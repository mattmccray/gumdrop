require_relative 'spec_helper'
unless ENV['RUN'] == 'output_only'

describe Gumdrop::Renderer do

  it 'should be instantiatable' do
    r= Gumdrop::Renderer.new
    r.wont_be_nil
  end

end
end