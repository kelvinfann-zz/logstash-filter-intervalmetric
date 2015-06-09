require 'logstash/devutils/rspec/spec_helper'
require "logstash/filters/intervalmetric"

describe LogStash::Filters::IntervalMetric do
  context "basic counter" do
    context "when no events were received" do
      it "should not do anything" do
        config = {}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        events = filter.flush
        insist { events }.nil? 
      end # it "should not do anything"
    end # context "no events were receieved"
    context "when one event was received" do
      subject {
        config = {"counter" => ["one"]}
        filter = Logstash::Filters::IntervalMetric.new config
        filter.register
        filter.filter LogStash::Event.new({"response" => 200})
        filter.flush
      } 
      it "should output one" do
        insist { subject.length } == 1
        insist { subject.first["one.count"] } == 1 
      end
    end
  end # context "basic counter"
end # describe Logstash::Filters:IntervalMetric
