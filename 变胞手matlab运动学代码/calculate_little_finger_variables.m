function j_var = calculate_little_finger_variables(theta1_num)
%LITTLE_FINGER_JVAR
% 小指三关节运动学：由输入 MCP 关节角序列 theta1 计算电缸行程 s，
% 并得到 theta2、theta3。
%
% 输入：
%   theta1 : 1×N 或 N×1（单位：rad）
% 输出：
%   j_var  : 4×N，j_var = [s; theta1; theta2; theta3]

    % ------- 小指固定参数（按你给的脚本）-------
    l     = [35,33.5,6,6,29.5,28.7,6,7,21.46,7,6.5];
    h     = 12.5;
    d     = 2.7;
    alpha = pi/6;
    beta  = pi/3;
    gamma = 3*pi/4;
    phi9  = 58.41/180*pi;
    zeta  = 150/180*pi;

    % 统一为行向量，便于拼接 4×N
    theta1_num = double(theta1_num(:).');

    % ------- 运动学求解 -------
    [phi_I_num,  ~] = PIP_kinematics(l, alpha, theta1_num);
    [phi_II_num, ~] = DIP_kinematics(l, alpha, beta, gamma, phi_I_num);
    phi_num = [phi_I_num; phi_II_num];

    theta2_num = pi - phi_num(3,:) - beta;
    theta3_num = pi - phi_num(7,:) - phi9;

    s_num = actuator_kinematics(l(10), l(11), h, d, alpha, zeta, phi_num(1,:));
    s_num = double(s_num(:).');  % 防止返回列向量导致维度不一致

    % ------- 输出 -------
    j_var = [s_num; theta1_num; theta2_num; theta3_num];
end