% This script allows for automatic running of Simulink Models using 
% Volvo Architecture Component-Blocks 

% Clear Workspace
clear;
%--------------------- Simulation information ---------------------------%

% Model name to be simulated
topology_script = 'bboo_con.m';
topology_name = "bboo_con_test";
% Data Source (Fleet)
sb_parameter_names = ["message_size","fleet_size", "simulation_time"];
sb_parameter_values = [...
    [0.008,1000,10];...
    [0.008,10000,10]...
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
%set_param(model_name,"FastRestart","on");
%set_param(model_name,"SimulationMode", "normal");
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

parameter_values = [zeros(simulation_limit,height(parameter_info))];

% Define the model name and configuration set
cs = getActiveConfigSet(model_name);

% Set the simulation mode to 'rapid-accelerator'
set_param(model_name,'SimulationMode','normal');

% Create an array of Simulink.SimulationInput objects
simIn = arrayfun(@(x) Simulink.SimulationInput(model_name), ones(1,simulation_limit*2));

% Specify the variable to change and its new value for each object in the array
idx = 1;
for i = 1:simulation_limit
   for j = 1:height(parameter_info)
        pinfo_row = parameter_info(j,:);
        
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
    
        simIn(idx) = simIn(idx).setVariable(pname, value);
        simIn(idx+1) = simIn(idx+1).setVariable(pname, value);
   
       parameter_values(i,j) = value;
   end

   for k = 1:length(sb_parameter_values)
        simIn(idx) = simIn(idx).setVariable(sb_parameter_names(k), sb_parameter_values(1,k));
        simIn(idx+1) = simIn(idx+1).setVariable(sb_parameter_names(k), sb_parameter_values(2,k));
   end

   idx = idx + 2;

   simIn(i) = simIn(i).setModelParameter('SimulationMode', 'normal');
end

out = parsim(simIn, 'ShowProgress', 'on');

% Sum quality measures
quality_metrics = [];
qm_temp1 = [0,0,0,0];
qm_temp2 = [0,0,0,0];

for i = 1:2:length(out)
    for j = 1:length(sout_info)
        eval_string1 = "out(" + i + ")." + sout_info(j,1) + ".Data(:,:,end)";
        eval_string2 = "out(" + (i+1) + ")." + sout_info(j,1) + ".Data(:,:,end)";
        qm_temp1 = qm_temp1 + eval(eval_string1);
        qm_temp2 = qm_temp2 + eval(eval_string2);
    end
    first = qm_temp1(1:3);
    second = qm_temp2(1:3);
    delta = (second - first)/(sb_parameter_values(2,2)-sb_parameter_values(1,2));
    
    qm_row = qm_temp1 + qm_temp2;
    qm_row(4) =  qm_row(4) + sum(delta,"all");
    quality_metrics = [quality_metrics;qm_row];
    qm_temp = [];
end
        
out_frame = ["Topology", parameter_names, ...
    "latency", "cost", "reliability", "scalability"];
for i = 1:height(parameter_values)
    out_frame_row = [topology_name, parameter_values(i,:), quality_metrics(i,:)];
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


