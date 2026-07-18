function j_var = calculate_modularized_finger_variables(theta1_num)
%THREE_JOINT_FINGER_JVAR
% 由输入 MCP 关节角序列 theta1，计算电缸行程 s 以及三关节角度，
% 输出 j_var = [s; theta1; theta2; theta3]
%
% 输入：
%   theta1 : 1×N 或 N×1（单位：rad）
% 输出：
%   j_var  : 4×N，其中
%            第1行 s，第2行 theta1，第3行 theta2，第4行 theta3

    % ------- 固定参数-------
    l     = [45,43,6,6,38,37,6,7,27.29,7,6.5];
    h     = 12.5;
    d     = 2.7;
    alpha = pi/6;
    beta  = pi/3;
    gamma = 3*pi/4;
    phi9  = 64.19/180*pi;
    zeta  = 150/180*pi;

    % 统一成行向量，方便后面拼接成 4×N
    theta1_num = double(theta1_num(:).');

    % ------- 运动学求解 -------
    [phi_I_num,  ~] = PIP_kinematics(l, alpha, theta1_num);
    [phi_II_num, ~] = DIP_kinematics(l, alpha, beta, gamma, phi_I_num);
    phi_num = [phi_I_num; phi_II_num];

    theta2_num = pi - phi_num(3,:) - beta;
    theta3_num = pi - phi_num(7,:) - phi9;

    s_num = actuator_kinematics(l(10), l(11), h, d, alpha, zeta, phi_num(1,:));

    % 统一 s 为行向量（避免 actuator_kinematics 返回列向量导致维度不一致）
    s_num = double(s_num(:).');

    % ------- 输出 -------
    j_var = [s_num; theta1_num; theta2_num; theta3_num];
end