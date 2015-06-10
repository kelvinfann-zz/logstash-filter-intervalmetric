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
        config = {"counter" => ["one"], "count_interval" => 5}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        filter.filter LogStash::Event.new({"response" => 200})
        filter.flush
        filter.flush
        filter.flush
      } 
      it "should have a counter of 1" do
        insist { subject.length } == 1
        insist { subject.first["one.count"] } == 1 
      end # it "should output one"
      it "random counter test" do
        config = {"counter" => ["six"], "count_interval" => 5}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        r = rand(2..100)
        for i in 1..r
          filter.filter LogStash::Event.new({"response" => i})
        end # for i in 0..r
        event = filter.flush
        event = filter.flush
        insist { event.length } == 1
        insist { event.first["six.count"] } == r
      end # it "should output 6"
    end # context "when one event was received"
    context "when one event was received" do 
    end # context "when multiple events were received"
    context "when we have different counters" do
      subject {
        config = {"counter" => ["%{response}"], "count_interval" => 5}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        filter.filter LogStash::Event.new({"response" => 200})
        filter.filter LogStash::Event.new({"response" => 400})
        filter.filter LogStash::Event.new({"response" => 200})
        filter.flush
        filter.flush
      } 
      it "should have a counter of 1" do
        insist { subject.length } == 1
        insist { subject.first["200.count"] } == 2
        insist { subject.first["400.count"] } == 1 
      end # it "should have multiple counters"          
    end # context "when we have different counters"
  end # context "basic counter"
end # describe Logstash::Filters:IntervalMetric
