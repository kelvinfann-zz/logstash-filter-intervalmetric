import sys
import random as r

def generate_file(filename, pattern, rep):
    f = open(filename, 'a')
    try:
        for _ in xrange(rep):
            f.write(pattern + '\n')
    finally:
        f.close()

def generate_random_file(filename, rep):
    f = open(filename, 'a')
    try:
        for _ in xrange(rep):
            f.write(str(int(r.random()*10000)) + '\n')
    finally:
        f.close()

def parse_metric(log):
    split_log = log.split('.count":')
    name = [item[item.rindex('"')+1:] for item in split_log[:-1]]
    value = [int(item[:item.index(',')]) for item in split_log[1:]]
    metrics = {}
    for i in xrange(len(name)):
        metrics[name[i]] = value[i]
    return metrics

def parse_metric_file(filename):
    metric = {}
    f = open(filename, 'r')
    for log in f:
        metric = parse_metric(log)
    f.close()
    return metric

def parse_intervalmetric(log):
    split_log = log.split('.count":')
    name = [item[item.rindex('"')+1:] for item in split_log[:-1]]
    unparsed_values = (item[item.index('{')+1:item.index("}")] for item in split_log[1:])
    value = []
    for up_value in unparsed_values:
        value += [sum(int(key_value[key_value.index(':')+1:]) for key_value in up_value.split(','))]
    interval_metric = {}
    for i in xrange(len(name)):
        interval_metric[name[i]] = value[i]
    return interval_metric

def parse_intervalmetric_file(filename):
    interval_metric = {}
    f = open(filename, 'r')
    for log in f:
        curr_interval_metric = parse_intervalmetric(log)
        for key in curr_interval_metric:
            if key not in interval_metric:
                interval_metric[key] = 0
            interval_metric[key] += curr_interval_metric[key]
    f.close()
    return interval_metric

def parse_intervalmetric_has_values(log):
    if '"has_values":true' in log:
        return True
    return False

def parse_intervalmetric_file_has_values(filename):
    has_values = False
    f = open(filename, 'r')
    for log in f:
        has_values = parse_intervalmetric_has_values(log)
    f.close()
    return has_values

def compare_logfiles(interval_file, metric_file):
    interval_metric = parse_intervalmetric_file(interval_file)
    metric = parse_metric_file(metric_file)
    not_matched = set()
    is_same = True
    for key in interval_metric:
        if key not in metric:
            is_same = False
            not_matched.add(key)
        elif interval_metric[key] != metric[key]:
            is_same = False
    for key in metric:
        if key not in interval_metric:
            is_same = False
            not_matched.add(key)
    return interval_metric, metric, not_matched, is_same

def main():
    command = ""
    if len(sys.argv) >= 2:
        command = sys.argv[1]
    if command == "generatefile" and len(sys.argv) == 5:
        filename = str(sys.argv[2])
        pattern = str(sys.argv[3])
        rep = int(sys.argv[4])
        generate_file(filename, pattern, rep)
    elif command == "generate_random_file" and len(sys.argv) == 4:
        filename = str(sys.argv[2])
        rep = int(sys.argv[3])
        generate_random_file(filename, rep)
    elif command == "compare" and len(sys.argv) == 4:
        intervalmetric_filename = str(sys.argv[2])
        metric_filename = str(sys.argv[3])
        print compare_logfiles(intervalmetric_filename, metric_filename)
    elif command == "track" and len(sys.argv) == 3:
        filename = str(sys.argv[2])
        print parse_intervalmetric_file_has_values(filename)
    elif command == "intervalmetric" and len(sys.argv) == 3:
        intervalmetric_filename = str(sys.argv[2])
        print parse_intervalmetric_file(intervalmetric_filename)
    elif command == "metric" and len(sys.argv) == 3:
        metric_filename = str(sys.argv[2])
        print parse_metric_file(metric_filename) 
    else:
        raise ValueError("bad params")

if __name__ == "__main__":
    main()
