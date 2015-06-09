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
        config = {"counter" => ["one"], "count_interval" => -5}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        filter.filter LogStash::Event.new({"response" => 200})
        filter.flush
      } 
      it "should have a counter of 1" do
        insist { subject.length } == 1
        insist { subject.first["one.count"] } == 1 
      end # it "should output one"
      it "should have a counter of 6" do
        config = {"counter" => ["six"], "counter_interval => 0"}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        for i in 0..6
          filter.filter LogStash::Event.new({"response" => i})
        end # for i in 0..6
        event = filter.flush
        insist { event.length } == 1
        insist { event.first["six.count"] } == 6
      end # it "should output 6"
    end # context "when one event was received"
    context "when one event was received" do 
    end # context "when multiple events were received"

  end # context "basic counter"
end # describe Logstash::Filters:IntervalMetric
