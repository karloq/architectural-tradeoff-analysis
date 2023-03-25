% This script allows for automatic running of Simulink Models using 
% Volvo Architecture Component-Blocks 

% Clear Workspace
clear;
%--------------------- Simulation information ---------------------------%

% Model name to be simulated
model_file = 'TestModel.slx';
model_name = 'TestModel/';
% Blocks (that have parameters) in the model
blocks = ["SQS", "S3","Lambda"]; 
% Must follow the order of blocks and the parameter order inside
out_frame = [];
% Limit number of simulations to run. (-1) = all simulations
simulation_limit = 100;

% Suppress warnings
%#ok<*NBRAK2> 
%#ok<*AGROW> 
%#ok<*SAGROW>
%------------------------ Model Initiation  -----------------------------%
load_system(model_file);

%TODO% add scenario parameter loading
 set_param(model_name + "Diagnostic Data", "cache_size", int2str(cacheSize), ...
                        "total_data_size", int2str(dataSize), ... 
                        "spurts", int2str(spurtsCount));

%--------------------------- Initiation  --------------------------------%

% Vector to contain all parameter names
p_name = [];
% Vector to contain all block names
b_name = [];


%-------------------- Simulation setup creation -------------------------%

% Read all "blockname.m" files and iteratively populate pva and p_name
out_index = 1;
sout_out_index = 1;
for i = 1:length(blocks)
    % Run script and fill workspace with variables
    script = blocks(i) + ".m";
    run(script);

    sout_info = [sout_name, sout_out_index];
    sout_out_index = sout_out_index + 1;

    for p = 1:length(block_parameters)
        parameter_info_row = [blocks(i),parameter_name(p), ...
            value_dist(p), value_min(p), value_max(p), value_step(p),out_index];

        out_index = out_index + 1;

        parameter_info = [parameter_info; parameter_info_row];
    end   
end
%--------------------------- Simulation ---------------------------------%

% Simulation loop
out_frame_size = length(blocks) + length(sout_info) + length(parameter_info);

for i = 1:length(parameter_info)
    parameter_names(i) = parameter_info(2);
end

parameter_values = [parameter_names];

for runs = 1:simulation_limit
    parameter_value_row = [];
    for i = 1:length(parameter_info)
        pinfo_row = parameter_info(i);
        
        pname = pinfo_row(2);
        dist = pinfo_row(3);

        step = pinfo_row(6);
        min = pinfo_row(4);
        max = pinfo_row(5);

        switch dist
            case "uniform"
                lower = round(min/step);
                upper = round(max/step);
                value = randi([lower,upper])*step;
            case "log"
                lower = log10(min);
                upper = log10(max);
                v = logspace(lower, upper, 100);
                w = round(v / 8) * 8;
                value = w(randi(length(w)));
            otherwise
                error("Unknown distribution of parameter: " + pname)
        end

        set_param(model_name + '/' + pinfo_row(1), pname, ...
        int2str(value));
        parameter_value_row(length(parameter_value_row)+1) = value; 
    end
    parameter_values = [parameter_values;parameter_value_row];

    disp("Running " + runs + " / " + simulation_limit + ...
    "( " + (runs/simulation_limit) * 100 + "% )");

    % Run simulation
    sim_data = sim(model_file);

    % Sum quality measures
    quality_metrics = ['name',0,0,0,0];
    for qm = 1:length(sout_info)
        quality_metrics_row = [sout_info(1), eval(sout_info(1))];
        quality_metrics = [quality_metrics;quality_metrics_row];
    end
end

for i = 1:length(parameter_values)
    out_frame_row = [blocks, parameter_values(i), quality_metrics(i)];
    out_frame = [out_frame;out_frame_row];
end

% Create filename
model_string = string(model_name(1:end-1));
date_string = strrep(erase(string(datetime)," "), ':', '-');
out_filename =  model_string + '_' + date_string + '.csv';

% Prompt user for storage of output
[baseFileName, outputFolder] = uiputfile(out_filename);
out_filename = fullfile(outputFolder, baseFileName);

% Write output to file
writematrix(out_frame, out_filename);


