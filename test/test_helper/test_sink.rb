class TestSink
  attr_reader :metrics

  def initialize
    @metrics = []
  end

  def accept(message)
    @metrics << message
  end
end
