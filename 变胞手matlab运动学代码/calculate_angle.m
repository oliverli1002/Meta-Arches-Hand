function [theta_sol1,theta_sol2] = calculate_angle(theta,eq)
%{
该函数将传入等式化简为只包含sin(theta)&cos(theta)的一次项
的线性方程，以便利用atan2函数反求包含两支解的theta值。

传入参数：theta-待求角度，eq-等式
传出参数：两支解
%}

syms st ct real

assumeAlso(st^2 + ct^2 == 1)

eq_subs = subs(eq,[sin(theta), cos(theta)],[st, ct]);
deg_total = polynomialDegree(eq_subs, [st, ct]);
if deg_total > 1
    error("方程含有 sin/cos 的二次及以上项（关于 st,ct 的总次数=%d）。", deg_total);
end

eq_iso = collect(eq_subs, [st,ct]);% 化成有关st和ct的多项式
%构造方程Asinθ+Bcosθ+C=0
C = subs(eq_iso, [st,ct], [0,0]);
A = subs(eq_iso, [st,ct], [1,0]) - C;
B = subs(eq_iso, [st,ct], [0,1]) - C;
%改写为极坐标，有Rcosφ=A,Rsinφ=B
R = sqrt(A^2 + B^2);%极半径
phi = atan2(B, A);%Rcosφ=A,Rsinφ=B代入方程Asinθ+Bcosθ+C=0，求极角
rhs = -C/R;%sin(θ+φ)=−C/R 
% 求theta两支解
theta_sol1 = asin(rhs) - phi;
theta_sol2 = pi - asin(rhs) - phi;
end