% This script allows for automatic running of Simulink Models using
% Volvo Architecture Component-Blocks

% Clear Workspace
clear;

% Prompt user for storage of output
[baseFileName, outputFolder] = uiputfile("placeholder.csv");

%--------------------- Simulation information ---------------------------%

% Model name to be simulated
topology_script = ["beachball_topo.m",...
    "blackbanana_iotcon_topo.m", ...
    "blackbanana_iotlam_topo.m", ...
    "blackbanana_kincon_topo.m", ...
    "blackbanana_kinlam_topo.m", ...
    "bamboo_con_topo.m", ...
    "bamboo_lam_topo.m"];...
topology_name = ["3.0", ...
"1.1", ...
"1.2", ...
"1.3", ...
"1.4", ...
"2.1", ...
"2.2", ...
];
% Data Source (Fleet)
sb_parameter_names = ["message_size","fleet_size", "simulation_time"];
sb_parameter_values = [...
    [0.008,1000,900];...
    [0.008,10000,900]...
    ];

simulation_limit = 2000;
% Suppress warnings
%#ok<*NBRAK2>
%#ok<*AGROW>
%#ok<*SAGROW>

for topo = 5:5%length(topology_script)
    %------------------------ Model Initiation  -----------------------------%
    run(topology_script(topo));
    load_system(model_file);
    %set_param(model_name,"FastRestart","on");
    %set_param(model_name,"SimulationMode", "normal");
    %-------------------- Simulation setup creation -------------------------%
    % Read all "blockname.m" files
    out_index = 1;
    sout_out_index = 1;
    parameter_info = [];
    sout_info = [];
    clear('parameter_names');
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
    set_param(model_name, 'StopTime', int2str(sb_parameter_values(1,3)*2))
    save_system(model_name);

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
    qm_debug = ["sout", "latency","cost","complexity", "scalability"];
    clear('qm_row');
    clear('out_frame');

    for i = 1:2:length(out)
        for j = 1:length(sout_info)
            eval_string1 = "out(" + i + ")." + sout_info(j,1) + ".Data(:,:,end)";
            eval_string2 = "out(" + (i+1) + ")." + sout_info(j,1) + ".Data(:,:,end)";
            q1 = eval(eval_string1);
            q2 = eval(eval_string2);
            %q1(isnan(q1))=0;
            %q2(isnan(q2))=0;
            qm_debug_row1 = [sout_info(j,1),q1];
            qm_debug_row2 = [sout_info(j,1),q2];
            qm_debug = [qm_debug;qm_debug_row1;qm_debug_row2];
            qm_temp1 = qm_temp1 + q1;
            qm_temp2 = qm_temp2 + q2;
        end
        load1 = sb_parameter_values(1,2);
        load2 = sb_parameter_values(2,2);
        rload = sb_parameter_values(2,2)/sb_parameter_values(1,2);
        first = qm_temp1(1:2);
        second = qm_temp2(1:2);
        l1 = first(1)/load1;
        l2 = second(1)/load2;
        c1 = first(2)/load1;
        c2 = second(2)/load2;
        eps = 1e-6;

        scalability = (second - first)/first;

        t1 = l1 + c1;
        t2 = l2 + c2;

        %scalability = (t2-t1)/t1;

        %qm_row = qm_temp1 + qm_temp2;
        % Save only low load
        qm_row = qm_temp1;
        qm_row(4) =  scalability;
        quality_metrics = [quality_metrics;qm_row];
        qm_row = [0,0,0,0];
        qm_temp1 = [0,0,0,0];
        qm_temp2 = [0,0,0,0];
    end

    out_frame = ["Topology", parameter_names, ...
        "latency", "cost", "complexity", "scalability"];
    for i = 1:height(parameter_values)
        out_frame_row = [topology_name(topo), parameter_values(i,:), quality_metrics(i,:)];
        out_frame = [out_frame;out_frame_row];
    end

    % Create filename
    model_string = string(model_name(1:end));
    out_filename =  model_string + '.csv';

    out_filename = fullfile(outputFolder, out_filename);

    % Write output to file
    writematrix(out_frame, out_filename);
end

