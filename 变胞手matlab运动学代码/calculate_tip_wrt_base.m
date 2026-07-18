function g_tip_base = calculate_tip_wrt_base(g_tip_num_ini, g0_base)
% CALCULATE_TIP_WRT_BASE 计算局部指根坐标系下的指尖位姿
% 根据齐次变换法则执行 g_tip_base = inv(g0_base) * g_tip_ini
%
% 输入:
%   g_tip_num_ini : 5x1 cell，手掌初始状态下的指尖绝对位姿 (4x4xNc)
%   g0_base       : 4x4x5 double，五指指根的初始绝对位姿
%
% 输出:
%   g_tip_base    : 5x1 cell，指根坐标系下的指尖相对位姿 (4x4xNc)

    % 1. 基础校验
    assert(iscell(g_tip_num_ini) && length(g_tip_num_ini) == 5, 'g_tip_num_ini 必须是 5x1 cell');
    assert(isnumeric(g0_base) && isequal(size(g0_base), [4, 4, 5]), 'g0_base 必须是 4x4x5 数组');
    
    % 2. 预分配内存
    g_tip_base = cell(5, 1);
    
    % 3. 遍历五根手指，进行极速张量乘法
    for i = 1:5
        % 提取第 i 根手指的指根初始绝对位姿 (4x4 矩阵)
        g0_b_i = g0_base(:, :, i);
        
        % 求指根绝对位姿的逆矩阵 (4x4)
        inv_g0_b_i = inv(g0_b_i);
        
        % 提取第 i 根手指在手掌静止时的指尖绝对位姿群 (4 x 4 x Nc_i)
        g_tip_ini_i = g_tip_num_ini{i};
        
        % 核心加速：使用 pagemtimes 将 4x4 的逆矩阵乘到成百上千个指尖位姿矩阵上
        % 相当于批量执行：指根系下的位姿 = 指根到全局的逆 * 全局下的指尖位姿
        g_tip_base{i} = pagemtimes(inv_g0_b_i, g_tip_ini_i);
    end
end