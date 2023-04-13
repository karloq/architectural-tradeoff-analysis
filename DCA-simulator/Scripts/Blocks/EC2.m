block_name = "EC2";

a = ["ec2_vcpus","cont", 1, 16, 2];
b = ["ec2_memorylevel","cont", 1, 3, 1];
c = ["ec2_instances","cont", 1, 100, 1];

parameter_name  =    [a(1),b(1),c(1)];
value_dist      =    [a(2),b(2),c(2)];
value_min       =    [a(3),b(3),c(3)];
value_max       =    [a(4),b(4),c(4)];
value_step      =    [a(5),b(5),c(5)];
sout_name       =    "ec2_sout";