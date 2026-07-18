function g_tip_num_dense = resample_g_tip_num_dense(Sf_ini, H_p_num_ini, g0_tip, thumb_sample_count, finger_sample_count)
%RESAMPLE_G_TIP_NUM_DENSE Generate dense fingertip poses for workspace plotting.
%   Defaults keep the original sampling density:
%   thumb: 20 x 20 samples; index/middle/ring/little: 400 samples each.

if nargin < 4
    thumb_sample_count = 20;
end
if nargin < 5
    finger_sample_count = 400;
end

theta_t1_base = linspace(-44.1*pi/180, -133.5*pi/180, thumb_sample_count);
theta_t2_base = linspace(9.44*pi/180, 82.27*pi/180, thumb_sample_count);
theta_i1_base = linspace(0, 84*pi/180, finger_sample_count);
theta_m1_base = linspace(0, 84*pi/180, finger_sample_count);
theta_r1_base = linspace(0, 84*pi/180, finger_sample_count);
theta_l1_base = linspace(0, 84*pi/180, finger_sample_count);

jvar_f_dense = cell(5, 1);
jvar_f_dense{1} = calculate_thumb_variables(theta_t1_base, theta_t2_base);
jvar_f_dense{2} = calculate_modularized_finger_variables(theta_i1_base);
jvar_f_dense{3} = calculate_modularized_finger_variables(theta_m1_base);
jvar_f_dense{4} = calculate_modularized_finger_variables(theta_r1_base);
jvar_f_dense{5} = calculate_modularized_finger_variables(theta_l1_base);

[H_t_num_dense, ~] = calculate_finger_tip_H(Sf_ini, H_p_num_ini, jvar_f_dense);
g_tip_num_dense = calculate_fingertip_poses(H_t_num_dense, g0_tip);
end