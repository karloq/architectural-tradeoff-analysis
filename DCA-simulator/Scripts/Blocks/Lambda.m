block_name = "Lambda";

a = ["lambda_parallel_instances","cont", 1, 100, 1];
b = ["lambda_allocated_memory","cont", 128, 10000, 64];

parameter_name =    [a(1),b(1)];
value_dist =        [a(2),b(2)];
value_min =         [a(3),b(3)];
value_max =         [a(4),b(4)];
value_step =        [a(5),b(5)];
sout_name =         "lambda_sout";