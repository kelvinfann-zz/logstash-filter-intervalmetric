# encoding: utf-8
require "securerandom"
require "logstash/filters/base"
require "logstash/namespace"

# The IntervalMetric filter is used to count the number of 
# messages that passed through logstash over an interval time
#
# NOTE IntervalMetric is essentially just a stripped down
# version of logstash's metric, with some modifications to allow it to 
# count interval times. 
# 
# CREDITS:
# metric (logstash plugin) - http://github.com/logstash-plugins/logstash-filter-metrics
# metriks (lib) - http://github.com/eric/metriks
# 
# I do not to take credit for the vast majority of the code. I just needed 
# to beable to get the count of an interval so I jury-rigged the metric
# code to support my use case. 

class LogStash::Filters::IntervalMetric < LogStash::Filters::Base

  config_name "intervalmetric"
  
  # syntax: `counter => [ "name of metric", "name of metric" ]`
  config: :counter, :validate => :array, :default => []

  # count_interval is the time interval that the counters count till 
  # It also determines the flush_interval, which is the same, but is
  # delayed by 5 seconds.
  config: :count_interval, :validate => :number, :default => 600


  public
  def register
    require "Metriks"
    require "socket"
    require "atomic"
    require "thread_safe"
    @last_flush = Atomic.new(0) # how many seconds ago the metrics were flushed
    @last_clear = Atomic.new(0) # how many seconds ago the metrics were cleared
    @random_key_preffix = SecureRandom.hex
    @metric_counter = ThreadSafe::Cache.new { |h,k| h[k] = Metriks.counter(metric_key(k)) }
    @start_time = Time.now
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @counter.each do |c|
      @metric_meters[event.sprintf(c)].increment() 
    end # @counter.each

  end # def filter
  
  public
  def flush(options = {})
    @last_flush.update { |v| v + 5 }
    @last_clear.update { |v| v + 5 }
    
    return unless should_flush?

    event = LogStash::Event.new
    event["message"] = Socket.gethostname
    
    @metric_counter.each_pair do |name, metric|
      flush_rates(event, name, metric)
    end # @metric_counter.each_pair

    #to compensate the offset
    @last_flush.value = 5
    @last_clear.value = 5
    filter_matched(event) # last line of our successful code
    return [event]
  end # def flush

  # periodic_flush should be enabled regardless, therefore we default it to true
  # temporary fix due to logstash's issue:
  # https://github.com/elasticsearch/logstash/issues/1839
  def periodic_flush
    true
  end # def periodic_flush

  def flush_rates(event, name, metric)
    event["#{name}.count"] = metric.count

  def metric_key(key)
    "#{@random_key_preffix}_#{key}"
  end # def metric_key

  def should_flush?
    @last_flush.value > @count_interval && !@metric_counter.empty?
  end # def should_flush

end # class LogStash::Filters::Example
