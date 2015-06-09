# Logstash Plugin Filter - Interval Metric 

This is a simple metrics plugin for [LogStash](https://github.com/elasticsearch/logstash).

Its current and only real goal is to count the number of messages that logstash processes for given intervals of time by the message's timestamp. (ex. the number of messages that logstash processed from 10:00-10:10, 10:10-10:20, ..., etc)

Following the lead of LogStash, this plugin is completely free and fully open source. The license is Apache 2.0 (I think?). 



## Disclaimer

This plugin is essentially a stripped down and modified version of the LogStash plugin [Metric](https://github.com/logstash-plugins/logstash-filter-metrics). 

The plugin also replies heavily on the [Metriks library](https://github.com/eric/metriks).

If you read through the code, it copies large portions of code from the metric code; I do not claim to be the author of alot of the code. I simply jury-rigged the metrics plugin code to fit my usecase to run some tests. I do not believe I violate any of the licenses of the plugin/lib, but if either parties are upset, feel free to email [me](kelvinfann@outlook.com). I only put this up because I figured some other user might also need to have an interval counter

## Documentation

To be completed after the plugin is completed. 


