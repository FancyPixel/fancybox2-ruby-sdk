module Fancybox2::Module::Exceptions

  describe FbxfileNotFound do
    let(:exception) { FbxfileNotFound }
    let(:file_path) { '/some/path' }

    it 'is expected to require file_path param' do
      expect { exception.new }.to raise_error ArgumentError
    end

    it 'is expected to raise a FbxfileNotFound error' do
      expect { raise exception.new(file_path) }.to raise_error exception, /#{file_path}/
    end

    it 'is expected to be a subclass of StandardError' do
      expect(exception.new(file_path)).to be_a StandardError
    end
  end

  describe NotValidMQTTClient do
    let(:exception) { NotValidMQTTClient }

    it 'is expected to be a subclass of StandardError' do
      expect(exception.new).to be_a StandardError
    end

    it 'is expected to raise a NotValidMQTTClient error' do
      expect { raise exception.new }.to raise_error exception, /PahoMqtt::Client/
    end
  end
end
