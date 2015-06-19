import sys

def generatefile(filename, pattern, rep):
    f = open(filename, 'w')
    try:
        for _ in xrange(rep):
            f.write(pattern + '\n')
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

def compare_logfiles(interval_file, metric_file):
    interval_metric = parse_intervalmetric_file(interval_file)
    metric = parse_metric_file(metric_file)
    is_same = True
    for key in interval_metric:
        if key not in metric:
            is_same = False
        if interval_metric[key] != metric[key]:
            is_same = False
    for key in metric:
        if key not in interval_metric:
            is_same = False
    return interval_metric, metric, is_same

def main():
    command = ""
    if len(sys.argv) >= 2:
        command = sys.argv[1]
    if command == "generatefile" and len(sys.argv) == 5:
        filename = str(sys.argv[2])
        pattern = str(sys.argv[3])
        rep = int(sys.argv[4])
        generatefile(filename, pattern, rep)
    elif command == "compare" and len(sys.argv) == 4:
        intervalmetric_filename = str(sys.argv[2])
        metric_filename = str(sys.argv[3])
        print compare_logfiles(intervalmetric_filename, metric_filename)
    else:
        raise ValueError("bad params")

if __name__ == "__main__":
    main()
