# encoding: utf-8
require "securerandom"
require "logstash/filters/base"
require "logstash/namespace"

# The IntervalMetric filter is used to count the number of 
# messages that passed through logstash over an interval time
#
# Note: IntervalMetric is essentially just a stripped down
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
  config :counter, :validate => :array, :default => []

  # count_interval is the time interval that the counters count till 
  # It also determines the flush_interval, which is the same, but is
  # delayed by 5 seconds.
  # syntax: `count_interval => `\int`
  config :count_interval, :validate => :number, :default => 600
 
  # The starting time of the interval
  config :interval_start, :validate => :number, :default => 0

  # the default metrics you want to keep track of
  config :persist_counters, :validate => :array, :default => []

  config :time_indicator, :validate => :string, :default => '@timestamp'

  public
  def register
    require "metriks"
    require "socket"
    require "atomic"
    require "thread_safe"
    require "time"
    if @count_interval <= 5
      @count_interval = 10 
    end # @counter_interval <= 0
    @last_flush = Atomic.new(0) # how many seconds ago the metrics were flushed
    @curr_interval_time = Atomic.new(get_start_interval())
    @random_key_prefix = SecureRandom.hex
    @metric_counter = ThreadSafe::Cache.new { |h,k| h[k] = Metriks.counter metric_key(k) } 
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    interval = get_time_interval(event['@timestamp'].time.utc)
    @counter.each do |c|
      @metric_counter["#{event.sprintf(c)}_#{interval.to_s}"].increment 
    end # @counter.each
  end # def filter
  
  public
  def flush(options = {})
    @last_flush.update { |v| v + 5 }

    return unless should_flush?

    event = LogStash::Event.new
    event["message"] = Socket.gethostname
    event["curr_interval"] = @curr_interval_time.value 

    has_values = false
    @persist_counters.each do |c|
      event["#{c}.count"] = { @curr_interval_time.value => 0 }
    end # @counter.each
    @metric_counter.each_pair do |extended_name, metric|
      expanded_name = extended_name.reverse.split('_', 2).map(&:reverse) # spliting by the last '_'
      name = expanded_name[1]
      interval_time = expanded_name[0].to_i
      if interval_time < @curr_interval_time.value
        flush_count(event, name, interval_time, metric)
        @metric_counter.delete(extended_name)
        has_values = true
      end # interval == @curr_interval_time
    end # @metric_counter.each_pair

    event["has_values"] = has_values
    # to compensate the offset rather 
    @last_flush.update { |v| v % @count_interval }
    @curr_interval_time.update { |v| v + (@count_interval*1000) }

    filter_matched(event) # last line of our successful code
    return [event]
  end # def flush

  # periodic_flush should be enabled regardless, therefore we default it to true
  # temporary fix due to logstash's issue:
  # https://github.com/elasticsearch/logstash/issues/1839
  def periodic_flush
    true
  end # def periodic_flush

  def flush_count(event, name, interval, metric)
    if event["#{name}.count"] == nil
      event["#{name}.count"] = {}
    end # if event[
    event["#{name}.count"][interval] = metric.count
  end # def flush_rates

  def metric_key(key)
    "#{@random_key_prefix}_#{key}"
  end # def metric_key

  def should_flush?
    @last_flush.value > @count_interval
  end # def should_flush
  
  # NOTICE: We cannot simply use get_time_interval since the start cannot carry
  # usecs. 
  def get_start_interval()
    now = Time.now.utc
    start_interval = Time.local(now.year, now.month, now.day).utc
    while start_interval + @count_interval < now
      start_interval += @count_interval
    end #while
    return convert_to_ms(start_interval.utc)
  end # get_start_interval

  # NOTICE: The time that is returned is not exactly correct since it still carries
  # the usec, however, since we parse this value into a string in the name of the 
  # metric and then reparse it back into a time, it effectively truncates the usecs  
  def get_time_interval(time)
    seconds = (time.sec + (time.min*60) + (time.hour*60*60))
    interval = (seconds / @count_interval).to_i * @count_interval
    floored_time = (convert_to_ms(time) / 1000).to_i 
    return (floored_time - seconds + interval) * 1000
  end # get_time_interval
  def convert_to_ms(time)
    return (time.to_f * 1000).to_i
  end # convert_to_ms
end # class LogStash::Filters::Example

