require 'spec_helper'
require "logstash/filters/example"

describe LogStash::Filters::Example do
  context "basic counter" do
    context "when no events were received" do
      it "should not do anything" do
        config = {}
        filter = LogStash::Filters::Metrics.new config
        filter.register
        events = filter.flush
        insist { events }.nil? 
      end # it "should not do anything"
    end # context "no events were receieved"
  end # context "basic counter"
end # describe Logstash::Filters:Example
