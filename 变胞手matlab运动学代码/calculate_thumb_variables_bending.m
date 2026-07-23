function j_var = calculate_thumb_variables_bending(theta2)
%CALCULATE_THUMB_VARIABLES_BENDING 计算仅由 theta2 变化引起的拇指关节变量。
%   输入：
%       theta2 : 1xN 或 Nx1 的拇指弯曲关节角，单位为 rad
%   输出：
%       j_var  : 3xN double，按 [s; theta2; theta3] 排列

% 拇指机构固定参数，与 calculate_thumb_variables 保持一致。
l     = [52.5, 50.5, 6, 6, 32.62, 7.5, 6.5];
h     = 12.5;
d     = 2.7;
alpha = pi/6;
phi9  = 50.34/180*pi;
zeta  = 155/180*pi;

% 统一为 double 行向量，保证函数输出尺寸为 3xN。
theta2 = double(theta2(:).');

% 根据 theta2 求解拇指耦合关节 theta3 及电缸行程 s。
[phi_num, ~] = PIP_kinematics(l, alpha, theta2);
theta3 = pi - phi_num(3,:) - phi9;
s = actuator_kinematics(l(6), l(7), h, d, alpha, zeta, phi_num(1,:));
s = double(s(:).');

j_var = [s; theta2; theta3];
end
