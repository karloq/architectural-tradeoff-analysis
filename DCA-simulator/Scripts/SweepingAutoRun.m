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
blocks_zeroes = [2];
% Must follow the order of blocks and the parameter order inside
out_frame = ["e_SQS","queue_size", "timeout" ... #1,2,3
             "e_S3", ... #4
             "e_lambda","parallel_instances","lambda_chunk_size"... #5,6,7
             "time", "cost" ... #8,9
             ]; 
% These must be set correct for output validity
% With "Index" it is implied index in out_frame above
%   out_frame_parameters    : Index for parameters that are used in model
%   out_frame_existence     : Index for existence columns (named "e_xxx")
%   out_frame_cost_index    : Index for cost quality measure
%   out_frame_time_index    : Index for time quality measure

out_frame_parameters = [2,3,6,7];
out_frame_existence = [1,4,5];
out_frame_time_index = 8;
out_frame_cost_index = 9;

% Limit number of simulations to run. (-1) = all simulations
simulation_limit = 10000;

% Suppress warnings
%#ok<*NBRAK2> 
%#ok<*AGROW> 
%#ok<*SAGROW>
%------------------------ Model Initiation  -----------------------------%

cacheSize = 8;
dataSize = 5000;
spurtsCount = 10;
load_system(model_file);

 set_param(model_name + "Diagnostic Data", "cache_size", int2str(cacheSize), ...
                        "total_data_size", int2str(dataSize), ... 
                        "spurts", int2str(spurtsCount));

%--------------------------- Initiation  --------------------------------%

% Vector to contain all parameter names
p_name = [];
% Vector to contain all block names
b_name = [];
% Matrix to contain all possible parameter values (per value) from each
% block. Will be overwritten for each iteration.
pva = {};
% Output frame to contain all simulation data 
master_simulation_data = [];

%-------------------- Simulation setup creation -------------------------%

% Read all "blockname.m" files and iteratively populate pva and p_name
empty = 0;
column = 0;
for i = 1:length(blocks)
    % If block is not in current model, skip it
    if ismember(i,blocks_zeroes)
        empty = empty + 1;
        continue
    end

    script = blocks(i) + ".m";

    % Run script and fill workspace with variables
    run(script);

    p_name = [p_name, parameter_names];

    for j = 1:length(parameter_values)
        index = j+(i-empty-1) + column;
        pva{index} = parameter_values{j};  
        b_name = [b_name, blocks(i)];
    end
    column = column + 1;
end

% Get all permutations of the vectors using the ndgrid function
[X{1:numel(pva)}] = ndgrid(pva{:});

% Reshape the permutations into a matrix
master_pva = cell2mat(cellfun(@(x) x(:), X, 'UniformOutput', false));

%--------------------------- Simulation ---------------------------------%

% Simulation loop
% Get size of all runs before filtering
sz = size(master_pva);

illegal_runs_index = [];
for i = 1:sz(1)
    run = master_pva(i,1:4);
    if (run(1) < cacheSize)
        illegal_runs_index = [illegal_runs_index,i];
    elseif (run(4) < cacheSize)
        illegal_runs_index = [illegal_runs_index,i];
    end
end

master_pva(illegal_runs_index,:) = [];

% Get size of the parameters to use
sz = size(master_pva);
% Get size for all parameters there is in the output frame
out_frame_sz = size(out_frame);

for runs = 1:sz(1)
    if simulation_limit > -1 
        run_index = randi(sz(1));
    else
        run_index = runs;
    end
    % Debug limit of simulations
    if simulation_limit >= 0 && runs >= simulation_limit
        break;
    end

    % Create empty output row for simulation
    out_frame_row = zeros(1,out_frame_sz(2));

    % Fill in existence columns
    for component_index = out_frame_existence
        out_frame_row(component_index) = 1;
    end
    
    % Load parameters in model and record to out frame
    pva_index = 0;
    for out_params = out_frame_parameters
        pva_index = pva_index+1;
        % Get parameter value
        parameter_value = master_pva(run_index,pva_index);
        % Save Parameter value to output frame
        out_frame_row(out_params) = parameter_value;
        % Load parameter value to model
        set_param(model_name + b_name(pva_index), p_name(pva_index), ...
            int2str(parameter_value));
    end
    
    % Reset cost and times
    sqs_sout = [0,0];
    s3_sout = [0,0];
    lambda_sout = [0,0];

    % Run simulation
    sim_data = sim(model_file);

    % Sum quality measures
    out_frame_row(out_frame_time_index) = sqs_sout(1,1) + ...
                                          s3_sout(1,1) + ...
                                          lambda_sout(1,1);
    out_frame_row(out_frame_cost_index) = sqs_sout(1,2) + ...
                                          s3_sout(1,2) + ...
                                          lambda_sout(1,2);
    
    % Add collected row to output frame
    out_frame = [out_frame; out_frame_row];
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


