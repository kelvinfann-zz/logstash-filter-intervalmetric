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
  config :count_interval, :validate => :number, :default => 20

  # the default metrics you want to keep track of. They will 
  # always show in the meter with a minium count of 0
  # syntax: `persist_counters => [ "name of metric", "name of metric" ]`
  config :persist_counter, :validate => :array, :default => []

  # the time indicator of the message; event[time_indicator]
  # syntax: `counter => [ "name of metric", "name of metric" ]`
  config :time_indicator, :validate => :string, :default => '@timestamp'

  # Where intervalmetric saves its current counts. If left
  # as '' it does not save counts on a graceful shutdown
  # `save_path => `/path/to/save/file`
  config :save_path, :validate => :string, :default => ''

  public
  def register
    require "metriks"
    require "socket"
    require "atomic"
    require "thread_safe"
    if @count_interval <= 5
      @count_interval = 10 
    end
    @last_flush = Atomic.new(0) # how many seconds ago the metrics were flushed
    @random_key_prefix = SecureRandom.hex
    @metric_counter = ThreadSafe::Cache.new { |h,k| h[k] = Metriks.counter metric_key(k) } 
    read_save
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    interval = parse_time_interval(event[@time_indicator].time.utc)
    @counter.each do |c|
      @metric_counter["#{event.sprintf(c)}_#{interval.to_s}"].increment 
    end
  end # def filter
  
  public
  def flush(options = {})
    @last_flush.update { |v| v + 5 }

    return unless should_flush?

    curr_interval = get_curr_interval

    event = LogStash::Event.new
    event["message"] = Socket.gethostname
    event["curr_interval"] = curr_interval 

    has_values = false
    @persist_counter.each do |c|
      event["#{c}.count"] = { curr_interval => 0 }
    end
    @metric_counter.each_pair do |extended_name, metric|
      expanded_name = extended_name.reverse.split('_', 2).map(&:reverse)
      name = expanded_name[1].to_s
      interval_time = expanded_name[0].to_i
      if interval_time < curr_interval
        flush_count(event, name, interval_time, metric)
        @metric_counter.delete(extended_name)
        has_values = true
      end
    end
    event["has_values"] = has_values
    event["count_interval"] = @count_interval
    @last_flush.update { |v| v % @count_interval }

    filter_matched(event)
    return [event]
  end # def flush

  # periodic_flush should be enabled regardless, therefore we default it to true
  # temporary fix due to logstash's issue:
  # https://github.com/elasticsearch/logstash/issues/1839
  def periodic_flush
    true
  end # def periodic_flush

  def metric_key(key)
    "#{@random_key_prefix}_#{key}"
  end # def metric_key

  def should_flush?
    @last_flush.value > @count_interval
  end # def should_flush

  def flush_count(event, name, interval, metric)
    if event["#{name}.count"] == nil
      event["#{name}.count"] = {}
    end
    event["#{name}.count"][interval] = metric.count
  end # def flush_rates
   
  def convert_to_ms(time)
    return (time.to_f * 1000).to_i
  end # convert_to_ms

  def get_curr_interval
    now = Time.now.utc
    start_interval = Time.gm(now.year, now.month, now.day).utc
    while start_interval + @count_interval < now
      start_interval += @count_interval
    end 
    return convert_to_ms(start_interval.utc)/1000
  end # get_start_interval

  def parse_time_interval(time)
    seconds = (time.sec + (time.min*60) + (time.hour*60*60))
    interval = (seconds / @count_interval).to_i * @count_interval
    floored_time = (convert_to_ms(time) / 1000).to_i 
    return (floored_time - seconds + interval)
  end # parse_time_interval

  def write_save
    open(@save_path, 'a') do |f|
      @metric_counter.each_pair do |extended_name, metric|
        f.puts "#{extended_name}:#{metric.count}"
        @metric_counter.delete(extended_name)
      end
    end
  end # write_save

  def read_save
    if @save_path != '' && File.exist?(@save_path)
      open(@save_path, 'r') do |f|
        f.each_line do |line|
          expanded_name = line.reverse.split(':', 2).map(&:reverse) # spliting by the last '_'
          name = expanded_name[1]
          count = expanded_name[0].to_i
          count.downto(1) { |_| @metric_counter[name].increment }
        end
      end
      File.delete(@save_path)
    end
  end # read_save

  def teardown
    if @save_path != ''
      write_save
    end
  end # teardown
  
end # class LogStash::Filters::Example

