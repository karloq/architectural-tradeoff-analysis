block_name = "Kinesis Stream";

a = ["ondemand","bool", "0", "1", "1"];
b = ["peak_buffer","cont", "1", "1000", "1"];
c = ["efo_consumers","cont", "0", "1", "1"];
d = ["base_records","cont", "1", "1", "1"];
e = ["peak_records","cont", "1", "1", "1"];

parameter_name  =    [a(1),b(1),c(1),d(1),e(1)];
value_dist      =    [a(2),b(2),c(2),d(2),e(2)];
value_min       =    [a(3),b(3),c(3),d(3),e(3)];
value_max       =    [a(4),b(4),c(4),d(4),e(4)];
value_step      =    [a(5),b(5),c(5),d(5),e(5)];
sout_name       =    "kinesis_sout";