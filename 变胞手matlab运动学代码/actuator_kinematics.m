function s_num = actuator_kinematics(l10_num,l11_num,h_num,d_num,alp_num,zet_num,phi1_num)
%{
该函数用于求手指关节空间到驱动器驱动空间slider–crank mechanism
的逆运动学，即根据desired的指节转角θ1反求电缸的输入s
%}

%声明符号变量。real代表实数，positive代表正数
syms l10 l11 h d s positive;
syms alp phi1 zet real;

%{
slider–crank mechanism的约束方程。原方程为：
h-s-l10*sin(zet-phi-(pi/2-alp)) = l11*sin(eta)，这里eta角是l11的方向角可以消掉
l10*cos(zet-phi-(pi/2-alp))-d = l11*cos(eta)，这里eta角是l11的方向角可以消掉
%}
eq1 = h-s-l10*sin(zet-phi1-(pi/2-alp));
eq2 = l10*cos(zet-phi1-(pi/2-alp))-d;
eq3 = simplify(expand(eq1^2+eq2^2-l11^2));

S = solve(eq3==0,s,'ReturnConditions',true);
sol = S.s(1);% 选分支1
f = matlabFunction(sol, 'Vars', {l10,l11,h,d,alp,zet,phi1});
s_num = f(l10_num, l11_num, h_num, d_num, alp_num, zet_num, phi1_num);% phi1_num是1×100，输出同尺寸
end