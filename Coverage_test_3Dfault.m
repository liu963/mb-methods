%% Generate Coverage plots for simple finite-fault geometries using Bootstrap and COBE
clear

%% Method to use for the coverage test
%test_type =1;  % Bootstrapping (can be residual or data)
%test_type =2;  % COBE
test_type = 1; 

% if flag = 1, use the data bootstrap. Otherwise use the residual bootstrap
boot_type_flag = 0; 

%% Number of pdfs to make
numModels = 1;

%% Set fault geometry
% Use the following tests to replicate the paper figures: 
%
% Test 1 (strike-slip fault): 
% H = 20, fault_length = 100, coupling = .2, dip = 90, xlocmod = 7, N = 50,
% nve = 5,  max_ss_sliprate = 30 (mm/yr) and max_ds_sliprate = 0. 
% sd = 0.001, 0.01, and 0.1 
% 
% Test 2 (dip-slip fault):
% H = 50, fault_length = 100, coupling = .2, dip = 45, nve = 10, sd = 0.001,
% max_ss_sliprate = 0, max_ds_sliprate = 30, N = 100. 
% xlocmod = 5, 6, and 7
%
% setup_synthetic_problem.m generates numModels slip models with randomly 
% locked patches, all at constant moment equal to coupling*maxM. Data are 
% generated by computing the predicted data for each slip model and adding 
% Gaussian noise with standard deviation sd. 

fault.N = 50;
fault.nve = 5;
fault.H=20;  %km
fault.L = 100; %km
fault.coupling = .2;
fault.dip = 90; % positive degrees

% slip rate is defined so that positive is up, right-lateral
fault.max_ss = 30;
fault.max_ds = 0; 

% specify slip model to use: random locked patches for replicating figures
fault.slip_model  = 1; 

% other fault parameters
fault.mu = 30e9;    % shear modulus in Pa

% data parameters
data.xlocmod = 5;
data.sd = 0.1; 

[fault, data, sig, SIG] = setup_synthetic_problem(fault, data, numModels);

%% Other options
solver_opts = optimset('maxiter', 3000,'Algorithm','interior-point'); 
conf_levels = [10 20 30 40 50 60 70 80 90 95 99]; 

%% Run the Test
switch test_type
    case 1
        % number of bootstrap   samples in each distribution
        Nboot = 400;     
        
        % call bootstrap function
         [results] = bootstrap(Nboot, numModels,fault,data,solver_opts, boot_type_flag);
    case 2
        % number of Mtest on the interval [0, maxM]
        nPs = 200; 
        
        % Call COBE
        [results] = cobe(data, fault, nPs,numModels,solver_opts);
end

results.truM = fault.truM; 
[emp_perc] = coverage(results, conf_levels, numModels, test_type);

%% Plot Results

% Coverage Plot
figure; 
plot(conf_levels, conf_levels, '--k')
hold on
plot(conf_levels, emp_perc, '-*b', 'LineWidth', 2, 'MarkerSize', 10)
xlabel('Expected coverage ((1-\alpha)*100%)', 'FontSize', 12)
ylabel('Observed Coverage', 'FontSize', 12)
if test_type == 1
    legend('Ideal','Bootstrap', 'Location', 'SouthEast')
else
    legend('Ideal','COBE', 'Location', 'SouthEast')
end
xlim([0, 100])
ylim([0,100])
title('Coverage Plot', 'FontSize', 12)
set(gca, 'FontSize', 12)


% Fault model and stations

% index is the model to plot, can be in the range [1,numModels]
index = 1; 

% scale GPS vectors for visibility if necessary
scale = 1; 

figure; 
plotpatchslip3D(fault.pm, fault.slipTru(:,index)', fault.nve)
hold on
quiver(data.xysites(:,1), data.xysites(:,2), scale*data.data_obs(1:end/2,index), scale*data.data_obs(end/2 + 1:end,index), 0, 'b')
