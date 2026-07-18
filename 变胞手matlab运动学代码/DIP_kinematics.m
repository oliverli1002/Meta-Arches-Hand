function [phi_II_num,phi_II_sol] = DIP_kinematics(l_num,alpha_num,beta_num,gamma_num,phi_num)
%{
该函数用于求模块化三指的指节2的运动学。
已知近指节（指节1）四个连杆夹角phi_num与手指设计参数，求中指节（指节2）反平行四边形机构的四个连杆夹角phi。
%}

%声明符号变量。real代表实数，positive代表正数
syms l5 l6 l7 l8 positive;
syms phi [1 4] real
syms alp bet gam ep real;% ep = phi7 + del;

phi5_sol = 2*pi-phi3-bet-gam;
del = bet-(phi4-(phi2-(pi/2-alp)));

%{
反平行四边形机构指节2的约束方程。原方程为：
l5*cos(del) - l7*cos(phi5 + del) - l8*cos(phi7 + del)=-l6*cos(del+phi7+phi8)
l5*sin(del) - l7*sin(phi5 + del) - l8*sin(phi7 + del)=-l6*sin(del+phi7+phi8)
%}
eq1 = l5*cos(del) - l7*cos(phi5_sol + del) - l8*cos(ep);
eq2 = l5*sin(del) - l7*sin(phi5_sol + del) - l8*sin(ep);
eq3 = simplify(expand(eq1^2+eq2^2-l6^2));
eq4 = expand(rewrite(eq3,'sincos'));

[ep_sol1,ep_sol2] = calculate_angle(ep,eq4);
% ep_sol_num = vpa(subs(ep_sol1,[l5,l6,l7,l8,bet,gam],[l_num(5:8),beta_num,gamma_num]));
phi7_sol = ep_sol1-del;
% phi7_sol2 = ep_sol2-del;%根据手指机构设计这里只选sol1
phi8_sol = atan2(-eq2,-eq1)-ep_sol1;
phi6_sol = phi7_sol+phi8_sol-phi5_sol;
phi_II_sol = [phi5_sol;phi6_sol;phi7_sol;phi8_sol];
phi_II_sol = subs(phi_II_sol,ep,ep_sol1);
f = matlabFunction(phi_II_sol, 'Vars', {l5,l6,l7,l8,alp,bet,gam,phi1,phi2,phi3,phi4});
% ---------- 计算角度值 ----------
n = size(phi_num,2);
phi_II_num = zeros(4,n);
for i = 1:n
    phi_II_num(:,i) = f(l_num(5),l_num(6),l_num(7),l_num(8),alpha_num,beta_num,gamma_num,...
        phi_num(1,i),phi_num(2,i),phi_num(3,i),phi_num(4,i));
end

% ---------- 复数处理 ----------
tolImagSmall = 1e-5;                  % 虚部可忽略阈值
imagAbs = abs(imag(phi_II_num));      % 4×n
ok = all(imagAbs <= tolImagSmall, 1); % 1×n：这一列4个角都“虚部可忽略”才算有效

phi_II_num = real(phi_II_num);        % 可忽略虚部 -> 保留实部
phi_II_num(:, ~ok) = 0;               % 不可忽略 -> 整列置0（和你theta5风格一致）
tmp = phi_II_num(:, ok);
% ---- 角度映射到 [0, pi]（只对有效点处理）----
tmp = abs(mod(tmp + pi, 2*pi) - pi);   % 一行映射到 [0, pi]
phi_II_num(:, ok) = tmp;

end