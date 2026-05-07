% =========================================================================
% MASTER BOOTSTRAPPER: MBD Environment Generator
% Description: Automatically generates folders, writes pipeline scripts, 
% and configures the MATLAB Project for the SCR Thermal Control system.
% All generated code contains English comments for industry compliance.
% =========================================================================
clear; clc;

disp('Starting Master MBD Environment Generator...');

%% 1. CREATE DIRECTORY STRUCTURE
projectName = 'SCR_Thermal_Control';
projectFolder = fullfile(pwd, projectName);

if ~exist(projectFolder, 'dir')
    mkdir(projectFolder);
end
cd(projectFolder);

% Standardized folder names
folders = {'scripts', 'models', 'local_libraries', 'local_tests', 'work'};
for i = 1:length(folders)
    if ~exist(folders{i}, 'dir'), mkdir(folders{i}); end
end
disp('Directory structure created.');

%% 2. GENERATE SCRIPT 1: Parameters (Phase 2.1)
disp('Generating p01_parameters.m...');
fid = fopen(fullfile('scripts', 'p01_parameters.m'), 'w');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% PHASE 2.1: Physical Parameters of the SCR System\n');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, 'disp(''Loading SCR Physical Parameters...'');\n\n');
fprintf(fid, 'T_amb = 298.15;       %% [K] Ambient temperature\n');
fprintf(fid, 'T_op  = 473.15;       %% [K] Target operating temperature\n\n');
fprintf(fid, 'm1_c1 = 1600;         %% [J/K] Thermal capacity of the ceramic brick\n');
fprintf(fid, 'h1A   = 40;           %% [W/K] Convective heat transfer coeff\n\n');
fprintf(fid, 'm2_c2 = 500;          %% [J/K] Thermal capacity of the washcoat layer\n');
fprintf(fid, 'h12A  = 100;          %% [W/K] Conductive heat transfer\n\n');
fprintf(fid, 'rad_term = 2e-8;      %% [W/K^4] Stefan-Boltzmann radiation constant\n\n');
fprintf(fid, 'disp(''Parameters loaded into base workspace.'');\n');
fclose(fid);

%% 3. GENERATE SCRIPT 2: State-Space Model (Phase 2.2)
disp('Generating p02_state_space_model.m...');
fid = fopen(fullfile('scripts', 'p02_state_space_model.m'), 'w');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% PHASE 2.2: State-Space Model Generation\n');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, 'disp(''Generating State-Space Matrices...'');\n\n');
fprintf(fid, 'if ~exist(''m1_c1'', ''var''), run(''p01_parameters.m''); end\n\n');
fprintf(fid, 'A_11 = -(h1A + h12A) / m1_c1;\n');
fprintf(fid, 'A_12 = h12A / m1_c1;\n');
fprintf(fid, 'A_21 = h12A / m2_c2;\n');
fprintf(fid, 'A_22 = (-h12A - 4 * rad_term * (T_op^3)) / m2_c2;\n\n');
fprintf(fid, 'A_scr = [A_11, A_12; A_21, A_22];\n');
fprintf(fid, 'B_scr = [1/m1_c1; 0];\n');
fprintf(fid, 'C_scr = [0, 1];\n');
fprintf(fid, 'D_scr = 0;\n\n');
fprintf(fid, 'sys_scr = ss(A_scr, B_scr, C_scr, D_scr);\n');
fprintf(fid, 'sys_scr.StateName = {''T_Substrate'', ''T_Washcoat''};\n');
fprintf(fid, 'sys_scr.InputName = {''Thermal_Power_In''};\n');
fprintf(fid, 'sys_scr.OutputName = {''T_Sensor_Out''};\n\n');
fprintf(fid, 'disp(''Matrices A_scr, B_scr, C_scr, D_scr successfully generated.'');\n\n');
fprintf(fid, '%% --- AUTOMATED PIPELINE EXECUTION ---\n');
fprintf(fid, 'if ~exist(fullfile(''local_libraries'', ''SCR_Plant_Library.slx''), ''file''), run(''p03_generate_library.m''); end\n');
fprintf(fid, 'if ~exist(fullfile(''local_tests'', ''Harness_SCR_OpenLoop.slx''), ''file''), run(''p04_open_loop_test.m''); end\n');
fprintf(fid, 'if ~exist(''K_integral'', ''var''), run(''p05_design_controllers.m''); end\n');
fprintf(fid, 'if ~exist(fullfile(''local_tests'', ''Harness_SCR_Observer_Kalman.slx''), ''file''), run(''p06_kalman_only_test.m''); end\n');
fprintf(fid, 'if ~exist(fullfile(''local_tests'', ''Harness_SCR_ClosedLoop_LQI.slx''), ''file''), run(''p07_closed_loop_lqi_kf.m''); end\n');
fprintf(fid, 'if ~exist(fullfile(''local_tests'', ''Harness_SCR_ClosedLoop_PID.slx''), ''file''), run(''p08_closed_loop_pid.m''); end\n');
fprintf(fid, 'run(''p09_configure_solvers.m'');\n');
fclose(fid);

%% 4. GENERATE SCRIPT 3: Simulink Library (Phase 2.3)
disp('Generating p03_generate_library.m...');
fid = fopen(fullfile('scripts', 'p03_generate_library.m'), 'w');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% PHASE 2.3: Generate Simulink Subsystem Library (LTI Plant)\n');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, 'disp(''Building Simulink Library Component...'');\n\n');
fprintf(fid, 'libName = ''SCR_Plant_Library'';\n');
fprintf(fid, 'libFile = fullfile(''local_libraries'', [libName ''.slx'']);\n\n');
fprintf(fid, 'if bdIsLoaded(libName), close_system(libName, 0); end\n');
fprintf(fid, 'if exist(libFile, ''file''), delete(libFile); end\n\n');
fprintf(fid, 'new_system(libName, ''Library'');\n');
fprintf(fid, 'open_system(libName);\n\n');
fprintf(fid, 'subSysPath = [libName ''/SCR_Thermal_Plant_LTI''];\n');
fprintf(fid, 'add_block(''simulink/Ports & Subsystems/Subsystem'', subSysPath);\n\n');

fprintf(fid, 'set_param([subSysPath ''/In1''], ''Name'', ''Heat_Input'');\n');
fprintf(fid, 'set_param([subSysPath ''/Out1''], ''Name'', ''Temp_Output'');\n');
fprintf(fid, 'add_block(''simulink/Ports & Subsystems/Out1'', [subSysPath ''/State_Output'']);\n');
fprintf(fid, 'delete_line(subSysPath, ''Heat_Input/1'', ''Temp_Output/1'');\n\n');

fprintf(fid, 'add_block(''simulink/Continuous/State-Space'', [subSysPath ''/LTI_State_Space'']);\n');
fprintf(fid, 'set_param([subSysPath ''/LTI_State_Space''], ''A'', ''A_scr'', ''B'', ''B_scr'', ''C'', ''eye(2)'', ''D'', ''[0;0]'', ''X0'', ''[T_amb; T_amb]'');\n\n');

fprintf(fid, 'add_block(''simulink/Math Operations/Gain'', [subSysPath ''/Sensor_C_Matrix'']);\n');
fprintf(fid, 'set_param([subSysPath ''/Sensor_C_Matrix''], ''Gain'', ''C_scr'', ''Multiplication'', ''Matrix(K*u)'');\n\n');

fprintf(fid, 'add_line(subSysPath, ''Heat_Input/1'', ''LTI_State_Space/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(subSysPath, ''LTI_State_Space/1'', ''State_Output/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(subSysPath, ''LTI_State_Space/1'', ''Sensor_C_Matrix/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(subSysPath, ''Sensor_C_Matrix/1'', ''Temp_Output/1'', ''autorouting'', ''on'');\n\n');

fprintf(fid, 'Simulink.BlockDiagram.arrangeSystem(subSysPath);\n');
fprintf(fid, 'save_system(libName, libFile);\n');
fprintf(fid, 'close_system(libName);\n');
fclose(fid);

%% 5. GENERATE SCRIPT 4: Open Loop Test (Phase 2.4)
disp('Generating p04_open_loop_test.m...');
fid = fopen(fullfile('scripts', 'p04_open_loop_test.m'), 'w');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% PHASE 2.4: Open-Loop Simulation Harness\n');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, 'disp(''Configuring Open-Loop Simulink harness...'');\n\n');
fprintf(fid, 'testModel = ''Harness_SCR_OpenLoop'';\n');
fprintf(fid, 'if bdIsLoaded(testModel), close_system(testModel, 0); end\n');
fprintf(fid, 'new_system(testModel);\n\n');
fprintf(fid, 'add_block(''simulink/Sources/Step'', [testModel ''/Step_Heat'']);\n');
fprintf(fid, 'set_param([testModel ''/Step_Heat''], ''Time'', ''150'', ''Before'', ''0'', ''After'', ''1500'');\n\n');
fprintf(fid, 'load_system(''SCR_Plant_Library'');\n');
fprintf(fid, 'add_block(''SCR_Plant_Library/SCR_Thermal_Plant_LTI'', [testModel ''/Plant_LTI'']);\n');
fprintf(fid, 'add_block(''simulink/Sinks/Out1'', [testModel ''/Test_Out'']);\n');
fprintf(fid, 'add_block(''simulink/Sinks/Terminator'', [testModel ''/Terminator'']);\n\n');

fprintf(fid, 'lh1 = add_line(testModel, ''Step_Heat/1'', ''Plant_LTI/1'');\n');
fprintf(fid, 'set_param(lh1, ''Name'', ''Heat_Command_W'');\n');
fprintf(fid, 'lh2 = add_line(testModel, ''Plant_LTI/1'', ''Test_Out/1'');\n');
fprintf(fid, 'set_param(lh2, ''Name'', ''Actual_Temperature_OL_K'');\n');
fprintf(fid, 'lh3 = add_line(testModel, ''Plant_LTI/2'', ''Terminator/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh3, ''Name'', ''Actual_States_x_OL'');\n\n');

fprintf(fid, 'ph_in = get_param([testModel ''/Step_Heat''], ''PortHandles'');\n');
fprintf(fid, 'set_param(ph_in.Outport(1), ''DataLogging'', ''on'');\n');
fprintf(fid, 'ph_out = get_param([testModel ''/Plant_LTI''], ''PortHandles'');\n');
fprintf(fid, 'set_param(ph_out.Outport(1), ''DataLogging'', ''on'');\n');
fprintf(fid, 'set_param(ph_out.Outport(2), ''DataLogging'', ''on'');\n\n');

fprintf(fid, 'set_param(testModel, ''StopTime'', ''300'', ''SignalLogging'', ''on'', ''SaveFormat'', ''Dataset'');\n');
fprintf(fid, 'Simulink.BlockDiagram.arrangeSystem(testModel);\n');
fprintf(fid, 'save_system(testModel, fullfile(''local_tests'', [testModel ''.slx'']));\n');
fprintf(fid, 'close_system(testModel, 0);\n');
fclose(fid);

%% 6. GENERATE SCRIPT 5: Controllers (Phase 3)
disp('Generating p05_design_controllers.m...');
fid = fopen(fullfile('scripts', 'p05_design_controllers.m'), 'w');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% PHASE 3: Controller Designs (LQI, Kalman Filter & PID)\n');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, 'disp(''Designing Controllers (LQI, KF, PID)...'');\n\n');
fprintf(fid, 'if ~exist(''sys_scr'', ''var''), run(''p02_state_space_model.m''); end\n\n');

fprintf(fid, '%% --- 1. LQI Control Design ---\n');
fprintf(fid, 'Co = ctrb(sys_scr);\n');
fprintf(fid, 'if (length(A_scr) - rank(Co)) > 0, error(''System is not fully controllable.''); end\n');
fprintf(fid, 'Q_lqi = diag([1, 10, 500]);\n');
fprintf(fid, 'R_lqi = 0.05;\n');
fprintf(fid, '[K_opt, ~, ~] = lqi(sys_scr, Q_lqi, R_lqi);\n');
fprintf(fid, 'K_states = K_opt(1:2);\n');
fprintf(fid, 'K_integral = K_opt(3);\n\n');

fprintf(fid, '%% --- 2. Kalman Filter (Observer) Design ---\n');
fprintf(fid, 'G_kf = eye(2);\n');
fprintf(fid, 'Q_kf = diag([0.1, 0.1]);\n');
fprintf(fid, 'R_kf = 0.5;\n');
fprintf(fid, '[L_kf, ~, ~] = lqe(A_scr, G_kf, C_scr, Q_kf, R_kf);\n');
fprintf(fid, 'A_obs = A_scr - L_kf * C_scr;\n');
fprintf(fid, 'B_obs = [B_scr, L_kf];\n');
fprintf(fid, 'C_obs = eye(2);\n');
fprintf(fid, 'D_obs = zeros(2, 2);\n\n');

fprintf(fid, '%% --- 3. Auto-Tuned PID Control Design ---\n');
fprintf(fid, 'disp(''Tuning baseline PID controller for the SISO plant...'');\n');
fprintf(fid, 'sys_siso = sys_scr(1,1); %% Heat_in to T_Washcoat relationship\n');
fprintf(fid, 'opts = pidtuneOptions(''DesignFocus'', ''reference-tracking'');\n');
fprintf(fid, 'C_pid = pidtune(sys_siso, ''PID'', opts);\n');
fprintf(fid, 'Kp_pid = C_pid.Kp;\n');
fprintf(fid, 'Ki_pid = C_pid.Ki;\n');
fprintf(fid, 'Kd_pid = C_pid.Kd;\n\n');

fprintf(fid, 'fprintf(''--- Control & Estimation Designed ---\\n'');\n');
fprintf(fid, 'fprintf(''LQI State Gains (Ks): [%%.4f, %%.4f]\\n'', K_states(1), K_states(2));\n');
fprintf(fid, 'fprintf(''PID Baseline Gains: Kp=%%.4f, Ki=%%.4f, Kd=%%.4f\\n'', Kp_pid, Ki_pid, Kd_pid);\n');
fclose(fid);

%% 7. GENERATE SCRIPT 6: Kalman Filter Only Test (Phase 4.1)
disp('Generating p06_kalman_only_test.m...');
fid = fopen(fullfile('scripts', 'p06_kalman_only_test.m'), 'w');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% PHASE 4.1: Kalman Filter Estimation Test\n');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, 'modelName = ''Harness_SCR_Observer_Kalman'';\n');
fprintf(fid, 'if bdIsLoaded(modelName), close_system(modelName, 0); end\n');
fprintf(fid, 'new_system(modelName);\n');
fprintf(fid, 'load_system(''SCR_Plant_Library'');\n\n');
fprintf(fid, 'add_block(''simulink/Sources/Step'', [modelName ''/Step_Heat'']);\n');
fprintf(fid, 'set_param([modelName ''/Step_Heat''], ''Time'', ''150'', ''Before'', ''0'', ''After'', ''1500'');\n');
fprintf(fid, 'add_block(''SCR_Plant_Library/SCR_Thermal_Plant_LTI'', [modelName ''/Plant_LTI'']);\n');
fprintf(fid, 'add_block(''simulink/Signal Routing/Mux'', [modelName ''/Obs_Mux'']);\n');
fprintf(fid, 'set_param([modelName ''/Obs_Mux''], ''Inputs'', ''2'');\n');
fprintf(fid, 'add_block(''simulink/Continuous/State-Space'', [modelName ''/Kalman_Filter'']);\n');
fprintf(fid, 'set_param([modelName ''/Kalman_Filter''], ''A'', ''A_obs'', ''B'', ''B_obs'', ''C'', ''C_obs'', ''D'', ''D_obs'', ''X0'', ''T_amb + 20 * (2*rand(2,1) - 1)'');\n');
fprintf(fid, 'add_block(''simulink/Math Operations/Sum'', [modelName ''/State_Error'']);\n');
fprintf(fid, 'set_param([modelName ''/State_Error''], ''Inputs'', ''+-'', ''IconShape'', ''rectangular'');\n');
fprintf(fid, 'add_block(''simulink/Sinks/Out1'', [modelName ''/Output_Temp'']);\n');
fprintf(fid, 'add_block(''simulink/Sinks/Out1'', [modelName ''/Output_Est'']);\n');
fprintf(fid, 'add_block(''simulink/Sinks/Out1'', [modelName ''/Output_Err'']);\n\n');

fprintf(fid, 'lh1 = add_line(modelName, ''Step_Heat/1'', ''Plant_LTI/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh1, ''Name'', ''Heat_Command_W'');\n');
fprintf(fid, 'add_line(modelName, ''Step_Heat/1'', ''Obs_Mux/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'lh2 = add_line(modelName, ''Plant_LTI/1'', ''Obs_Mux/2'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh2, ''Name'', ''Actual_Temperature_K'');\n');
fprintf(fid, 'add_line(modelName, ''Obs_Mux/1'', ''Kalman_Filter/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(modelName, ''Plant_LTI/1'', ''Output_Temp/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'lh_state = add_line(modelName, ''Plant_LTI/2'', ''State_Error/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh_state, ''Name'', ''Actual_States_x'');\n');
fprintf(fid, 'add_line(modelName, ''Kalman_Filter/1'', ''State_Error/2'', ''autorouting'', ''on'');\n');
fprintf(fid, 'lh3 = add_line(modelName, ''Kalman_Filter/1'', ''Output_Est/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh3, ''Name'', ''Estimated_States_x_hat'');\n');
fprintf(fid, 'lh4 = add_line(modelName, ''State_Error/1'', ''Output_Err/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh4, ''Name'', ''State_Estimation_Error'');\n\n');

fprintf(fid, '%% Data Logging \n');
fprintf(fid, 'ph_in = get_param([modelName ''/Step_Heat''], ''PortHandles'');\n');
fprintf(fid, 'set_param(ph_in.Outport(1), ''DataLogging'', ''on'');\n');
fprintf(fid, 'ph_p = get_param([modelName ''/Plant_LTI''], ''PortHandles'');\n');
fprintf(fid, 'set_param(ph_p.Outport(1), ''DataLogging'', ''on'');\n');
fprintf(fid, 'set_param(ph_p.Outport(2), ''DataLogging'', ''on'');\n');
fprintf(fid, 'ph_k = get_param([modelName ''/Kalman_Filter''], ''PortHandles'');\n');
fprintf(fid, 'set_param(ph_k.Outport(1), ''DataLogging'', ''on'');\n');
fprintf(fid, 'set_param(modelName, ''StopTime'', ''300'', ''SignalLogging'', ''on'', ''SaveFormat'', ''Dataset'');\n');
fprintf(fid, 'Simulink.BlockDiagram.arrangeSystem(modelName);\n');
fprintf(fid, 'save_system(modelName, fullfile(''local_tests'', [modelName ''.slx'']));\n');
fprintf(fid, 'close_system(modelName, 0);\n');
fclose(fid);

%% 8. GENERATE SCRIPT 7: Closed-Loop Model LQI (Phase 4.2)
disp('Generating p07_closed_loop_lqi_kf.m...');
fid = fopen(fullfile('scripts', 'p07_closed_loop_lqi_kf.m'), 'w');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% PHASE 4.2: LQI + Kalman Filter Closed-Loop\n');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, 'modelName = ''Harness_SCR_ClosedLoop_LQI'';\n');
fprintf(fid, 'if bdIsLoaded(modelName), close_system(modelName, 0); end\n');
fprintf(fid, 'new_system(modelName);\n');
fprintf(fid, 'load_system(''SCR_Plant_Library'');\n\n');

fprintf(fid, 'add_block(''simulink/Sources/Step'', [modelName ''/Target_Temp'']);\n');
fprintf(fid, 'set_param([modelName ''/Target_Temp''], ''Time'', ''150'', ''Before'', ''298.15'', ''After'', ''473.15'');\n');
fprintf(fid, 'add_block(''simulink/Math Operations/Sum'', [modelName ''/Error_Sum'']);\n');
fprintf(fid, 'set_param([modelName ''/Error_Sum''], ''Inputs'', ''+-'', ''IconShape'', ''rectangular'');\n');
fprintf(fid, 'add_block(''simulink/Continuous/Integrator'', [modelName ''/Integrator'']);\n');
fprintf(fid, 'add_block(''simulink/Math Operations/Gain'', [modelName ''/Ki_Gain'']);\n');
fprintf(fid, 'set_param([modelName ''/Ki_Gain''], ''Gain'', ''K_integral'');\n');

fprintf(fid, '%% Goto/From Labels to avoid spaghetti routing\n');
fprintf(fid, 'add_block(''simulink/Signal Routing/Goto'', [modelName ''/Goto_Y'']);\n');
fprintf(fid, 'set_param([modelName ''/Goto_Y''], ''GotoTag'', ''Y_MEAS'', ''ShowName'', ''off'');\n');
fprintf(fid, 'add_block(''simulink/Signal Routing/From'', [modelName ''/From_Y_Err'']);\n');
fprintf(fid, 'set_param([modelName ''/From_Y_Err''], ''GotoTag'', ''Y_MEAS'', ''ShowName'', ''off'');\n');
fprintf(fid, 'add_block(''simulink/Signal Routing/From'', [modelName ''/From_Y_Obs'']);\n');
fprintf(fid, 'set_param([modelName ''/From_Y_Obs''], ''GotoTag'', ''Y_MEAS'', ''ShowName'', ''off'');\n');
fprintf(fid, 'add_block(''simulink/Signal Routing/Goto'', [modelName ''/Goto_U'']);\n');
fprintf(fid, 'set_param([modelName ''/Goto_U''], ''GotoTag'', ''U_CMD'', ''ShowName'', ''off'');\n');
fprintf(fid, 'add_block(''simulink/Signal Routing/From'', [modelName ''/From_U_Obs'']);\n');
fprintf(fid, 'set_param([modelName ''/From_U_Obs''], ''GotoTag'', ''U_CMD'', ''ShowName'', ''off'');\n');
fprintf(fid, 'add_block(''simulink/Signal Routing/Goto'', [modelName ''/Goto_Xhat'']);\n');
fprintf(fid, 'set_param([modelName ''/Goto_Xhat''], ''GotoTag'', ''X_HAT'', ''ShowName'', ''off'');\n');
fprintf(fid, 'add_block(''simulink/Signal Routing/From'', [modelName ''/From_Xhat_Ctrl'']);\n');
fprintf(fid, 'set_param([modelName ''/From_Xhat_Ctrl''], ''GotoTag'', ''X_HAT'', ''ShowName'', ''off'');\n\n');

fprintf(fid, 'add_block(''simulink/Signal Routing/Mux'', [modelName ''/Obs_Mux'']);\n');
fprintf(fid, 'set_param([modelName ''/Obs_Mux''], ''Inputs'', ''2'');\n');
fprintf(fid, 'add_block(''simulink/Continuous/State-Space'', [modelName ''/Kalman_Filter'']);\n');
fprintf(fid, 'set_param([modelName ''/Kalman_Filter''], ''A'', ''A_obs'', ''B'', ''B_obs'', ''C'', ''C_obs'', ''D'', ''D_obs'', ''X0'', ''T_amb + 20 * (2*rand(2,1) - 1)'');\n');
fprintf(fid, 'add_block(''simulink/Math Operations/Gain'', [modelName ''/Ks_Gain'']);\n');
fprintf(fid, 'set_param([modelName ''/Ks_Gain''], ''Gain'', ''K_states'', ''Multiplication'', ''Matrix(K*u)'');\n');
fprintf(fid, 'add_block(''simulink/Math Operations/Sum'', [modelName ''/Control_Sum'']);\n');
fprintf(fid, 'set_param([modelName ''/Control_Sum''], ''Inputs'', ''--'', ''IconShape'', ''rectangular'');\n');
fprintf(fid, 'add_block(''SCR_Plant_Library/SCR_Thermal_Plant_LTI'', [modelName ''/Plant_LTI'']);\n');
fprintf(fid, 'add_block(''simulink/Sinks/Out1'', [modelName ''/Output_Temp'']);\n');
fprintf(fid, 'add_block(''simulink/Sinks/Terminator'', [modelName ''/Terminator'']);\n\n');

fprintf(fid, '%% Connections\n');
fprintf(fid, 'add_line(modelName, ''Target_Temp/1'', ''Error_Sum/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(modelName, ''From_Y_Err/1'', ''Error_Sum/2'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(modelName, ''Error_Sum/1'', ''Integrator/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(modelName, ''Integrator/1'', ''Ki_Gain/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(modelName, ''Ki_Gain/1'', ''Control_Sum/2'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(modelName, ''From_Xhat_Ctrl/1'', ''Ks_Gain/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(modelName, ''Ks_Gain/1'', ''Control_Sum/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'lh_u = add_line(modelName, ''Control_Sum/1'', ''Plant_LTI/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh_u, ''Name'', ''Heat_Command_W'');\n');
fprintf(fid, 'add_line(modelName, ''Control_Sum/1'', ''Goto_U/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'lh_y = add_line(modelName, ''Plant_LTI/1'', ''Goto_Y/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh_y, ''Name'', ''Actual_Temperature_CL_K'');\n');
fprintf(fid, 'add_line(modelName, ''Plant_LTI/1'', ''Output_Temp/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(modelName, ''From_U_Obs/1'', ''Obs_Mux/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(modelName, ''From_Y_Obs/1'', ''Obs_Mux/2'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(modelName, ''Obs_Mux/1'', ''Kalman_Filter/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'lh_xhat = add_line(modelName, ''Kalman_Filter/1'', ''Goto_Xhat/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh_xhat, ''Name'', ''Estimated_State_x_hat'');\n');
fprintf(fid, 'lh_state = add_line(modelName, ''Plant_LTI/2'', ''Terminator/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh_state, ''Name'', ''Actual_States_x_CL'');\n\n');

fprintf(fid, '%% Data Logging\n');
fprintf(fid, 'ph_ref = get_param([modelName ''/Target_Temp''], ''PortHandles'');\n');
fprintf(fid, 'set_param(ph_ref.Outport(1), ''Name'', ''Target_Temperature_K'', ''DataLogging'', ''on'');\n');
fprintf(fid, 'ph_ctrl = get_param([modelName ''/Control_Sum''], ''PortHandles'');\n');
fprintf(fid, 'set_param(ph_ctrl.Outport(1), ''DataLogging'', ''on'');\n');
fprintf(fid, 'ph_y = get_param([modelName ''/Plant_LTI''], ''PortHandles'');\n');
fprintf(fid, 'set_param(ph_y.Outport(1), ''DataLogging'', ''on'');\n');
fprintf(fid, 'set_param(ph_y.Outport(2), ''DataLogging'', ''on'');\n');
fprintf(fid, 'ph_hat = get_param([modelName ''/Kalman_Filter''], ''PortHandles'');\n');
fprintf(fid, 'set_param(ph_hat.Outport(1), ''DataLogging'', ''on'');\n');
fprintf(fid, 'set_param(modelName, ''StopTime'', ''300'', ''SignalLogging'', ''on'', ''SaveFormat'', ''Dataset'');\n');
fprintf(fid, 'Simulink.BlockDiagram.arrangeSystem(modelName);\n');
fprintf(fid, 'save_system(modelName, fullfile(''local_tests'', [modelName ''.slx'']));\n');
fprintf(fid, 'close_system(modelName, 0);\n');
fclose(fid);

%% 9. GENERATE SCRIPT 8: Closed-Loop Model PID (Phase 4.3)
disp('Generating p08_closed_loop_pid.m...');
fid = fopen(fullfile('scripts', 'p08_closed_loop_pid.m'), 'w');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% PHASE 4.3: Baseline PID Controller Closed-Loop\n');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, 'modelName = ''Harness_SCR_ClosedLoop_PID'';\n');
fprintf(fid, 'if bdIsLoaded(modelName), close_system(modelName, 0); end\n');
fprintf(fid, 'new_system(modelName);\n');
fprintf(fid, 'load_system(''SCR_Plant_Library'');\n\n');

fprintf(fid, 'add_block(''simulink/Sources/Step'', [modelName ''/Target_Temp'']);\n');
fprintf(fid, 'set_param([modelName ''/Target_Temp''], ''Time'', ''150'', ''Before'', ''298.15'', ''After'', ''473.15'');\n');
fprintf(fid, 'add_block(''simulink/Math Operations/Sum'', [modelName ''/Error_Sum'']);\n');
fprintf(fid, 'set_param([modelName ''/Error_Sum''], ''Inputs'', ''+-'', ''IconShape'', ''rectangular'');\n');

fprintf(fid, '%% Goto/From Labels for clean PID routing\n');
fprintf(fid, 'add_block(''simulink/Signal Routing/Goto'', [modelName ''/Goto_Y'']);\n');
fprintf(fid, 'set_param([modelName ''/Goto_Y''], ''GotoTag'', ''Y_MEAS'', ''ShowName'', ''off'');\n');
fprintf(fid, 'add_block(''simulink/Signal Routing/From'', [modelName ''/From_Y_Err'']);\n');
fprintf(fid, 'set_param([modelName ''/From_Y_Err''], ''GotoTag'', ''Y_MEAS'', ''ShowName'', ''off'');\n');

fprintf(fid, 'add_block(''simulink/Continuous/PID Controller'', [modelName ''/PID_Controller'']);\n');
fprintf(fid, 'set_param([modelName ''/PID_Controller''], ''P'', ''Kp_pid'', ''I'', ''Ki_pid'', ''D'', ''Kd_pid'');\n');

fprintf(fid, 'add_block(''SCR_Plant_Library/SCR_Thermal_Plant_LTI'', [modelName ''/Plant_LTI'']);\n');
fprintf(fid, 'add_block(''simulink/Sinks/Out1'', [modelName ''/Output_Temp'']);\n');
fprintf(fid, 'add_block(''simulink/Sinks/Terminator'', [modelName ''/Terminator'']);\n\n');

fprintf(fid, '%% Connections\n');
fprintf(fid, 'add_line(modelName, ''Target_Temp/1'', ''Error_Sum/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(modelName, ''From_Y_Err/1'', ''Error_Sum/2'', ''autorouting'', ''on'');\n');
fprintf(fid, 'add_line(modelName, ''Error_Sum/1'', ''PID_Controller/1'', ''autorouting'', ''on'');\n');

fprintf(fid, 'lh_u = add_line(modelName, ''PID_Controller/1'', ''Plant_LTI/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh_u, ''Name'', ''Heat_Command_W'');\n');

fprintf(fid, 'lh_y = add_line(modelName, ''Plant_LTI/1'', ''Goto_Y/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh_y, ''Name'', ''Actual_Temperature_CL_K'');\n');
fprintf(fid, 'add_line(modelName, ''Plant_LTI/1'', ''Output_Temp/1'', ''autorouting'', ''on'');\n');

fprintf(fid, 'lh_state = add_line(modelName, ''Plant_LTI/2'', ''Terminator/1'', ''autorouting'', ''on'');\n');
fprintf(fid, 'set_param(lh_state, ''Name'', ''Actual_States_x_CL'');\n\n');

fprintf(fid, '%% Data Logging\n');
fprintf(fid, 'ph_ref = get_param([modelName ''/Target_Temp''], ''PortHandles'');\n');
fprintf(fid, 'set_param(ph_ref.Outport(1), ''Name'', ''Target_Temperature_K'', ''DataLogging'', ''on'');\n');
fprintf(fid, 'ph_ctrl = get_param([modelName ''/PID_Controller''], ''PortHandles'');\n');
fprintf(fid, 'set_param(ph_ctrl.Outport(1), ''DataLogging'', ''on''); %% LOG PID CONTROL EFFORT\n');
fprintf(fid, 'ph_y = get_param([modelName ''/Plant_LTI''], ''PortHandles'');\n');
fprintf(fid, 'set_param(ph_y.Outport(1), ''DataLogging'', ''on'');\n');
fprintf(fid, 'set_param(ph_y.Outport(2), ''DataLogging'', ''on'');\n');

fprintf(fid, 'set_param(modelName, ''StopTime'', ''300'', ''SignalLogging'', ''on'', ''SaveFormat'', ''Dataset'');\n');
fprintf(fid, 'Simulink.BlockDiagram.arrangeSystem(modelName);\n');
fprintf(fid, 'save_system(modelName, fullfile(''local_tests'', [modelName ''.slx'']));\n');
fprintf(fid, 'close_system(modelName, 0);\n');
fclose(fid);

%% 10. GENERATE SCRIPT 9: Solver Configuration (Phase 5)
disp('Generating p09_configure_solvers.m...');
fid = fopen(fullfile('scripts', 'p09_configure_solvers.m'), 'w');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% PHASE 5: Fixed-Step Solver Configuration (ODE8)\n');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, 'modelsToConfig = {''Harness_SCR_OpenLoop'', ''Harness_SCR_Observer_Kalman'', ''Harness_SCR_ClosedLoop_LQI'', ''Harness_SCR_ClosedLoop_PID''};\n');
fprintf(fid, 'for i = 1:length(modelsToConfig)\n');
fprintf(fid, '    mdl = modelsToConfig{i};\n');
fprintf(fid, '    mdlPath = fullfile(''local_tests'', [mdl ''.slx'']);\n');
fprintf(fid, '    if exist(mdlPath, ''file'')\n');
fprintf(fid, '        load_system(mdlPath);\n');
fprintf(fid, '        set_param(mdl, ''SolverType'', ''Fixed-step'', ''Solver'', ''ode8'', ''FixedStep'', ''0.01'');\n');
fprintf(fid, '        save_system(mdl);\n');
fprintf(fid, '        close_system(mdl);\n');
fprintf(fid, '    end\n');
fprintf(fid, 'end\n');
fclose(fid);

%% 11. GENERATE SCRIPT 10: Comparative Tests via Test Manager (Phase 9)
disp('Generating p10_run_comparative_tests.m...');
fid = fopen(fullfile('scripts', 'p10_run_comparative_tests.m'), 'w');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, '%% PHASE 9: Test Manager Execution and Report Generation\n');
fprintf(fid, '%% =========================================================================\n');
fprintf(fid, 'sltest.testmanager.clear();\n');
fprintf(fid, 'sltest.testmanager.clearResults();\n');
fprintf(fid, 'testFile = fullfile(''local_tests'', ''SCR_Comparative_Suite.mldatx'');\n');
fprintf(fid, 'if exist(testFile, ''file''), delete(testFile); end\n\n');
fprintf(fid, 'tf = sltest.testmanager.TestFile(testFile);\n');
fprintf(fid, 'ts = getTestSuites(tf);\n');
fprintf(fid, 'tcs = getTestCases(ts);\n\n');
fprintf(fid, 'tc_ol = tcs(1);\n');
fprintf(fid, 'tc_ol.Name = ''1_Open_Loop_Dynamics'';\n');
fprintf(fid, 'setProperty(tc_ol, ''Model'', ''Harness_SCR_OpenLoop'');\n\n');
fprintf(fid, 'tc_ko = createTestCase(ts, ''Simulation'', ''2_Kalman_Estimation_Only'');\n');
fprintf(fid, 'setProperty(tc_ko, ''Model'', ''Harness_SCR_Observer_Kalman'');\n\n');
fprintf(fid, 'tc_lqi = createTestCase(ts, ''Simulation'', ''3_Closed_Loop_LQI_Kalman'');\n');
fprintf(fid, 'setProperty(tc_lqi, ''Model'', ''Harness_SCR_ClosedLoop_LQI'');\n\n');
fprintf(fid, 'tc_pid = createTestCase(ts, ''Simulation'', ''4_Closed_Loop_PID_Baseline'');\n');
fprintf(fid, 'setProperty(tc_pid, ''Model'', ''Harness_SCR_ClosedLoop_PID'');\n\n');
fprintf(fid, 'tf.saveToFile();\n');
fprintf(fid, 'result = tf.run();\n');
fprintf(fid, 'reportPath = fullfile(pwd, ''SCR_Comparative_Report.pdf'');\n');
fprintf(fid, 'sltest.testmanager.report(result, reportPath, ''IncludeSimulationSignalPlots'', true, ''IncludeTestResults'', 0, ''LaunchReport'', true);\n');
fclose(fid);

%% 12. CREATE MATLAB PROJECT AND CONFIGURE STARTUP
disp('Configuring MATLAB Project and Startup routines...');

% Create Project
proj = matlab.project.createProject('Folder', pwd, 'Name', 'SCR Thermal MBD Pipeline');

% Set cache folders
Simulink.fileGenControl('set', 'CacheFolder', fullfile(pwd, 'work'), 'CodeGenFolder', fullfile(pwd, 'work'));

% Add paths
addPath(proj, fullfile(pwd, 'scripts'));
addPath(proj, fullfile(pwd, 'local_libraries'));
addPath(proj, fullfile(pwd, 'local_tests'));

% Startup scripts
addStartupFile(proj, fullfile('scripts', 'p01_parameters.m'));
addStartupFile(proj, fullfile('scripts', 'p02_state_space_model.m'));

close(proj);

%% 13. INITIALIZE GIT REPOSITORY (OPTIONAL & ROBUST)
disp('=========================================================================');
user_input = input('Do you want to initialize a local Git repository and make the first commit? (Y/N) [N]: ', 's');
if strcmpi(user_input, 'y') || strcmpi(user_input, 'yes')
    disp('Checking Git installation on the system...');
    
    % Check if 'git' command exists silently
    [status_check, ~] = system('git --version');
    
    if status_check == 0
        disp('Git detected. Initializing repository...');
        system('git init');
        system('git add .');
        system('git commit -m "Initial commit: Bootstrapped SCR Thermal MBD Pipeline (LTI, PID, LQI, KF)"');
        disp('Git repository successfully created and first commit made!');
    else
        fprintf(2, '\nERROR: Git is not installed or not found in the system PATH variable.\n');
        disp('-------------------------------------------------------------------------');
        disp('--- HOW TO FIX IT? ---');
        disp('1. Download and install Git from: https://git-scm.com/downloads');
        disp('2. During installation, make sure to check the option that says:');
        disp('   "Git from the command line and also from 3rd-party software"');
        disp('   (This is crucial for Windows/Mac to add it to the PATH).');
        disp('3. CLOSE and reopen MATLAB to read the new PATH.');
        disp('4. To initialize your project manually after restarting, run:');
        disp('   >> system(''git init''); system(''git add .''); system(''git commit -m "Init"'');');
        disp('-------------------------------------------------------------------------');
    end
else
    disp('Git initialization skipped.');
end

disp('=========================================================================');
disp('ENVIRONMENT FULLY GENERATED.');
disp('The project is now active. Startup files loaded cleanly.');
disp('=========================================================================');

% Re-open the project so the UI detects the .git folder (if successfully created)
openProject(proj);