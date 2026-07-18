function [Sl1,Sl1r,Sl2,Sl2r,S14,S23] = yield_palm_screws()
%{
该函数用于生成手掌关节旋量。传入六杆圆心角alpha与拇指偏转轴线的圆心距d_t，传出手掌各关节旋量
注意，若使用Chasles运动的方法计算各关节单位旋量，则相当于每一次运动都是
绕前一根杆件的局部坐标系进行的。
%}

%声明符号变量。这里real代表符号变量是实数，在进行simplify涉及三角函数时简化更彻底
syms alp [1 6] real;
syms the [1 6] real;
zp = [0;0;1];

%支链1运动旋量系
S11 = [1;0;0;0;0;0];
S11_n = chasles_motion(S11,zp,alp1);
S12 = chasles_motion(S11_n,S11,the1);
z_1 =  yield_R(S11,the1)*zp;%杆件1局部坐标系的z轴，垂直于其所在平面
S12_n = chasles_motion(S12,z_1,alp2);
S13 = chasles_motion(S12_n,S12,the2);
Sl1 = [S11 S12 S13];
%支链1约束旋量系
Sl1r = null(Sl1.');
%支链1下J4关节的单位旋量，用于边界条件求解角度
z_2 =  yield_R(S12,the(2))*z_1;%杆件2局部坐标系的z轴，垂直于其所在平面
S13_n = chasles_motion(S13,z_2,alp(3));
S14 = chasles_motion(S13_n,S13,the(3));
% %以下用于求算拇指偏转关节的St1旋量
% z_3 =  yield_R(S13,the(3))*z_2;%杆件3局部坐标系的z轴，垂直于其所在平面
% St1 = chasles_motion(S13,z_3,-alp(7),d_t);
% St1_num = subs(St1,alp(1:7),alpha);

%支链2运动旋量系
S26 = chasles_motion(S11,zp,-alp6);%支链2是绕z轴顺时针旋转，故这里α要加负号
S26_n = chasles_motion(S26,zp,-alp5);
S25 = chasles_motion(S26_n,S26,the6);
z_5 =  yield_R(S26,the6)*zp;%杆件5局部坐标系的z轴
S25_n = chasles_motion(S25,z_5,-alp4);%支链2是绕z轴顺时针旋转，故这里α要加负号
S24 = chasles_motion(S25_n,S25,the5);
Sl2 = [S24 S25 S26];
%支链2约束旋量系
Sl2r = null(Sl2.');
%支链2下J3关节的单位旋量，用于边界条件求解角度
z_4 =  yield_R(S25,the5)*z_5;%杆件4局部坐标系的z轴
S24_n = chasles_motion(S24,z_4,-alp3);
S23 = chasles_motion(S24_n,S24,the4);
end