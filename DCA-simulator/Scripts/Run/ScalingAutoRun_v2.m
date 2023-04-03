% This script allows for automatic running of Simulink Models using 
% Volvo Architecture Component-Blocks 

% Clear Workspace
clear;
%--------------------- Simulation information ---------------------------%

% Model name to be simulated
topology_script = 'bb_kinlam_ver2.m';
% Data Source (Fleet)
source_block_name = "Constant Fleet";
sb_parameter_names = ["time","message_size","frequency","fleet_size"];
sb_parameter_values = [...
    [10, 0.008, 1, 1000];...
    [10,0.008, 1, 10000]...
    ];
% Limit number of simulations to run. (-1) = all simulations
simulation_limit = 15;
% Suppress warnings
%#ok<*NBRAK2> 
%#ok<*AGROW> 
%#ok<*SAGROW>
%------------------------ Model Initiation  -----------------------------%
run(topology_script);
load_system(model_file);
set_param(model_name,"FastRestart","on");
set_param(model_name,"SimulationMode", "normal");
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

    hws = get_param(model_name, 'modelworkspace');
    hws.DataSource = 'MAT-file';
    hws.FileName = 'params';

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
            
            hws.assignin(pname, value);
            parameter_value_row(length(parameter_value_row)+1) = value; 
    end

    hws.saveToSource;
    hws.reload;

    qm_row_temp = [0,0,0,0];
    delta_row = [0,0,0,0];
    qm_row = [];

    for subruns = 1:2
        hws = get_param(model_name, 'modelworkspace');
        hws.DataSource = 'MAT-file';
        hws.FileName = 'params';


        % Set fleet size
        for i = 1:length(sb_parameter_values)
            hws.assignin(sb_parameter_names(i), sb_parameter_values(subruns,i));
        end

        hws.saveToSource;
        hws.reload;
       
        % Run simulation
        simdata = sim(model_file);

        % Sum quality measures
        
        for qm = 1:length(sout_info)
            eval_string = "simdata." + sout_info(qm,1) + ".Data(:,:,end)";
            qm_temp = eval(eval_string);
            qm_row_temp = qm_row_temp + qm_temp;
        end
        qm_row = [qm_row; [qm_row_temp]];       
    end

    first = qm_row(1,1:3);
    second = qm_row(2,1:3);
    delta = (second - first)/(sb_parameter_values(2,4)-sb_parameter_values(1,4));

    qm_row = qm_row(1,:) + qm_row(2,:);
    qm_row(4) =  qm_row(4) + sum(delta,"all");

    parameter_values = [parameter_values;parameter_value_row];
    quality_metrics = [quality_metrics;qm_row];

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


