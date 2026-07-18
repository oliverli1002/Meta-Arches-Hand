function [phi_I_num,phi_I_sol] = PIP_kinematics(l_num,alpha_num,theta_num)
%{
该函数用于求模块化三指的指节1的运动学。
已知输入驱动角度theta_num与手指设计参数l_num、alpha_num，求反平行四边形机构的四个连杆夹角phi。
%}

%声明符号变量。real代表实数，positive代表正数
syms l [1 4] positive;
syms alp theta ep real;% ep = phi3-theta;

%{
反平行四边形机构指节1的约束方程。原方程为：
l1*sin(theta)+l3*sin(alp)+l4*sin(phi3-theta)=l2*sin(phi2+alp)
l1*cos(theta)-l3*cos(alp)-l4*sin(phi3-theta)=-l2*cos(phi2+alp)
%}
eq1 = l1*sin(theta)+l3*sin(alp)+l4*sin(ep);
eq2 = l1*cos(theta)-l3*cos(alp)-l4*cos(ep);
eq3 = simplify(expand(eq1^2+eq2^2-l2^2));
eq4 = expand(rewrite(eq3,'sincos'));

[ep_sol1,ep_sol2] = calculate_angle(ep,eq4);
% phi3_sol2 = ep_sol2+theta;%根据手指机构设计这里只选sol1
phi3_sol = ep_sol1+theta;
phi2_sol = atan2(eq1,-eq2)-alp;
phi1_sol = alp+theta;
phi4_sol = phi1_sol+phi2_sol-phi3_sol;
phi_I_sol = [phi1_sol;phi2_sol;phi3_sol;phi4_sol];
phi_I_sol = subs(phi_I_sol,ep,ep_sol1);
f = matlabFunction(phi_I_sol, 'Vars', {l1,l2,l3,l4,alp,theta});
phi_I_num = f(l_num(1), l_num(2), l_num(3), l_num(4), alpha_num, theta_num);

% ---------- 复数处理 ----------
tolImagSmall = 1e-5;                  % 虚部可忽略阈值
imagAbs = abs(imag(phi_I_num));      % 4×n
ok = all(imagAbs <= tolImagSmall, 1); % 1×n：这一列4个角都“虚部可忽略”才算有效

phi_I_num = real(phi_I_num);        % 可忽略虚部 -> 保留实部
phi_I_num(:, ~ok) = 0;               % 不可忽略 -> 整列置0（和你theta5风格一致）
tmp = phi_I_num(:, ok);
% ---- 角度映射到 [0, pi]（只对有效点处理）----
tmp = abs(mod(tmp + pi, 2*pi) - pi);   % 一行映射到 [0, pi]
phi_I_num(:, ok) = tmp;
end