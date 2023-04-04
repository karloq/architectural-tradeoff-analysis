block_name = "DynamoDB";
a = ["dynamo_stream","bool", 0, 1, 1];
b = ["dynamo_ondemand","cont", 0, 1, 1];
c = ["dynamo_writerate","cont", 500, 10000, 50];
d = ["dynamo_peakcapacity","cont", 1, 10, 1];
e = ["dynamo_peaktime","cont", 0, 1, 0.1];
f = ["dynamo_readrate","cont", 500, 10000, 50];

parameter_name  =    [a(1),b(1),c(1),d(1),e(1),f(1)];
value_dist      =    [a(2),b(2),c(2),d(2),e(2),f(2)];
value_min       =    [a(3),b(3),c(3),d(3),e(3),f(3)];
value_max       =    [a(4),b(4),c(4),d(4),e(4),f(4)];
value_step      =    [a(5),b(5),c(5),d(5),e(5),f(5)];
sout_name       =    "dynamo_sout";