parameter_names = ["no_cores", "no_instances","ram"];
parameter_values{1} = 1:32;
parameter_values{2} = [1/1000,1/100,1/10,1];
parameter_values{3} = 2:2:64;