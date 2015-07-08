# Logstash Plugin Filter - Interval Metric 

This is a simple metrics plugin for [LogStash](https://github.com/elasticsearch/logstash).

Its current and only real goal is to count the number of messages that logstash processes for given intervals of time by the message's timestamp. (ex. the number of messages that logstash processed from 10:00-10:10, 10:10-10:20, ..., etc)

Following the lead of LogStash, this plugin is completely free and fully open source. The license is Apache 2.0 (I think?). 



## Disclaimer

This plugin is essentially a stripped down and modified version of the LogStash plugin [Metric](https://github.com/logstash-plugins/logstash-filter-metrics). 

The plugin also relies heavily on the [Metriks library](https://github.com/eric/metriks).

If you read through the code, it copies large portions of code from the metric code; I do not claim to be the author of alot of the code. I simply jury-rigged the metrics plugin code to fit my usecase to run some tests. I do not believe I violate any of the licenses of the plugin/lib, but if either parties are upset, feel free to email [me](kelvinfann@outlook.com). I only put this up because I figured some other user might also need to have an interval counter

## Documentation

Interval Metric is, in many ways, a simplified version of the metrics plugin. The configs that should concern you are:
  1. `counter` - like the `meter` config from metrics, it is just the name of the counter of the message. It also supports the event parsing markup that the `meter` supports.
  2. `count_interval` - the time interval buckets in which the interval metric will sort the counts. The count_interval should be evenly divisible in a day (24hrs). The counts will be flushed at each interval with a 5 second delay.  
  3. `persist_counter` - by default the counters for the meters you specify will not output anything on each flush if the count is 0. Counters indicated in persist_counter will always show up in the flush. 
  4. `time_indicator` - the time indicator of the events that will be used to put the messages into the correct time bucket.
  5. `seralize_path` - the *absolute* path to a *file* in which the intervalmetric will save the counts that have not been flushed out in the case of a graceful shutdown. This is also the path the filter will read from when it starts initially. 

