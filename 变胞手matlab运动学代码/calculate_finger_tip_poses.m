function g_tip = calculate_finger_tip_poses(H_t_num, g0_tip)
% CALCULATE_FINGERTIP_POSES 计算指尖坐标系位姿
% 根据 POE 理论执行 g_tip = H_t_num * g0_tip
%
% 输入:
%   H_t_num : 5x1 cell，各手指的相对齐次变换矩阵 (例如 4x4xNcxNp)
%   g0_tip  : 4x4x5 double，五指指尖的初始绝对齐次变换阵
%
% 输出:
%   g_tip_num : 5x1 cell，各手指真实的指尖绝对位姿 (维度与 H_t_num 一致)

    % 1. 基础校验
    assert(iscell(H_t_num) && length(H_t_num) == 5, 'H_t_num 必须是 5x1 cell');
    assert(isnumeric(g0_tip) && isequal(size(g0_tip), [4, 4, 5]), 'g0_tip 必须是 4x4x5 数组');
    
    % 2. 预分配内存
    g_tip = cell(5, 1);
    
    % 3. 遍历五根手指，进行极速张量乘法
    for i = 1:5
        % 提取当前手指的初始位姿 (4x4 矩阵)
        g0_i = g0_tip(:, :, i);
        
        % 提取当前手指的相对变换群 (4 x 4 x Nc_i x Np)
        Ht_i = H_t_num{i};
        
        % 核心加速：使用 pagemtimes 进行批量矩阵乘法
        % pagemtimes 会自动将右侧的 4x4 矩阵 g0_i，分别乘到 Ht_i 的第 3、4 维的每一页上
        % 无视 Nc_i 和 Np 是多少，计算速度极快
        g_tip{i} = pagemtimes(Ht_i, g0_i);
    end
end