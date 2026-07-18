function j_var = calculate_thumb_variables(theta1,theta2)
%THUMB_JVAR
% 拇指三关节运动学：由输入 MCP 关节角序列 theta1 计算电缸行程 s，
% 并得到 theta2、theta3。
%
% 输入：
%   theta1 : 1×N 或 N×1（单位：rad）
% 输出：
%   j_var  : 4×N，j_var = [s; theta1; theta2; theta3]

% ------- 拇指固定参数-------
l     = [52.5,50.5,6,6,32.62,7.5,6.5];
h     = 12.5;
d     = 2.7;
alpha = pi/6;
phi9  = 50.34/180*pi;
zeta  = 155/180*pi;

% 统一为行向量，便于拼接 4×N
theta1 = double(theta1(:).');
theta2 = double(theta2(:).');

N1 = numel(theta1);
N2 = numel(theta2);

% --- 生成组合网格：N2×N1 ---
% T1, T2 都是 N2×N1
[T1, T2] = meshgrid(theta1, theta2);

% 展平成 1×(N1*N2)，并约定顺序：theta2 快速变化，theta1 慢速变化
theta1_all = reshape(T1, 1, []);
theta2_all = reshape(T2, 1, []);
% ------- 运动学求解 -------
[phi_num,  ~] = PIP_kinematics(l, alpha, theta2_all);
theta3_all = pi - phi_num(3,:)-phi9;

s_all = actuator_kinematics(l(6), l(7), h, d, alpha, zeta, phi_num(1,:));
% 统一 s 为行向量（避免 actuator_kinematics 返回列向量导致维度不一致）
s_all = double(s_all(:).');

% ------- 输出 -------
j_var = [s_all;theta1_all;theta2_all;theta3_all];
end