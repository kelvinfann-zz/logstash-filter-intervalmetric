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
    context "when nothing should be counted" do
      subject {
        config = {"counter" => ["one"], "count_interval" => 30}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        filter.filter LogStash::Event.new({"response" => 200})
        for _ in 1..6
          filter.flush
        end
        filter.flush
      } 
      it "should have a counter of 1" do
        insist { subject.length } == 1
        insist { subject.first["one.count"].first[1] } == 0  
      end # it "should output one"
    end # context "when one event was received"
    
    context "when one event was received" do
      subject {
        config = {"counter" => ["one"], "count_interval" => 10}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        filter.filter LogStash::Event.new({"response" => 200})
        for _ in 1..4
          filter.flush
        end
        filter.flush
      } 
      it "should have a counter of 1" do
        insist { subject.length } == 1
        insist { subject.first["one.count"].first[1] } == 1 
      end # it "should output one"
    end # context "when one event was received"
    context "when one empty event was received" do
      subject {
        config = {"counter" => ["one"], "count_interval" => 10, "persist_counters" => ["one"]}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        for _ in 1..4
          filter.flush
        end
        filter.flush
      } 
      it "should have a counter of 1" do
        insist { subject.length } == 1
        insist { subject.first["one.count"].first[1] } == 0 
      end # it "should output one"
    end # context "when one event was received"
    
    context "When random num events are recieved" do
       it "should get a random counter" do
        config = {"counter" => ["Random"], "count_interval" => 10}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        r = rand(2..100)
        for i in 1..r
          filter.filter LogStash::Event.new({"response" => i})
        end # for i in 0..r
        for _ in 1..5
            event = filter.flush
        end
        insist { event.length } == 1
        insist { event.first["Random.count"].first[1] } == r
      end # it "should get a random counter"
    end # context "When random num events are recieved"
    context "when a random interval is set and only 1 event" do
      it "should delete that event after two intervals" do
        for _ in 1..10
          count_interval = rand(2..100)
          config = {"counter" => ["%{response}"], "count_interval" => count_interval*5}
          filter = LogStash::Filters::IntervalMetric.new config
          filter.register
          filter.filter LogStash::Event.new({"response" => 200})
          for _ in 1..count_interval-1
            event = filter.flush
          end # for _ in 1..count_interval-1
          for i in count_interval..rand(count_interval*2+1..300)
            event = filter.flush
            if i % count_interval != 1 
              insist { event }.nil? 
            elsif i > count_interval*2 + 1
              insist { event } != nil
              insist { event.first['has_values'] } == false
            else
              insist { event } != nil
            end # if i*5 % ...
          end # for i in count_interval..rand( ...
        end # for _ in 1..10
      end # it "should produce nil on all times except interval+5" do
    end # context "when a random interval is set" do 
    context "when a random interval is set" do
      it "should produce nil on all times except interval+5" do
        for _ in 1..10
          count_interval = rand(2..99)
          config = {"counter" => ["%{response}"], "count_interval" => count_interval*5}
          filter = LogStash::Filters::IntervalMetric.new config
          filter.register
          filter.filter LogStash::Event.new({"response" => 200})
          for __ in 1..count_interval-1
            event = filter.flush
          end # for __ in 1..count_interval-1
          for i in count_interval..rand(count_interval+1..100)
            filter.filter LogStash::Event.new({"response" => 200})
            event = filter.flush
            if i % count_interval != 1 
              insist { event }.nil? 
            else
              insist { event } != nil
            end # if i*5 % ...
          end # for i in count_interval..rand( ...
        end # for _ in 1..10
      end # it "should produce nil on all times except interval+5" do
    end # context "when a random interval is set" do
    context "when we have different counters" do
      subject {
        config = {"counter" => ["%{response}"], "count_interval" => 10}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        filter.filter LogStash::Event.new({"response" => 200})
        filter.filter LogStash::Event.new({"response" => 400})
        filter.filter LogStash::Event.new({"response" => 200})
        for _ in 1..4
          filter.flush
        end 
        filter.flush
      } 
      it "should have a counter of 1" do
        insist { subject.length } == 1
        insist { subject.first["200.count"].first[1] } == 2
        insist { subject.first["400.count"].first[1] } == 1 
      end # it "should have multiple counters"          
    end # context "when we have different counters"
    context "Testing counter_interval" do
      it "Should have the same output as when we have different counters" do
      for _ in 0..10
        config = {"counter" => ["%{response}"], "count_interval" => 30}
        filter = LogStash::Filters::IntervalMetric.new config
        filter.register
        filter.filter LogStash::Event.new({"response" => 200})
        filter.filter LogStash::Event.new({"response" => 400})
        filter.filter LogStash::Event.new({"response" => 200})
        for _ in 1..6 
          filter.flush
        end
        event=filter.flush
        for _ in 1..5 
          filter.flush
        end
        event=filter.flush
        for _ in 1..5 
          filter.flush
        end
        event2=filter.flush
        if event2.first["has_values"] == true
          event = event2
        end
        insist { event.length } == 1
        insist { event.first["200.count"].first[1] } == 2 
        insist { event.first["400.count"].first[1] } == 1 
      end # it "should have multiple counters"          
      end
    end # context "Testing counter_interval"
  end # context "basic counter"
end # describe Logstash::Filters:IntervalMetric
