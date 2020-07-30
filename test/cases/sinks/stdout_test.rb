module Sinks
  class StdoutTest < TestCase
    let(:msg) { { hello: 'world' } }
    let(:sink) { Aws::Embedded::Metrics::Sinks::Stdout.new }

    it 'initializes with no arguments' do
      expect(sink).must_be_instance_of Aws::Embedded::Metrics::Sinks::Stdout
    end

    it '#accept dumps its message as json to stdout' do
      STDOUT.expects(:puts).with(JSON.dump(msg)).once
      sink.accept(msg)
    end
  end
end
