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
        config = {"counter" => ["one"], "count_interval" => 10}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        filter.filter LogStash::Event.new({"response" => 200})
        for _ in 1..4
          filter.flush
        end
      } 
      it "should have a counter of 1" do
        insist { subject.length } == 1
        insist { subject.first["one.count"] } == 1 
      end # it "should output one"
      it "random counter test" do
        config = {"counter" => ["Random"], "count_interval" => 5}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        r = rand(2..100)
        for i in 1..r
          filter.filter LogStash::Event.new({"response" => i})
        end # for i in 0..r
        for _ in 1..4
            event = filter.flush
        end
        insist { event.length } == 1
        insist { event.first["Random.count"] } == r
      end # it "should output 6"
    end # context "when one event was received"
    context "when we have different counters" do
      subject {
        config = {"counter" => ["%{response}"], "count_interval" => 5}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        filter.filter LogStash::Event.new({"response" => 200})
        filter.filter LogStash::Event.new({"response" => 400})
        filter.filter LogStash::Event.new({"response" => 200})
        for _ in 1..4
          filter.flush
        end 
      } 
      it "should have a counter of 1" do
        insist { subject.length } == 1
        insist { subject.first["200.count"] } == 2
        insist { subject.first["400.count"] } == 1 
      end # it "should have multiple counters"          
    end # context "when we have different counters"
    context "when we have different counters" do
      subject {
        config = {"counter" => ["%{response}"], "count_interval" => 5}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        filter.filter LogStash::Event.new({"response" => 200})
        filter.filter LogStash::Event.new({"response" => 400})
        filter.filter LogStash::Event.new({"response" => 200})
         for _ in 1..4
          filter.flush
        end 
      } 
      it "should have a counter of 1" do
        insist { subject.length } == 1
        insist { subject.first["200.count"] } == 2
        insist { subject.first["400.count"] } == 1 
      end # it "should have multiple counters"          
    end # context "when we have multiple "
    context "Testing counter_interval" do
      subject {
        config = {"counter" => ["%{response}"], "count_interval" => 30}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        filter.filter LogStash::Event.new({"response" => 200})
        filter.filter LogStash::Event.new({"response" => 400})
        filter.filter LogStash::Event.new({"response" => 200})
        for _ in 1..7 
          filter.flush
        end
      } 
      it "Should have the same output as when we have different counters" do
        insist { subject.length } == 1
        insist { subject.first["200.count"] } == 2
        insist { subject.first["400.count"] } == 1 
      end # it "should have multiple counters"          
    end # context "when we have multiple "
  end # context "basic counter"
end # describe Logstash::Filters:IntervalMetric
