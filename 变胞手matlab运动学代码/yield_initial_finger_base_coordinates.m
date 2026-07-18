function g0_num = yield_initial_finger_base_coordinates(L,gamma,t1_num,t2_num)
%该函数用于生成手掌处于平面状态下（初始位置）手掌上的指根坐标系位姿。

syms l [1 5] positive;
syms bet [1 5] real;
syms gam [1 5] real;
syms t1 t2;
z = [0;0;1];%全局坐标系z轴
y = [0;1;0];%全局坐标系y轴

%五指基坐标系的位置
p0_t=[l1*sin(bet1-pi/2);l1*cos(bet1-pi/2);t2];
p0_i=[-l2*cos(bet2);l2*sin(bet2);t1];
p0_m=[-l3*cos(bet3);l3*sin(bet3);t1];
p0_r=[-l4*cos(bet4);-l4*sin(bet4);t1];
p0_l=[-l5*cos(bet5);-l5*sin(bet5);t1];
%五指基坐标系的姿态
R0_t =  yield_R(z,(pi/2-gam1))*yield_R(y,-pi/2);%从右向左，在全局坐标系下
R0_i =  yield_R(z,(pi/2-gam2));
R0_m =  yield_R(z,(pi/2+gam3));
R0_r =  yield_R(z,(pi/2+gam4));
R0_l =  yield_R(z,(pi/2+gam5));
%沿第3维堆叠这5个3×1向量
p0 = cat(3, p0_t, p0_i, p0_m, p0_r, p0_l);
%沿第3维堆叠这5个3×3矩阵
R0 = cat(3, R0_t, R0_i, R0_m, R0_r, R0_l);

%这段代码是在构造5个齐次变换矩阵，并把它们按第3维堆叠成一个数组g0
g0 = sym(zeros(4,4,5));
for i = 1:5
    g0(:,:,i) = [R0(:,:,i), p0(:,:,i);
        0 0 0,     1];
end

%代入参数求数值解
f = matlabFunction(g0, 'Vars', {l, bet, gam, t1, t2});
g0_num = f(L(1,:), gamma(1,:), gamma(2,:), t1_num, t2_num);
end
