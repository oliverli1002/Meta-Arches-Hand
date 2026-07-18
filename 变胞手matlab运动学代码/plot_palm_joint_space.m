function plot_palm_joint_space(T1, T2, T6)
% PLOT_PALM_JOINT_SPACE 绘制变胞手掌六杆机构的三维关节空间曲面 (包络面)
% 输入 T1, T2, T6 可以是一维数组，或者是 ndgrid 生成的三维矩阵 (弧度制)

    % --- 1. 数据预处理：转换为角度制以提升可读性 ---
    T1_deg = T1(:) * 180 / pi;
    T2_deg = T2(:) * 180 / pi;
    T6_deg = T6(:) * 180 / pi;
    
    % 提取关节空间的极值边界
    min_t1 = min(T1_deg); max_t1 = max(T1_deg);
    min_t2 = min(T2_deg); max_t2 = max(T2_deg);
    min_t6 = min(T6_deg); max_t6 = max(T6_deg);

    % --- 2. 初始化高规格图窗 ---
    figure('Name', 'Palm Joint Space', 'Color', 'w');
    hold on; grid on;
    set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 40, 'Color', [0.98, 0.98, 0.98], ...
        'LineWidth', 2, 'GridLineWidth', 2, 'GridAlpha', 0.25);
    view(35, 25);
    
    % --- 3. 定义关节空间包络盒的 8 个顶点和 6 个面 ---
    % 顶点矩阵 (V)
    V = [min_t1, min_t2, min_t6;  % 1: 左下后
         max_t1, min_t2, min_t6;  % 2: 右下后
         max_t1, max_t2, min_t6;  % 3: 右上后
         min_t1, max_t2, min_t6;  % 4: 左上后
         min_t1, min_t2, max_t6;  % 5: 左下前
         max_t1, min_t2, max_t6;  % 6: 右下前
         max_t1, max_t2, max_t6;  % 7: 右上前
         min_t1, max_t2, max_t6]; % 8: 左上前
         
    % 面的连接顺序 (F)
    F = [1 2 3 4;   % 底面
         5 6 7 8;   % 顶面
         1 2 6 5;   % 前面
         2 3 7 6;   % 右面
         3 4 8 7;   % 后面
         4 1 5 8];  % 左面

    % --- 4. 绘制半透明的边界曲面 (Patch 渲染) ---
    my_color = [140, 190, 178] ./ 255;      % 采用我们标志性的变胞手主题色
    edge_color = [0.0039, 0.1255, 0.1882];  % 勾勒深色轮廓线增强立体感
    
    patch('Vertices', V, 'Faces', F, ...
          'FaceColor', my_color, ...
          'FaceAlpha', 0.3, ...      % 30%透明度，营造"玻璃盒"质感
          'EdgeColor', edge_color, ...
          'LineWidth', 2.5);

    % =================================================================
    % --- 5. 坐标系标签与排版 (LaTeX 符号支持) ---
    % =================================================================
    % 关节空间各轴的物理跨度不同，但为了视觉美观，我们强制外框为正方体比例
    pbaspect([1 1 1]); 
    
    xlabel('$\theta_{p1}\ (^\circ)$', 'Interpreter', 'latex', 'FontSize', 40);
    ylabel('$\theta_{p2}\ (^\circ)$', 'Interpreter', 'latex', 'FontSize', 40);
    zlabel('$\theta_{p6}\ (^\circ)$', 'Interpreter', 'latex', 'FontSize', 40);
    
    % --- 让轴标签呈现高级的倾斜透视效果 ---
    hx = get(gca, 'XLabel'); 
    hy = get(gca, 'YLabel');
    hx.Rotation = -15; 
    hy.Rotation = 35;
    
    % --- 为了防止坐标轴刻度过于密集，自适应提取漂亮的刻度间隔 ---
    % （这里不再强制 50 步长，因为 T1, T2, T6 的范围差异悬殊：25° vs 276° vs 135°）
    set(gca, 'XLim', [min_t1, max_t1]);
    set(gca, 'YLim', [min_t2, max_t2]);
    set(gca, 'ZLim', [min_t6, max_t6]);
    
    % 使用原生底层 LaTeX 渲染格式，保证负号和数字绝对居中对齐
    xticklabels(arrayfun(@(x) sprintf('$%g$', x), xticks, 'UniformOutput', false));
    yticklabels(arrayfun(@(y) sprintf('$%g$', y), yticks, 'UniformOutput', false));
    zticklabels(arrayfun(@(z) sprintf('$%g$', z), zticks, 'UniformOutput', false));

    hold off;
    drawnow;
    
end