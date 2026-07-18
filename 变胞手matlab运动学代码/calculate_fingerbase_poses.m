function g_base_num = calculate_fingerbase_poses(H_p_num, g0_base)
% CALCULATE_BASE_POSES 计算各指根坐标系的真实绝对位姿
% 根据 POE 理论执行 g_base = H_p_num * g0_base
%
% 输入:
%   H_p_num : 4x4x5xNp double，全局到各指根的相对变换
%   g0_base : 4x4x5 double，各指根的初始绝对位姿
% 输出:
%   g_base_num : 4x4x5xNp double，各指根真实的绝对位姿

    % 1. 基础校验 (兼容 Np=1 的初始姿态)
    assert(isnumeric(H_p_num) && size(H_p_num,1)==4 && size(H_p_num,2)==4 && size(H_p_num,3)==5, ...
        'H_p_num 格式错误，应为 4x4x5xNp');
    assert(isnumeric(g0_base) && isequal(size(g0_base), [4, 4, 5]), ...
        'g0_base 必须是 4x4x5 数组');
        
    Np = size(H_p_num, 4);
    g_base_num = zeros(4, 4, 5, Np);
    
    % 2. 遍历五根手指，进行极速张量乘法
    for i = 1:5
        % 提取当前手指指根的初始绝对位姿 (4x4)
        g0_i = g0_base(:, :, i);          
        
        % 提取当前手指指根的相对变换矩阵群 (4x4x1xNp)
        Hp_i = H_p_num(:, :, i, :);       
        
        % 将其降维压缩为 4x4xNp，以适配 pagemtimes
        Hp_i_reshaped = reshape(Hp_i, 4, 4, Np); 
        
        % 计算绝对位姿，并将其升维恢复为 4x4x1xNp 存入结果
        g_base_num(:, :, i, :) = reshape(pagemtimes(Hp_i_reshaped, g0_i), 4, 4, 1, Np);
    end
end