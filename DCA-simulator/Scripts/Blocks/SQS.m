block_name = "SQS";

a = ["sqs_queue_size","log", 8, 1000, 1];
b = ["sqs_timeout","cont", 1, 10, 1];

parameter_name =    [a(1),b(1)];
value_dist =        [a(2),b(2)];
value_min =         [a(3),b(3)];
value_max =         [a(4),b(4)];
value_step =        [a(5),b(5)];
sout_name =         "sqs_sout";