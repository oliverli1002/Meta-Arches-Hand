%%该段定义设计参数与各关节变量
%{
手掌的设计参数。其中n为杆件数，g为运动副个数，f为第1至6个运动副的自由度，k为
对闭链机构进行分析时划分的支链数目，alpha为连杆圆心角，t1和t2分别为中性面到
手掌前表面（手掌上的指根坐标在zp方向上的偏置）与拇指手掌连杆前表面
（手掌上的指根坐标在zp方向上的偏置）的距离。
%}
n = 6;
g = 6;
f = ones(1,g);
k = 2;
alpha = [pi/4,pi/9,7*pi/36,4*pi/9,5*pi/9,4*pi/9];
t1 = 16;
t2 = 11;
%在小论文的指根基关节定义中，其处于冠状面，t1与t2没有用到。

%生成五指的驱动关节变量。原采样数量均为100。
theta_t1 = linspace(-25*pi/180,-133.5*pi/180,30);
theta_t2 = linspace(9.44*pi/180,82.27*pi/180,30);
theta_i1 = linspace(0,84*pi/180,30);
theta_m1 = linspace(0,84*pi/180,30);
theta_r1 = linspace(0,84*pi/180,30);
theta_l1 = linspace(0,84*pi/180,30);
%计算五指的关节变量
jvar_t = calculate_thumb_variables(theta_t1,theta_t2);
jvar_t_bd = calculate_thumb_variables_bending(theta_t2);
jvar_i = calculate_modularized_finger_variables(theta_i1);
jvar_m = calculate_modularized_finger_variables(theta_m1);
jvar_r = calculate_modularized_finger_variables(theta_r1);
jvar_l = calculate_little_finger_variables(theta_l1);
jvar_f = {jvar_t;jvar_i;jvar_m;jvar_r;jvar_l};

%{
五指的设计参数。
L的5列对应五指，L第一行为五指基坐标系到全局坐标系的距离，
第二行为手指基坐标系原点至mcp关节旋量距离(注意，在论文中手指坐标系定义在mcp关节)，
第三四五行分别为指节长度。gamma的5列对应五指，gamma第一行为手掌全局坐标到五指指根坐标向量的圆心角，
第二行为五指基坐标系y0轴朝向与竖直方向的偏角，
三四五行分别为五指在初始状态下三指节的关节角。
%}
%拇指这里第二行15.4为拇指基坐标系原点在xoz平面上至St2的距离，第三行27.25为拇指基坐标系原点在xoy平面上至St2的距离
l_t = [65.56;  15.4; 27.25; 52.5; 32.62];
l_i = [80.96; 13.75;   45 ;   38; 27.29];
l_m = [73.32; 15.83;   45 ;   38; 27.29];
l_r = [74.17;  9.55;   45 ;   38; 27.29];
l_l = [82.15;  9.41;   35 ; 29.5; 21.46];
L = [l_t, l_i, l_m, l_r, l_l];

%q手处于初始构型下，各设计角度和各手指关节角度。q_ini记录关节角度。
gamma_t = [99.04*pi/180;  28*pi/180;           0; jvar_t(3,1); jvar_t(4,1)];
gamma_i = [35.02*pi/180;  10*pi/180; jvar_i(2,1); jvar_i(3,1); jvar_i(4,1)];
gamma_m = [ 12.2*pi/180;   0*pi/180; jvar_m(2,1); jvar_m(3,1); jvar_m(4,1)];
gamma_r = [16.71*pi/180;   8*pi/180; jvar_r(2,1); jvar_r(3,1); jvar_r(4,1)];
gamma_l = [39.68*pi/180;  17*pi/180; jvar_l(2,1); jvar_l(3,1); jvar_l(4,1)];
gamma = [gamma_t,gamma_i,gamma_m,gamma_r,gamma_l];
q_ini = gamma(3:5,:);

%%
%该段用于计算全局坐标系到五指指根坐标系的齐次变换。
%生成关节角用于绘制工作空间。先遍历theta1，再遍历theta2，最后遍历theta6。
theta_p1 = linspace(-11*pi/180,15.2*pi/180,20);%25.8°
theta_p2 = linspace(-60*pi/180,pi,200);%240°
theta_p6 = linspace(-pi/2,45.5*pi/180,105);%135.5°
[T1,T2,T6] = ndgrid(theta_p1,theta_p2,theta_p6);
theta_p = [T1(:)'; T2(:)'; T6(:)'];

%注意，以下变量中带有"_ini"后缀的都是表示变胞手处于initial的初始位置。
%建立手掌旋量系
[Sl1,~,Sl2,~,S14,S23] = yield_palm_screws();
%建立约束方程，求解手掌运动学(得到手掌6个关节变量)
[jvar_p,forcedToZero] = caculate_palm_variables(Sl1,Sl2,S14,S23,alpha,theta_p);
jvar_p_deg = (symRad2DoubleDeg(jvar_p)).';
% writematrix(jvar_p_deg, 'Palm_Variables.xlsx');%将手掌关节变量写进excel表格
%手掌的6个关节变量的初始值（手掌处于平面状态下）
jvar_p_ini = zeros(6, 1);
%求算手掌初始状态下的旋量轴线。其中最后一个传入变量"0"代表所有关节变量取0
[Sl1_ini,Sl2_ini] = calculate_initial_palm_screws(Sl1,Sl2,alpha,0);
%手掌指根坐标系初始位姿数值解
g0_base = yield_initial_finger_base_coordinates(L,gamma,t1,t2);
%全局坐标系至各指根坐标系的齐次变换矩阵
[H_p_num, ~] = calculate_palm_H(Sl1_ini,Sl2_ini,jvar_p);
[H_p_num_ini, ~] = calculate_palm_H(Sl1_ini,Sl2_ini,jvar_p_ini);

%%
% 该段用于计算全局坐标系到五指指尖坐标系的齐次变换。
% 建立五指旋量系。其中r3_f为五指远指节旋量到手掌全局坐标系的距离向量。
[Sf, r3_f] = yield_finger_screws();
%求算初始状态下手指的旋量轴线
Sf_ini = calculate_initial_finger_screws(L, gamma, Sf);
%指尖坐标系初始位姿数值解
g0_tip = yield_initial_finger_tip_coordinates(L, gamma, r3_f);
%全局坐标系至各手指指尖坐标系的齐次变换矩阵。其中H_t = H_p * H_tb。
[H_t_num,H_tb_num] = calculate_finger_tip_H(Sf_ini, H_p_num, jvar_f,q_ini);
[H_t_num_ini, H_tb_num_ini] = calculate_finger_tip_H(Sf_ini, H_p_num_ini, jvar_f,q_ini);

%
%该段用于计算指根坐标系位姿
g_base_num = calculate_fingerbase_poses(H_p_num, g0_base);
%该段用于计算指尖坐标系位姿
g_tip_num = calculate_finger_tip_poses(H_t_num, g0_tip);
g_tip_num_ini = calculate_finger_tip_poses(H_t_num_ini, g0_tip);
%该段用于计算指尖坐标系位姿(相对于各自基坐标系)
g_tip_base = calculate_tip_wrt_base(g_tip_num_ini, g0_base);

%该段用于绘制变胞手整手的工作空间
WS_palm = plot_palm_workspace(g_base_num, 5000);
WS_fold1 = plot_hand_workspace_foldpalm(g_tip_num,5000);
WS_fold2 = plot_hand_workspace_foldpalm_test(g_tip_num, 5000);

%%
%对手指驱动关节变量进行重新采样，绘制手掌不发生翻折情况下的变胞手工作空间
g_tip_num_dense = resample_g_tip_num_dense(Sf_ini, H_p_num_ini, g0_tip, q_ini);
WS_unfold = plot_hand_workspace_inipalm(g_tip_num_dense,400);
% 利用逆矩阵映射回局部指根坐标系
g_tip_base_dense = calculate_tip_wrt_base(g_tip_num_dense, g0_base); 


%调用专属函数分别绘制高密度点云
WS_thumb = plot_thumb_workspace(g_tip_base_dense);
WS_index = plot_index_workspace(g_tip_base_dense);

