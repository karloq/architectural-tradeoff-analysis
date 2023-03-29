% This script allows for automatic running of Simulink Models using 
% Volvo Architecture Component-Blocks 

% Clear Workspace
clear;
%--------------------- Simulation information ---------------------------%

% Model name to be simulated
topology_script = 'bb_iotlam.m';
% Data Source (Fleet)
source_block_name = "Constant Fleet";
sb_parameter_names = ["time","message_size","frequency","fleet_size"];
subruns_limit = 2;
sb_parameter_values = [...
    ["10", "0.008", "1", "1000"];...
    ["10","0.008", "1", "10000"]...
    ];
% Limit number of simulations to run. (-1) = all simulations
simulation_limit = 15000;

% Suppress warnings
%#ok<*NBRAK2> 
%#ok<*AGROW> 
%#ok<*SAGROW>
%------------------------ Model Initiation  -----------------------------%
run(topology_script);
load_system(model_file);
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

    if ~isempty(parameter_name)
        for p = 1:length(parameter_name)
            parameter_info_row = [block_name,parameter_name(p), ...
                value_dist(p), value_min(p), value_max(p), value_step(p), ...
                out_index];
        
            out_index = out_index + 1;
        
            parameter_info = [parameter_info; parameter_info_row];
        end   
    end
    
end
%--------------------------- Simulation ---------------------------------%


for i = 1:height(parameter_info)
    parameter_names(i) = parameter_info(i,2);
end

parameter_values = [];
quality_metrics = [];
 
sec = 0;
minut = 0;
hour = 0;
comp_time = 0;
remaining_time_str = "";

for runs = 1:simulation_limit
    parameter_value_row = [];

    for i = 1:height(parameter_info)
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

    cost = 0;
    latency = 0;
    scalability = 0;
    reliability = 0;
    delta_cost = 0;
    delta_time = 0;
    delta_reliability = 0;
    delta_fleet = 0;
    quality_metrics_row = [];

    for subruns = 1:subruns_limit
        % Set scenario parameters
        for i = 1:length(sb_parameter_names)
            set_param(model_name + source_block_name, sb_parameter_names(i), ...
                sb_parameter_values(subruns,i))
        end
        % Run simulation
        sim(model_file);

        % Sum quality measures
        for qm = 1:length(sout_info)
            qm_temp = eval(sout_info(qm,1));
            latency = latency + qm_temp(1);
            cost = cost + qm_temp(2);
            reliability = reliability + qm_temp(3);
            scalability = scalability + qm_temp(4);
        end
        quality_metrics_row = [quality_metrics_row; [latency, cost, reliability, scalability]];       
    end

    first = quality_metrics_row(1,1:3);
    second = quality_metrics_row(2,1:3);
    delta = (second - first)/(str2double(sb_parameter_values(2,4))-str2double(sb_parameter_values(1,4)));

    quality_metrics_row = quality_metrics_row(1,:) + quality_metrics_row(2,:);
    quality_metrics_row(4) =  quality_metrics_row(4) + sum(delta,"all");

    parameter_values = [parameter_values;parameter_value_row];
    quality_metrics= [quality_metrics;quality_metrics_row];

    % Progress print
    if (mod(runs,2) == 0)
        comp_time = comp_time + toc;
    
        remaining_runs = simulation_limit-runs;
        remaining_time = remaining_runs * (comp_time/runs);
    
        if remaining_time >= 3600
            seconds_left = mod(remaining_time,3600);
            hour = (remaining_time - seconds_left)/3600;
            remaining_time = seconds_left;
        end
        if remaining_time >= 60
            seconds_left = mod(remaining_time,60);
            minut = (remaining_time - seconds_left)/60;
            remaining_time = seconds_left;
        end
        sec = round(remaining_time);
    
        remaining_time_str = "Remaining Time: " + hour + "h" + minut + "m" + sec + "sec";
    end

    disp("Running " + runs + " of " + ...
            simulation_limit + "( " ...
            + round((runs/(simulation_limit)) * 100) + "% )" ...
            + remaining_time_str); 
    remaining_time_str = "";
    tic;
end

out_frame = [blocks, parameter_names, ...
    "latency", "cost", "reliability", "scalability"];
for i = 1:height(parameter_values)
    out_frame_row = [ones(1,length(blocks)), parameter_values(i,:), quality_metrics(i,:)];
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


