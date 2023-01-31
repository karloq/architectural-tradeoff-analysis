% This script allows for automatic running of Simulink Models using 
% Volvo Architecture Component-Blocks 

blocks_with_parameter = ["Cache"];
pva(1:20) = -1;
p_name = [];
pva_cell = {};

for i = 1:length(blocks_with_parameter)
    blockname = blocks_with_parameter(i);
    script = blockname + ".m";
    run(script);

    p_name = [p_name, parameter_names];

    for j = 1:length(parameter_values)
        index = j+i-1;
        pva_cell{index} = parameter_values{j};
    end
end

% Get all permutations of the vectors using the ndgrid function
[X{1:numel(pva_cell)}] = ndgrid(pva_cell{:});

% Reshape the permutations into a matrix
master_pva = cell2mat(cellfun(@(x) x(:), X, 'UniformOutput', false));
