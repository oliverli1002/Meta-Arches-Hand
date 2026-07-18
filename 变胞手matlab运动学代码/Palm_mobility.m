%单心球面六杆手掌运动学。在手掌全局坐标系（圆心）下建立手掌旋量系，并根据约束方程求解手掌运动学
n = 6;%杆件数
g = 6;%运动副个数
f = ones(1,g);%第1至6个运动副的自由度
k = 2;%该k为对闭链机构进行分析时划分的支链数目
d_St1 = 21.3;%该d为拇指的St1到手掌球心的距离
% 手掌设计参数与输入关节变量
alpha = [pi/4,pi/9,7*pi/36,4*pi/9,5*pi/9,4*pi/9,3/180*pi];%这里alpha7为拇指St1与手掌S13之间夹角
theta_drive  = [-pi/18,pi/3,-pi/3];%手掌驱动关节变量
d_t = [d_St1*sin(alpha(7));d_St1*cos(alpha(7));0];%该d_t为在手掌连杆3的局部坐标系下的平移向量，该参数被传入yield_palm_screws中以得到St1

% 建立手掌旋量系
[Sl1,Sl1r,Sl2,Sl2r,S14,S23,St1] = yield_palm_screws(d_t);
% 建立约束方程，求解手掌运动学
[theta_var,theta_var_deg] = yield_palm_variables(Sl1,Sl2,S14,S23,alpha,theta_drive);

%求机构运动旋量系及阶数
Sr = unique([Sl1r Sl2r].','rows','stable').';%输出杆件约束旋量系（不包含重复元素）
Sr_mul = [Sl1r Sl2r];%输出杆件约束旋量系多重集
% 计算环路机构活动度
m = calculate_mobility(f,k,Sr_mul,Sr);

%赋值计算平面奇异构型下的活动度
alpha_val = [pi/4 pi/9 7*pi/36 4*pi/9 5*pi/9 4*pi/9];
theta_val = [0 0 0 0 0 0];
[Sl1_num, Sl2_num] = mobility_assign_params(Sl1, Sl2, alpha_val, theta_val);
Sl1r_num = null(Sl1_num.');
Sl2r_num = null(Sl2_num.');
Sr_num = unique([Sl1r_num Sl2r_num].','rows','stable').';
Sr_mul_num = [Sl1r_num Sl2r_num];
m_num = calculate_mobility(f,k,Sr_mul_num,Sr_num);
