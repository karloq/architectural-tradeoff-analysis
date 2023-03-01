% This script allows for automatic running of Simulink Models using 
% Volvo Architecture Component-Blocks 

% Clear Workspace
clear;
%--------------------- Simulation information ---------------------------%

% Model name to be simulated
model_file = 'DebuggingModel_1.slx';
model_name = 'DebuggingModel_1/';
% Blocks (that have parameters) in the model
blocks = ["Cache", "S3","Container","MessageQueue","Lambda"]; 
blocks_zeroes = [3];
% Must follow the order of blocks and the parameter order inside
out_frame = ["e_cache","cache_size", ... #1,2
             "e_S3","consistency", ... #3,4
             "e_container","no_cores","container_no_instances","ram",... #5,6,7,8
             "e_messageQueue","queue_size",... #9,10
             "e_lambda","lambda_no_instances",... #11,12
             "cost", "time" ... #13,14
             ]; 
% These must be set correct for output validity
% With "Index" it is implied index in out_frame above
%   out_frame_parameters    : Index for parameters that are used in model
%   out_frame_existence     : Index for existence columns (named "e_xxx")
%   out_frame_cost_index    : Index for cost quality measure
%   out_frame_time_index    : Index for time quality measure

out_frame_parameters = [2,4,10,12];
out_frame_existence = [1,3,9,11];
out_frame_cost_index = 13;
out_frame_time_index = 14;

% Limit number of simulations to run. (-1) = all simulations
simulation_limit = 10;

% Suppress warnings
%#ok<*NBRAK2> 
%#ok<*AGROW> 
%#ok<*SAGROW>

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
column = 0;
for i = 1:length(blocks)
    % If block is not in current model, skip it
    if ismember(i,blocks_zeroes)
        continue
    end

    column = column + 1;
    script = blocks(i) + ".m";

    % Run script and fill workspace with variables
    run(script);

    p_name = [p_name, parameter_names];

    for j = 1:length(parameter_values)
        index = j+column-1;
        pva{index} = parameter_values{j};  
        b_name = [b_name, blocks(i)];
    end
end

% Get all permutations of the vectors using the ndgrid function
[X{1:numel(pva)}] = ndgrid(pva{:});

% Reshape the permutations into a matrix
master_pva = cell2mat(cellfun(@(x) x(:), X, 'UniformOutput', false));

%--------------------------- Simulation ---------------------------------%

% Simulation loop
% Get size of the parameters to use
sz = size(master_pva);
% Get size for all parameters there is in the output frame
out_frame_sz = size(out_frame);

for runs = 1:sz(1)
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
        parameter_value = master_pva(runs,pva_index);
        % Save Parameter value to output frame
        out_frame_row(out_params) = parameter_value;
        % Load parameter value to model
        set_param(model_name + b_name(pva_index), p_name(pva_index), ...
            int2str(parameter_value));
    end
    
    % Reset cost and times
    s3_sout = [0,0];
    lambda_sout = [0,0];
    container_sout = [0,0];

    % Run simulation
    sim_data = sim(model_file);

    % Sum quality measures
    out_frame_row(out_frame_time_index) = s3_sout(1,1) + lambda_sout(1,1) ...
        + container_sout(1,1);
    out_frame_row(out_frame_cost_index) = s3_sout(1,2) + lambda_sout(1,2) ...
        + container_sout(1,2);
    
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


