% This script allows for automatic running of Simulink Models using 
% Volvo Architecture Component-Blocks 

%--------------------- Simulation information ---------------------------%

% Model name to be simulated
model_file = 'DebuggingModel_1.slx';
model_name = 'DebuggingModel_1/';
% Blocks (that have parameters) in the model
blocks_with_parameter = ["Cache"]; 
% Suppress warnings
%#ok<*NBRAK2> 
%#ok<*AGROW> 
%#ok<*SAGROW>

%--------------------------- Initiation  --------------------------------%

% Vector to contain all parameter names
p_name = [];
% Matrix to contain all possible parameter values (per value) from each
% block. Will be overwritten for each iteration.
pva = {};
% Output frame to contain all simulation data 
master_simulation_data = [];
% master_pva will contatin all parameter values for each possible
% simulation

%-------------------- Simulation setup creation -------------------------%

% Read all "blockname.m" files and iteratively populate pva and p_name
for i = 1:length(blocks_with_parameter)
    script = blocks_with_parameter(i) + ".m";
    run(script);

    p_name = [p_name, parameter_names]; 

    for j = 1:length(parameter_values)
        index = j+i-1;
        pva{index} = parameter_values{j};  
    end
end

% Get all permutations of the vectors using the ndgrid function
[X{1:numel(pva)}] = ndgrid(pva{:});

% Reshape the permutations into a matrix
master_pva = cell2mat(cellfun(@(x) x(:), X, 'UniformOutput', false));

%--------------------------- Simulation ---------------------------------%

% Simulation loop
sz = size(master_pva);
for runs = 1:sz(1)
    for params = 1:sz(2)
    % Load parameters
    set_param(model_name + blocks_with_parameter, p_name(params),int2str(master_pva(runs,params)));
    end
    % Run simulation
    sim_data = sim(model_file);
    % Collect data
    % TODO
end








