block_name = "Kinesis Stream";

a = ["kinesis_ondemand","bool", 0, 1, 1];
b = ["kinesis_efos","cont", 0, 1, 1];
c = ["kinesis_records","log", 500, 10000, 50];
d = ["kinesis_peak","cont", 0, 1, 0.1];

parameter_name  =    [a(1),b(1),c(1),d(1)];
value_dist      =    [a(2),b(2),c(2),d(2)];
value_min       =    [a(3),b(3),c(3),d(3)];
value_max       =    [a(4),b(4),c(4),d(4)];
value_step      =    [a(5),b(5),c(5),d(5)];
sout_name       =    "kinesis_sout";