block_name = "Fargate";

a = ["fargate_vcpus","cont", 1, 16, 2];
b = ["fargate_memorylevel","cont", 1, 3, 1];

parameter_name  =    [a(1),b(1)];
value_dist      =    [a(2),b(2)];
value_min       =    [a(3),b(3)];
value_max       =    [a(4),b(4)];
value_step      =    [a(5),b(5)];
sout_name       =    "fargate_sout";