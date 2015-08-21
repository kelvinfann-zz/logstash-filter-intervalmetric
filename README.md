#Logstash Plugin Filter - Interval Metric 

This is a simple metrics plugin for [LogStash](https://github.com/elasticsearch/logstash).

Its current and only real goal is to count the number of messages that logstash processes for given intervals of time by the message's timestamp. (ex. the number of messages that logstash processed from 10:00-10:10, 10:10-10:20, ..., etc)

Following the lead of LogStash, this plugin is completely free and fully open source. The license is Apache 2.0 (I think?). 

##Disclaimer

This plugin is essentially a stripped down and modified version of the LogStash plugin [Metric](https://github.com/logstash-plugins/logstash-filter-metrics). 

If you read through the code, it copies large portions of code from the metric code; I do not claim to be the author of alot of the code. I simply jury-rigged the metrics plugin code to fit my usecase to run some tests. I do not believe I violate any of the licenses of the plugin/lib, but if either parties are upset, feel free to email [me](kelvinfann@outlook.com). I only put this up because I figured some other user might also need to have an interval counter

##Credit
This plugin utilizes the following libraries:
  - [Metriks library](https://github.com/eric/metriks)
  - [Atomic library](https://github.com/ruby-concurrency/atomic)
  - [Thread-Safe library](https://github.com/ruby-concurrency/thread_safe)

##Install
You install this plugin as you would install all logstash plugins. Here is a [guide](https://www.elastic.co/guide/en/logstash/current/_how_to_write_a_logstash_filter_plugin.html#_test_installation_3) Use the test installation 

##Config

Interval Metric is, in many ways, a simplified version of the metrics plugin. The configs that should concern you are:
  - `counter`: like the `meter` config from metrics, it is just the name of the counter of the message. It also supports the event parsing markup that the `meter` supports. Defaults to '[]'
  - `count_interval`: the time interval buckets in which the interval metric will sort the counts. The count_interval should be evenly divisible in a day (24hrs). The counts will be flushed at each interval with a 5 second delay. Defaults to 20
  - `persist_counter`: by default the counters for the meters you specify will not output anything on each flush if the count is 0. Counters indicated in persist_counter will always show up in the flush. Defaults to '[]'
  - `time_indicator`: the time indicator of the events that will be used to put the messages into the correct time bucket. Defaults to '@timestamp'
  - `save_path`: the *absolute* path to a *file* in which the intervalmetric will save the counts that have not been flushed out in the case of a graceful shutdown. This is also the path the filter will read from when it starts initially to check for any saved counts. Defaults to '' which means it does not actually save

##Example

Simple stdin/out example

logstash config:

```
input{
	stdin{}
}
filter{
	intervalmetric {
		counter => ["%{message}", 'collective_count']
		persist_counter => ['persist_collective_counter']
		add_tag => "im"
	}
}
output{
	if "im" in [tags]{
		stdout{
			codec => json
		}
	}
}
```

input:

```
$ counter1
$ counter2
$ counter2
$ counter3
$ counter3
$ counter3
```

output:
```
{
	"message": "localhost",
	"@timestamp": "2015-08-21T19:27:05.723Z"
	"@version": "1"
	"curr_interval": 1440185220,
	"has_values": true,
	"count_interval": "20",
	"counter1.count": {
		1440185200: 1
	},
	"counter2.count": {
		1440185200: 2
	},
	"counter3.count": {
		1440185200: 3
	},
	"persist_collective_counter.count" {
		1440185200: 6
	},
	"collective_count.count" {
		1440185200: 6
	}
}
```

input:

```
$
```

output:
```
{
	"message": "localhost",
	"@timestamp": "2015-08-21T19:47:05.723Z"
	"@version": "1"
	"curr_interval": 1440185240,
	"has_values": false,
	"count_interval": "20",
	"persist_collective_counter.count" {
		1440185220: 0
	},
}
```



