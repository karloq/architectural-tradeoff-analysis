% This script allows for automatic running of Simulink Models using 
% Volvo Architecture Component-Blocks 

% Clear Workspace
clear;
%--------------------- Simulation information ---------------------------%

% Model name to be simulated
model_file = 'blackbanana.slx';
model_name = 'blackbanana/';
% Data Source (Fleet)
source_block_name = "Constant Fleet";
sb_parameter_names = ["time","message_size","frequency","fleet_size"];
sb_parameter_values = [10, 1, 1, 1000];
% Blocks (that have parameters) in the model
blocks = ["Lambda","Kinesis_Stream","Constant_Fleet"];
% Limit number of simulations to run. (-1) = all simulations
simulation_limit = 5;

% Suppress warnings
%#ok<*NBRAK2> 
%#ok<*AGROW> 
%#ok<*SAGROW>
%------------------------ Model Initiation  -----------------------------%
load_system(model_file);

%TODO% add scenario parameter loading
for i = 1:length(sb_parameter_names)
    set_param(model_name + source_block_name, sb_parameter_names(i), ...
        int2str(sb_parameter_values(i)))
end
%-------------------- Simulation setup creation -------------------------%
% Read all "blockname.m" files
out_index = 1;
sout_out_index = 1;
parameter_info = [];
sout_info = [];
for i = 1:length(blocks)
    % Run script and fill workspace with variables
    script = blocks(i) + ".m";
    run(script);

    if (sout_name ~= "")
        sout_info = [sout_info;sout_name, sout_out_index];
        sout_out_index = sout_out_index + 1;
    end

    for p = 1:length(parameter_name)
        parameter_info_row = [block_name,parameter_name(p), ...
            value_dist(p), value_min(p), value_max(p), value_step(p), ...
            out_index];

        out_index = out_index + 1;

        parameter_info = [parameter_info; parameter_info_row];
    end   
end
%--------------------------- Simulation ---------------------------------%

% Simulation loop

for i = 1:length(parameter_info)
    parameter_names(i) = parameter_info(i,2);
end

parameter_values = [];

quality_metrics = [];

for runs = 1:simulation_limit
    parameter_value_row = [];
    for i = 1:length(parameter_info)
        pinfo_row = parameter_info(i,:);
        
        pname = pinfo_row(2);
        dist = pinfo_row(3);

        step = str2double(pinfo_row(6));
        min = str2double(pinfo_row(4));
        max = str2double(pinfo_row(5));

        switch dist
            case "cont"
                lower = round(min/step);
                upper = round(max/step);
                value = randi([lower,upper])*step;
            case "log"
                lower = log10(min);
                upper = log10(max);
                v = logspace(lower, upper, 100);
                w = round(v / step) * step;
                value = w(randi(length(w)));
            case "bool"
                value = randi([min,max]);
            otherwise
                error("Unknown distribution of parameter: " + pname)
        end

        set_param(model_name + pinfo_row(1), pname, ...
        int2str(value));
        parameter_value_row(length(parameter_value_row)+1) = value; 
    end
    parameter_values = [parameter_values;parameter_value_row];

    disp("Running " + runs + " / " + simulation_limit + ...
    "( " + (runs/simulation_limit) * 100 + "% )");

    % Run simulation
    sim_data = sim(model_file);

    % Sum quality measures
    cost = 0;
    time = 0;
    scalability = 0;
    reliability = 0;
    for qm = 1:length(sout_info)
        qm_temp = eval(sout_info(qm,1));
        cost = cost + qm_temp(1);
        time = time + qm_temp(2);
        scalability = scalability + qm_temp(3);
        reliability = reliability + qm_temp(4);
    end
    quality_metrics_row = [cost, time, scalability, reliability];
    quality_metrics= [quality_metrics;quality_metrics_row];
end

out_frame = [ones(1,length(blocks)), parameter_names, ...
    "time", "cost", "scalability", "reliability"];
for i = 1:height(parameter_values)
    out_frame_row = [blocks, parameter_values(i,:), quality_metrics(i,:)];
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


