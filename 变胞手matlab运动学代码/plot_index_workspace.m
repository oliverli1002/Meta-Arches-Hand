function WS_index = plot_index_workspace(g_tip_base)
% PLOT_INDEX_WORKSPACE 绘制食指在指根局部坐标系下的工作空间热力图
% 纯二维绘图：直接绘制 YOZ 平面，横轴为 Z，纵轴为 Y，颜色映射空间距离

    % --- 1. 提取食指数据 (索引 2) ---
    X_local = squeeze(g_tip_base{2}(1, 4, :));
    Y_local = squeeze(g_tip_base{2}(2, 4, :));
    Z_local = squeeze(g_tip_base{2}(3, 4, :));
    
    % 结构体中依然保存完整的三维数据，保证数据输出的完整性
    WS_index = struct('Finger', 'Index', 'X', X_local, 'Y', Y_local, 'Z', Z_local);

    % =================================================================
    % --- 新增：计算每个点到原点的真实空间距离 (用于热力图) ---
    % =================================================================
    Distances = sqrt(X_local.^2 + Y_local.^2 + Z_local.^2);

    % --- 2. 初始化图窗 ---
    figure('Name', 'Index Local Workspace', 'Color', 'w');
    hold on; grid on;
    set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 30, 'Color', [0.98, 0.98, 0.98], ...
        'LineWidth', 4, 'GridLineWidth', 4, 'GridAlpha', 0.25);
        
    % =================================================================
    % --- 新增：配置与综合图完全一致的高级渐变色标 ---
    % =================================================================
    color_nodes = [
        0.0039,  0.1255,  0.1882;
        0.0745,  0.4039,  0.5412;
        0.2706,  0.7686,  0.6902;
        0.6039,  0.9216,  0.6392;
        0.8549,  0.9922,  0.7294
        ];
    custom_cmap = interp1(linspace(0, 1, size(color_nodes, 1)), color_nodes, linspace(0, 1, 256));
    colormap(custom_cmap);

    % --- 3. 绘制 2D 点云热力图 ---
    % 将之前的纯色 my_color 替换为 Distances
    scatter(Z_local, Y_local, 200, Distances, 'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeColor', 'none');
        
    % =================================================================
    % --- 新增：添加 Colorbar 颜色条 ---
    % =================================================================
    cb = colorbar;
    cb.LineWidth = 1.5; 
    cb.TickLabelInterpreter = 'latex'; 
    cb.FontSize = 30; 
    
    % --- 4. 核心优化：强制正方形画框与等比例数据边界 ---
    % 计算数据在两个方向上的实际跨度
    span_z = max(Z_local) - min(Z_local);
    span_y = max(Y_local) - min(Y_local);
    
    % 取两者中最大的跨度，作为正方形画框的基准边长
    max_span = max(span_z, span_y);
    
    % 计算数据的几何中心
    center_z = (max(Z_local) + min(Z_local)) / 2;
    center_y = (max(Y_local) + min(Y_local)) / 2;
    
    % 在基准边长的基础上增加 15% 的呼吸感，计算最终单侧跨度
    half_span = (max_span * 1.15) / 2; 
    
    % 手动设置完全等长的坐标轴边界，保证数据居中且边框为绝对正方形
    xlim([center_z - half_span, center_z + half_span]);
    ylim([center_y - half_span, center_y + half_span]);
    
    % --- 5. 标签与排版 ---
    xlabel('$z_{i\mathrm{0}}$ (mm)', 'Interpreter', 'latex', 'FontSize', 35);
    ylabel('$y_{i\mathrm{0}}$ (mm)', 'Interpreter', 'latex', 'FontSize', 35);
    
    % 锁定等比例 1:1 视觉，并且强制图框为正方形
    daspect([1 1 1]);
    pbaspect([1 1 1]);
    
    % 确保视角为纯二维平面
    view(2);
    
    hold off;
    drawnow;
    
end