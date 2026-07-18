function [H_tip_num, H_tb_cache] = calculate_finger_tip_H(Sf, H_palm, jvar_f)
% 输出 H_tip_num: 5×1 cell
%   - H_tip_num{i}: 4×4×Nc_i×Np (每根手指完全根据自己的采样点数 Nc_i 独立生成位姿)
% 输出 H_tb_cache: 5×1 cell
%   - H_tb_cache{i}: 4×4×Nc_i (手指局部齐次变换缓存)
%
% 输入：
%   Sf     : 6×3×5 double (初始旋量系)
%   H_palm : 4×4×5×Np double (手掌变胞位姿)
%   jvar_f : 5×1 cell (五指各自的关节变量全集)
    
    % 1. 输入维度基础校验
    assert(isnumeric(Sf) && isequal(size(Sf), [6,3,5]), 'Sf 必须是 6×3×5');
    
    assert(isnumeric(H_palm) && size(H_palm,1)==4 && size(H_palm,2)==4 ...
        && size(H_palm,3)==5, 'H_palm 必须是 4×4×5×Np (Np可以为1)');
        
    assert(iscell(jvar_f) && numel(jvar_f)==5, 'jvar_f 必须是 5×1 cell');
    
    % 获取手掌的变胞构态总数（即使 H_palm 是 3 维，size(..., 4) 也会安全返回 1）
    Np = size(H_palm, 4); 
    
    % --- 统一预分配输出为 5x1 cell 列向量 ---
    H_tb_cache = cell(5, 1);
    H_tip_num  = cell(5, 1);
    
    % 2. 统一遍历五根手指，完全解耦
    for i = 1:5
        % 动态获取当前手指的配置总数 Nc_i (例如拇指是 400，食指是 20)
        Nc_i = size(jvar_f{i}, 2);
        
        % 提取当前手指的关节角数据 (提取第 2~4 行)
        q = double(jvar_f{i}(2:4, :)); % 维度为 3 x Nc_i
        
        % --- 预计算局部变换矩阵 Htb (4 x 4 x Nc_i) ---
        Htb = zeros(4, 4, Nc_i);
        for c = 1:Nc_i
            Htb(:,:,c) = yield_H(Sf(:,1,i), q(1,c)) * ...
                         yield_H(Sf(:,2,i), q(2,c)) * ...
                         yield_H(Sf(:,3,i), q(3,c));
        end
        % 存入 5x1 的 cell 中
        H_tb_cache{i} = Htb;
        
        % --- 计算最终指尖齐次矩阵 (4 x 4 x Nc_i x Np) ---
        H_tip_num{i} = zeros(4, 4, Nc_i, Np);
        
        % 极速计算：遍历手掌构态，利用 pagemtimes 瞬间完成所有配置的相乘
        for p = 1:Np
            Hp = H_palm(:,:,i,p); % 取出当前手指在当前手掌姿态下的 4x4 变换阵
            
            % pagemtimes 自动将 4x4 的 Hp 乘以 Htb 的每一页(4x4xNc_i)
            H_tip_num{i}(:,:,:,p) = pagemtimes(Hp, Htb);
        end
    end
end