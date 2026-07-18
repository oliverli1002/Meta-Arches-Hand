function [theta,forcedToZero] = caculate_palm_variables(Sl1,Sl2,S14,S23,alpha,theta_drive)
%{
该函数根据约束方程求取手掌各关节变量。传入手掌的两支链旋量系Sl1,Sl2，旋量S14,S23（用于形成
约束方程），杆件圆心角alpha，驱动关节变量数值theta_drive。传出手掌关节变量数值theta，以及
复数解的对应掩码forcedToZero。
%}

%%
% 建立约束方程求解关节角度
syms the [1 6] real;
syms alp [1 6] real;
num = size(theta_drive,2);

% 先代入alpha（double 1×6）以便求解
Sl1 = subs(Sl1, alp, alpha);
Sl2 = subs(Sl2, alp, alpha);
S14 = subs(S14, alp, alpha);
S23 = subs(S23, alp, alpha);
%{
根据输入关节变量θ1、θ2、θ6，通过几何约束（边界条件）求解被动关节变量θ3、θ4、θ5
S13.'*S24 = cosα3，求解θ5
S14.'*S24 = 1，求解θ3
S13.'*S23 = 1，求解θ4
%}
eq1 = Sl1(:,3).'*Sl2(:,1)-cos(alpha(3));%S13.'*S24 = cosα3，求解θ5
eq2 = S14.'*Sl2(:,1)-1;%S14.'*S24 = 1，求解θ3
eq3 = Sl1(:,3).'*S23-1;%S13.'*S23 = 1，求解θ4

%存在两个构型下的解sol1与sol2
[the5_sol1,the5_sol2] = calculate_angle(the5,eq1);
[the3_sol1,the3_sol2] = calculate_angle(the3,eq2);
[the4_sol1,the4_sol2] = calculate_angle(the4,eq3);

% %以下三行代码用于生成关节变量的解析解
% the3_sol1 = subs(the3_sol1,the5,the5_sol2);
% the4_sol1 = subs(the4_sol1,the5,the5_sol2);
% theta_sol = [the1;the2;the3_sol1;the4_sol1;the5_sol2;the6];

%%
%代入数值求解
% --------- 用 matlabFunction 编译成数值函数 ----------
% the5 只依赖驱动 the1,the2,the6
f5 = matlabFunction(the5_sol2, 'Vars', {the1, the2, the6});
%{
the3/the4 依赖驱动 + the5。注意，这里theta4只取了the5_sol2这一个分岔构型下的解，
相当于规定了theta4 = [-pi,0]
%}
f3 = matlabFunction(the3_sol1, 'Vars', {the1, the2, the6, the5});
f4 = matlabFunction(the4_sol1, 'Vars', {the1, the2, the6, the5});

tolImagSmall = 1e-5;% 定义虚部可忽略的精度

% 计算theta5
theta5 = zeros(1,num);
for i = 1:num
    t1 = theta_drive(1,i);
    t2 = theta_drive(2,i);
    t6 = theta_drive(3,i);
    theta5(i) = f5(t1,t2,t6);
end
% ---- theta5复数处理 ----
imagAbs_5 = abs(imag(theta5));% 取虚部绝对值
ok5 = imagAbs_5 <= tolImagSmall; % 生成逻辑向量，用于判断哪组数据虚部可忽略
theta5 = real(theta5);                % 虚部很小/纯实数 -> 保留实部
theta5(~ok5) = 0;             % 虚部不可忽略 -> 置0
% ---- theta5角度映射到 (-pi, pi]（只对有效点处理）----
t5 = theta5(ok5);
t5 = mod(t5 + pi, 2*pi) - pi;% 映射至 (-pi, pi]
theta5(ok5) = t5;

% 计算theta3
theta3 = zeros(1,num);
for i = 1:num
    t1 = theta_drive(1,i);
    t2 = theta_drive(2,i);
    t6 = theta_drive(3,i);
    theta3(i) = f3(t1,t2,t6,theta5(i));
end
% ---- theta3复数处理 ----
imagAbs_3 = abs(imag(theta3));
ok3 = imagAbs_3 <= tolImagSmall;
theta3 = real(theta3);
theta3(~ok3) = 0;
% ---- theta3角度映射到 (-pi, pi]（只对有效点处理）----
t3 = theta3(ok3);
t3 = mod(t3 + pi, 2*pi) - pi;% 映射至 (-pi, pi]
theta3(ok3) = t3;

% 计算theta4
theta4 = zeros(1,num);
for i = 1:num
    t1 = theta_drive(1,i);
    t2 = theta_drive(2,i);
    t6 = theta_drive(3,i);
    theta4(i) = f4(t1,t2,t6,theta5(i));
end
% ---- theta4复数处理 ----
imagAbs_4 = abs(imag(theta4));
ok4 = imagAbs_4 <= tolImagSmall;
theta4 = real(theta4);
theta4(~ok4) = 0;
% ---- theta4角度映射到 [-pi, 0]（只对有效点处理）----
t4 = theta4(ok4);
% 先 wrap 到 (-pi, pi]
t4 = mod(t4 + pi, 2*pi) - pi;
% 再把 (0, pi] 映射到 (-pi, 0]
pos = t4 > 0;
t4(pos) = t4(pos) - pi;
theta4(ok4) = t4;

% % ---- 统计向量 forcedToZero：theta5 theta3 和 theta4 的虚部都可忽略 => 记为1 ----
% forcedToZero = ok5 & ok3 & ok4;          % 1×num logical（true/false）
% 
% % ---- 组装 theta: 6×num，每列一组 [theta1;theta2;theta3;theta4;theta5;theta6] ----
% theta = zeros(6, num);
% theta(1,:) = theta_drive(1,:);  % theta1
% theta(2,:) = theta_drive(2,:);  % theta2
% theta(3,:) = theta3;            % theta3
% theta(4,:) = theta4;            % theta4
% theta(5,:) = theta5;            % theta5
% theta(6,:) = theta_drive(3,:);  % theta6
% 
% % ---- 按 forcedToZero 置零：只要该列存在虚数解(=forcedToZero为false)，整列关节变量全置0 ----
% theta(:, ~forcedToZero) = 0;
% theta = theta(:, forcedToZero);   % 只保留有效列

% 定义被动关节的物理限位
lim3_low = 0;
lim3_up  = 2*pi;
lim4_low = -pi/2;
lim4_up  = 0;
lim5_low = -48.8 * pi/180;
lim5_up  = 43.7 * pi/180;

% 判断各关节是否在允许的物理范围内
% 注意：即使是之前被置为 0 的无效点，也会在最终的 & 操作中被 ok3/ok4/ok5 剔除，所以直接全量判断非常安全
range3_ok = (theta3 >= lim3_low) & (theta3 <= lim3_up);
range4_ok = (theta4 >= lim4_low) & (theta4 <= lim4_up);
range5_ok = (theta5 >= lim5_low) & (theta5 <= lim5_up);
% ============================================================

% ---- 统计向量 forcedToZero：虚部可忽略 且 在物理限位内 => 记为1 ----
% 原代码：forcedToZero = ok5 & ok3 & ok4;
forcedToZero = ok5 & ok3 & ok4 & range3_ok & range4_ok & range5_ok; 

% ---- 组装 theta: 6×num，每列一组 [theta1;theta2;theta3;theta4;theta5;theta6] ----
theta = zeros(6, num);
theta(1,:) = theta_drive(1,:);  % theta1
theta(2,:) = theta_drive(2,:);  % theta2
theta(3,:) = theta3;            % theta3
theta(4,:) = theta4;            % theta4
theta(5,:) = theta5;            % theta5
theta(6,:) = theta_drive(3,:);  % theta6

% ---- 按 forcedToZero 置零：只要该列存在虚数解或超限，整列关节变量全置0 ----
theta(:, ~forcedToZero) = 0;

% 只保留有效列（此时输出的 theta 列数就是剔除了虚数和限位干涉后的有效数据）
theta = theta(:, forcedToZero);
end