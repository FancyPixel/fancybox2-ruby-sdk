require 'spec_helper'

describe Fancybox2::Module::Base do

  context 'attr_accessors' do
    subject(:module_base_class) { Fancybox2::Module::Base.new }

    it { should have_attr_reader :logger }
  end
end