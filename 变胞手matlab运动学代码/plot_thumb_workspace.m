function WS_thumb = plot_thumb_workspace(g_tip_base)
% PLOT_THUMB_WORKSPACE 绘制拇指在指根局部坐标系下的工作空间热力图
% 包含：1. 坐标旋转置换 (x->-z, y->-x, z->y)
%       2. 动态三维正方体绝对包络盒
%       3. 带有距离渐变色的三面正交投影墙
    % --- 1. 提取拇指原始数据 (索引 1) ---
    X_orig = squeeze(g_tip_base{1}(1, 4, :));
    Y_orig = squeeze(g_tip_base{1}(2, 4, :));
    Z_orig = squeeze(g_tip_base{1}(3, 4, :));

    WS_thumb = struct('Finger', 'Thumb', 'X', X_orig, 'Y', Y_orig, 'Z', Z_orig);

    % --- 2. 执行坐标系旋转置换 ---
    X_plot = -Z_orig;
    Y_plot = -X_orig;
    Z_plot = Y_orig;
    % 计算每个点到原点的距离 (用于热力图)
    Distances = sqrt(X_plot.^2 + Y_plot.^2 + Z_plot.^2);
    % --- 3. 初始化高规格图窗 ---
    figure('Name', 'Thumb Local Workspace', 'Color', 'w');
    hold on; grid on;
    set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 40, 'Color', [0.98, 0.98, 0.98], ...
        'LineWidth', 4, 'GridLineWidth', 4, 'GridAlpha', 0.25);
    view(3);

    % --- 4. 配置高级渐变色标 ---
    color_nodes = [
        0.0039,  0.1255,  0.1882;
        0.0745,  0.4039,  0.5412;
        0.2706,  0.7686,  0.6902;
        0.6039,  0.9216,  0.6392;
        0.8549,  0.9922,  0.7294
        ];
    custom_cmap = interp1(linspace(0, 1, size(color_nodes, 1)), color_nodes, linspace(0, 1, 256));
    colormap(custom_cmap);
    % --- 5. 核心包围盒计算：强制绝对正方体 ---
    span_x = max(X_plot) - min(X_plot);
    span_y = max(Y_plot) - min(Y_plot);
    span_z = max(Z_plot) - min(Z_plot);
    max_span = max([span_x, span_y, span_z]);

    center_x = (max(X_plot) + min(X_plot)) / 2;
    center_y = (max(Y_plot) + min(Y_plot)) / 2;
    center_z = (max(Z_plot) + min(Z_plot)) / 2;

    half_span = (max_span * 1.8) / 2; % 留出30%的呼吸感

    % 锁定投影墙位置 (贴合包围盒的背面和底面)
    z_floor = center_z - half_span;
    x_wall  = center_x + half_span;
    y_wall  = center_y + half_span;
    % --- 6. 绘制主体点云热力图 ---
    scatter3(X_plot, Y_plot, Z_plot, 200, Distances, 'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeColor', 'none');

    % =================================================================
    % --- 7. 核心恢复：绘制带有热力图映射的三面投影墙 ---
    % =================================================================
    edge_color = [0.0039, 0.1255, 0.1882]; % 深色边界线
    line_w = 2.0;
    offset = half_span * 0.005;
    grid_pts = 200;
    alpha_shrink = 1.6;
    area_scale = (half_span * 2)^2;
    hole_thresh = area_scale * 0.015;
    region_thresh = area_scale * 0.005;
    X_col = X_plot(:); Y_col = Y_plot(:); Z_col = Z_plot(:); Dist_col = Distances(:);
    % (1) XY 平面投影 (底面)
    shp_xy = alphaShape(X_col, Y_col); shp_xy.Alpha = shp_xy.Alpha * alpha_shrink;
    shp_xy.HoleThreshold = hole_thresh; shp_xy.RegionThreshold = region_thresh;
    [Xg_xy, Yg_xy] = meshgrid(linspace(min(X_col), max(X_col), grid_pts), linspace(min(Y_col), max(Y_col), grid_pts));
    F_xy = scatteredInterpolant(X_col, Y_col, Dist_col, 'linear', 'none');
    Cg_xy = F_xy(Xg_xy, Yg_xy); in_xy = inShape(shp_xy, Xg_xy, Yg_xy); Cg_xy(~in_xy) = NaN;
    surf(Xg_xy, Yg_xy, repmat(z_floor, size(Xg_xy)), Cg_xy, 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'FaceColor', 'interp');
    [bf_xy, P_xy] = boundaryFacets(shp_xy);
    edgeX_xy = [P_xy(bf_xy(:,1), 1)'; P_xy(bf_xy(:,2), 1)'; NaN(1, size(bf_xy,1))];
    edgeY_xy = [P_xy(bf_xy(:,1), 2)'; P_xy(bf_xy(:,2), 2)'; NaN(1, size(bf_xy,1))];
    plot3(edgeX_xy(:), edgeY_xy(:), repmat(z_floor + offset, numel(edgeX_xy), 1), '-', 'Color', edge_color, 'LineWidth', line_w, 'LineJoin', 'round');
    % (2) YZ 平面投影 (右侧墙)
    shp_yz = alphaShape(Y_col, Z_col); shp_yz.Alpha = shp_yz.Alpha * alpha_shrink;
    shp_yz.HoleThreshold = hole_thresh; shp_yz.RegionThreshold = region_thresh;
    [Yg_yz, Zg_yz] = meshgrid(linspace(min(Y_col), max(Y_col), grid_pts), linspace(min(Z_col), max(Z_col), grid_pts));
    F_yz = scatteredInterpolant(Y_col, Z_col, Dist_col, 'linear', 'none');
    Cg_yz = F_yz(Yg_yz, Zg_yz); in_yz = inShape(shp_yz, Yg_yz, Zg_yz); Cg_yz(~in_yz) = NaN;
    surf(repmat(x_wall, size(Yg_yz)), Yg_yz, Zg_yz, Cg_yz, 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'FaceColor', 'interp');
    [bf_yz, P_yz] = boundaryFacets(shp_yz);
    edgeY_yz = [P_yz(bf_yz(:,1), 1)'; P_yz(bf_yz(:,2), 1)'; NaN(1, size(bf_yz,1))];
    edgeZ_yz = [P_yz(bf_yz(:,1), 2)'; P_yz(bf_yz(:,2), 2)'; NaN(1, size(bf_yz,1))];
    plot3(repmat(x_wall - offset, numel(edgeY_yz), 1), edgeY_yz(:), edgeZ_yz(:), '-', 'Color', edge_color, 'LineWidth', line_w, 'LineJoin', 'round');
    % (3) XZ 平面投影 (左侧墙)
    shp_xz = alphaShape(X_col, Z_col); shp_xz.Alpha = shp_xz.Alpha * alpha_shrink;
    shp_xz.HoleThreshold = hole_thresh; shp_xz.RegionThreshold = region_thresh;
    [Xg_xz, Zg_xz] = meshgrid(linspace(min(X_col), max(X_col), grid_pts), linspace(min(Z_col), max(Z_col), grid_pts));
    F_xz = scatteredInterpolant(X_col, Z_col, Dist_col, 'linear', 'none');
    Cg_xz = F_xz(Xg_xz, Zg_xz); in_xz = inShape(shp_xz, Xg_xz, Zg_xz); Cg_xz(~in_xz) = NaN;
    surf(Xg_xz, repmat(y_wall, size(Xg_xz)), Zg_xz, Cg_xz, 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'FaceColor', 'interp');
    [bf_xz, P_xz] = boundaryFacets(shp_xz);
    edgeX_xz = [P_xz(bf_xz(:,1), 1)'; P_xz(bf_xz(:,2), 1)'; NaN(1, size(bf_xz,1))];
    edgeZ_xz = [P_xz(bf_xz(:,1), 2)'; P_xz(bf_xz(:,2), 2)'; NaN(1, size(bf_xz,1))];
    plot3(edgeX_xz(:), repmat(y_wall - offset, numel(edgeX_xz), 1), edgeZ_xz(:), '-', 'Color', edge_color, 'LineWidth', line_w, 'LineJoin', 'round');
    % --- 8. Colorbar 配置 ---
    cb = colorbar;
    cb.LineWidth = 2; cb.TickLabelInterpreter = 'latex'; cb.FontSize = 40; 
    cb.Position = [0.75, 0.15, 0.015, 0.7];
    % --- 9. 施加边界、标签与排版 ---
    xlim([center_x - half_span, center_x + half_span]);
    ylim([center_y - half_span, center_y + half_span]);
    zlim([center_z - half_span, center_z + half_span]);

    % =================================================================
    % 新增：仅将三轴分度值统一为 50，不干涉其他任何逻辑
    % =================================================================
    tick_step = 100; 
    uniform_ticks = -1000 : tick_step : 1000;
    xticks(uniform_ticks);
    yticks(uniform_ticks);
    zticks(uniform_ticks);

    xlabel('$z_{t\mathrm{0}}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
    ylabel('$x_{t\mathrm{0}}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
    zlabel('$y_{t\mathrm{0}}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);

    daspect([1 1 1]);
    pbaspect([1 1 1]);

    % 修正刻度正负号 (必须在设置 lim 和 surf 绘制之后执行)
    current_xticks = xticks; xticklabels(string(-current_xticks));
    current_yticks = yticks; yticklabels(string(-current_yticks));

    hx = get(gca, 'XLabel'); hy = get(gca, 'YLabel');
    hx.Rotation = 25; hy.Rotation = -35;

    hold off;
    drawnow;

end
