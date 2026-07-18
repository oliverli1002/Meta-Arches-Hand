function g0_num = yield_initial_finger_tip_coordinates(L, gamma, r3)
%YIELD_INITIAL_FINGER_TIP_COORDINATES 生成五指指尖齐次变换 g0，并代入数值得到 g0_num
%
% 输入：
%   L     : 5×5 数值 (与符号 l 对应)
%   gamma : 5×N 或 5×5 数值（你这里用到 gamma(1,:), gamma(2,:), gamma(3:5,:)）
%           约定：gamma(1,:)=bet，gamma(2,:)=gam，gamma(3:5,:)=the(1:3,:)
%   r3    : 3×5 数值/符号均可（每指第3关节位置向量）
%
% 输出：
%   g0_num: 4×4×5 数值数组，g0_num(:,:,f) 为第 f 指在全局下的齐次变换

% ---- 符号定义（用于构造通用表达式，然后一次 matlabFunction）----
syms l   [5 5] positive
syms bet [1 5] real
syms gam [1 5] real
syms the [3 5] real

z = [0;0;1];
y = [0;1;0];

% 统一存放
p0 = sym(zeros(3,1,5));
R0 = sym(zeros(3,3,5));

% -------- 拇指：保持你原来的特殊角度关系 --------
% 指尖位置
tip_ang_t = the(2,1) - (gam(1) - the(1,1));  % = the2 - gam + the1
p0(:,:,1) = [ -l(5,1)*cos(tip_ang_t) + r3(1,1);
    -l(5,1)*sin(tip_ang_t) + r3(2,1);
    r3(3,1) ];

% 基坐标系姿态
R0(:,:,1) = yield_R(z, pi/2 - gam(1) + the(1,1) + the(2,1)) * yield_R(y, -pi/2);

% -------- 其余四指（2~5）：共用模板，用 y 符号区分 --------
% 食/中：y 为正；无/小：y 为负
sgn_y = [NaN, +1, +1, -1, -1];

for f = 2:5
    thsum = the(1,f) + the(2,f) + the(3,f);

    % 指尖位置：x 统一是 -cos(g)*cos(thsum)，y 用符号，z 是 sin(thsum)
    p0(:,:,f) = [ -l(5,f)*cos(thsum)*cos(gam(f)) + r3(1,f);
        sgn_y(f)*l(5,f)*cos(thsum)*sin(gam(f)) + r3(2,f);
        l(5,f)*sin(thsum) + r3(3,f) ];

    % 基坐标系姿态：你原式对食指用 (pi/2 - gam)，其余用 (pi/2 + gam)
    % 结合你写法：f=2 是减号，f=3~5 是加号
    if f == 2
        z_ang = (pi/2 - gam(f));
    else
        z_ang = (pi/2 + gam(f));
    end
    R0(:,:,f) = yield_R(z, z_ang) * yield_R(y, thsum);
end

% -------- 拼齐次变换 --------
g0 = sym(zeros(4,4,5));
for f = 1:5
    g0(:,:,f) = [R0(:,:,f), p0(:,:,f); 0 0 0 1];
end

% -------- 一次性生成数值函数并代入 --------
F = matlabFunction(g0, 'Vars', {l, bet, gam, the});
g0_num = F(L, gamma(1,:), gamma(2,:), gamma(3:5,:));
end