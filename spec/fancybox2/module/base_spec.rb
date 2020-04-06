require 'spec_helper'

describe Fancybox2::Module::Base do

  context 'attr_accessors' do
    subject(:module_base_class) { Fancybox2::Module::Base.new }

    it { should have_attr_reader :logger }
  end

  describe 'initialize' do
    let(:module_base) { Fancybox2::Module::Base.new }

    it "is expected to set the logger" do
      expect(module_base.logger).to_not be_nil
    end

  end
end