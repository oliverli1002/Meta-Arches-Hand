function WS = plot_hand_workspace_inipalm(H_t_num, num_samples)
% PLOT_HAND_WORKSPACE_INIPALM 绘制手掌处于初始位置时的五指指尖综合工作空间
% 视觉升级版：拇指保留玻璃质感阴影面，其余四指以半透明点云打在墙上
% 包含：150等距网格、修复LaTeX倾斜Bug、拉开视觉主次

if nargin < 2
    num_samples = 50000;
end
finger_names = {'Thumb', 'Index', 'Middle', 'Ring', 'Little'};
WS = cell(1, 5);

% 用于收集五指的汇总数据
X_combined = [];
Y_combined = [];
Z_combined = [];
Distances_combined = [];
global_min = inf;
global_max = -inf;

% 自定义统一的高级渐变色标
color_nodes = [
    0.0039,  0.1255,  0.1882; 
    0.0745,  0.4039,  0.5412;
    0.2706,  0.7686,  0.6902;
    0.6039,  0.9216,  0.6392;
    0.8549,  0.9922,  0.7294  
    ];
custom_cmap = interp1(linspace(0, 1, size(color_nodes, 1)), color_nodes, linspace(0, 1, 256));

% ================= 第一步：纯数据预处理，计算全局统一的坐标极限 =================
fprintf('--- 正在预处理数据并计算全局坐标包围盒 (初始位置) ---\n');
for i = 1:5
    X_orig = reshape(H_t_num{i}(1, 4, :, :), 1, []);
    Y_orig = reshape(H_t_num{i}(2, 4, :, :), 1, []);
    Z_orig = reshape(H_t_num{i}(3, 4, :, :), 1, []);
    
    % 坐标空间旋转置换 (x->y, y->-z, z->-x)
    X_full = Y_orig; 
    Y_full = -Z_orig; 
    Z_full = -X_orig;
    
    total_points = length(X_full);
    if total_points > num_samples
        idx = randperm(total_points, num_samples);
        X = X_full(idx); Y = Y_full(idx); Z = Z_full(idx);
        fprintf('Finger %d (%s): Downsampled to %d points.\n', i, finger_names{i}, num_samples);
    else
        X = X_full; Y = Y_full; Z = Z_full;
        fprintf('Finger %d (%s): Total points %d.\n', i, finger_names{i}, total_points);
    end
    
    Distances = sqrt(X.^2 + Y.^2 + Z.^2);
    WS{i} = struct('X', X, 'Y', Y, 'Z', Z, 'Distances', Distances);
    
    X_combined = [X_combined, X];
    Y_combined = [Y_combined, Y];
    Z_combined = [Z_combined, Z];
    Distances_combined = [Distances_combined, Distances];
    
    global_min = min([global_min, min(X), min(Y), min(Z)]);
    global_max = max([global_max, max(X), max(Y), max(Z)]);
end

% 确立整个体系的"绝对尺寸"
global_axis_span = global_max - global_min;
global_margin = global_axis_span * 0.3; % 统一的 30% 边距
global_uniform_lim = [global_min - global_margin, global_max + global_margin];

% 锁定绝对投影墙面的位置
z_floor = global_uniform_lim(1);
x_wall  = global_uniform_lim(2);
y_wall  = global_uniform_lim(2);

edge_color = [0.0039,  0.1255,  0.1882];
line_w = 2.0;
offset = global_axis_span * 0.005;
grid_pts = 200;
alpha_shrink = 1.6;

% ================= 第二步：图窗初始化与排版 =================
figure('Name', 'Initial Workspace of All Fingers', 'Color', 'w');
hold on; grid on;

% 100% 同步 foldpalm 的坐标轴格式
set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 40, 'Color', [0.98, 0.98, 0.98], ...
    'LineWidth', 3, 'GridLineWidth', 2, 'GridAlpha', 0.25);
view(-37.5, 20);

area_scale = global_axis_span^2;
hole_thresh = area_scale * 0.015;
region_thresh = area_scale * 0.005;

% ================= 第三步：绘制主体 3D 点云与三面投影 =================
% 1. 绘制主体点云 (所有5根手指的主体保持 3D 热力图显示)
scatter3(X_combined, Y_combined, Z_combined, 100, Distances_combined, 'filled', 'MarkerFaceAlpha', 1, 'MarkerEdgeColor', 'none');

% ---------------------------------------------------------------------
% 2. 绘制拇指 (Thumb, i=1) 的高级阴影面投影 (面积 surf)
% ---------------------------------------------------------------------
X_t = WS{1}.X'; Y_t = WS{1}.Y'; Z_t = WS{1}.Z'; Dist_t = WS{1}.Distances';

% XY 平面投影 (Thumb)
shp_xy = alphaShape(X_t, Y_t); shp_xy.Alpha = shp_xy.Alpha * alpha_shrink;
shp_xy.HoleThreshold = hole_thresh; shp_xy.RegionThreshold = region_thresh;
[Xg_xy, Yg_xy] = meshgrid(linspace(min(X_t), max(X_t), grid_pts), linspace(min(Y_t), max(Y_t), grid_pts));
F_xy = scatteredInterpolant(X_t, Y_t, Dist_t, 'linear', 'none');
Cg_xy = F_xy(Xg_xy, Yg_xy); in_xy = inShape(shp_xy, Xg_xy, Yg_xy); Cg_xy(~in_xy) = NaN;
surf(Xg_xy, Yg_xy, repmat(z_floor, size(Xg_xy)), Cg_xy, 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'FaceColor', 'interp');
[bf_xy, P_xy] = boundaryFacets(shp_xy);
eX_xy = [P_xy(bf_xy(:,1), 1)'; P_xy(bf_xy(:,2), 1)'; NaN(1, size(bf_xy,1))];
eY_xy = [P_xy(bf_xy(:,1), 2)'; P_xy(bf_xy(:,2), 2)'; NaN(1, size(bf_xy,1))];
plot3(eX_xy(:), eY_xy(:), repmat(z_floor + offset, numel(eX_xy), 1), '-', 'Color', edge_color, 'LineWidth', line_w, 'LineJoin', 'round');

% YZ 平面投影 (Thumb)
shp_yz = alphaShape(Y_t, Z_t); shp_yz.Alpha = shp_yz.Alpha * alpha_shrink;
shp_yz.HoleThreshold = hole_thresh; shp_yz.RegionThreshold = region_thresh;
[Yg_yz, Zg_yz] = meshgrid(linspace(min(Y_t), max(Y_t), grid_pts), linspace(min(Z_t), max(Z_t), grid_pts));
F_yz = scatteredInterpolant(Y_t, Z_t, Dist_t, 'linear', 'none');
Cg_yz = F_yz(Yg_yz, Zg_yz); in_yz = inShape(shp_yz, Yg_yz, Zg_yz); Cg_yz(~in_yz) = NaN;
surf(repmat(x_wall, size(Yg_yz)), Yg_yz, Zg_yz, Cg_yz, 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'FaceColor', 'interp');
[bf_yz, P_yz] = boundaryFacets(shp_yz);
eY_yz = [P_yz(bf_yz(:,1), 1)'; P_yz(bf_yz(:,2), 1)'; NaN(1, size(bf_yz,1))];
eZ_yz = [P_yz(bf_yz(:,1), 2)'; P_yz(bf_yz(:,2), 2)'; NaN(1, size(bf_yz,1))];
plot3(repmat(x_wall - offset, numel(eY_yz), 1), eY_yz(:), eZ_yz(:), '-', 'Color', edge_color, 'LineWidth', line_w, 'LineJoin', 'round');

% XZ 平面投影 (Thumb)
shp_xz = alphaShape(X_t, Z_t); shp_xz.Alpha = shp_xz.Alpha * alpha_shrink;
shp_xz.HoleThreshold = hole_thresh; shp_xz.RegionThreshold = region_thresh;
[Xg_xz, Zg_xz] = meshgrid(linspace(min(X_t), max(X_t), grid_pts), linspace(min(Z_t), max(Z_t), grid_pts));
F_xz = scatteredInterpolant(X_t, Z_t, Dist_t, 'linear', 'none');
Cg_xz = F_xz(Xg_xz, Zg_xz); in_xz = inShape(shp_xz, Xg_xz, Zg_xz); Cg_xz(~in_xz) = NaN;
surf(Xg_xz, repmat(y_wall, size(Xg_xz)), Zg_xz, Cg_xz, 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'FaceColor', 'interp');
[bf_xz, P_xz] = boundaryFacets(shp_xz);
eX_xz = [P_xz(bf_xz(:,1), 1)'; P_xz(bf_xz(:,2), 1)'; NaN(1, size(bf_xz,1))];
eZ_xz = [P_xz(bf_xz(:,1), 2)'; P_xz(bf_xz(:,2), 2)'; NaN(1, size(bf_xz,1))];
plot3(eX_xz(:), repmat(y_wall - offset, numel(eX_xz), 1), eZ_xz(:), '-', 'Color', edge_color, 'LineWidth', line_w, 'LineJoin', 'round');

% ---------------------------------------------------------------------
% 3. 绘制其余四指 (Index, Middle, Ring, Little) 的点云投影 (scatter3)
% ---------------------------------------------------------------------
for i = 2:5
    X_f = WS{i}.X; 
    Y_f = WS{i}.Y; 
    Z_f = WS{i}.Z; 
    Dist_f = WS{i}.Distances;
    
    % XY 平面投影 (底面)
    scatter3(X_f, Y_f, repmat(z_floor + offset, 1, length(Z_f)), 60, Dist_f, 'filled', ...
        'MarkerFaceAlpha', 0.15, 'MarkerEdgeColor', 'none');
    
    % YZ 平面投影 (右侧墙)
    scatter3(repmat(x_wall - offset, 1, length(X_f)), Y_f, Z_f, 60, Dist_f, 'filled', ...
        'MarkerFaceAlpha', 0.15, 'MarkerEdgeColor', 'none');
    
    % XZ 平面投影 (左侧墙)
    scatter3(X_f, repmat(y_wall - offset, 1, length(Y_f)), Z_f, 60, Dist_f, 'filled', ...
        'MarkerFaceAlpha', 0.15, 'MarkerEdgeColor', 'none');
end

% ================= 第四步：Colorbar 及排版收尾 =================
colormap(custom_cmap);
cb_combined = colorbar;
cb_combined.LineWidth = 2; 
cb_combined.TickLabelInterpreter = 'latex'; 
cb_combined.FontSize = 40;
cb_combined.Position = [0.75, 0.15, 0.015, 0.7];

hx = xlabel('$y_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
hy = ylabel('$z_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
hz = zlabel('$x_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
drawnow;

hx.Rotation = 15; 
hy.Rotation = -25;

daspect([1 1 1]); 
pbaspect([1 1 1]);
xlim(global_uniform_lim); 
ylim(global_uniform_lim); 
zlim(global_uniform_lim);

% =================================================================
% 强制三轴步长一致为 150，并使用 arrayfun 彻底修复 LaTeX 倾斜 Bug
% =================================================================
tick_step = 150; 
uniform_ticks = -1000 : tick_step : 1000;
xticks(uniform_ticks);
yticks(uniform_ticks);
zticks(uniform_ticks);

% X轴保持正负号不变
current_xticks_comb = xticks;
xticklabels(arrayfun(@(x) sprintf('$%d$', x), current_xticks_comb, 'UniformOutput', false));

% Y轴和Z轴根据坐标置换逻辑加上负号修正
current_yticks_comb = yticks;
yticklabels(arrayfun(@(x) sprintf('$%d$', -x), current_yticks_comb, 'UniformOutput', false));

current_zticks_comb = zticks;
zticklabels(arrayfun(@(x) sprintf('$%d$', -x), current_zticks_comb, 'UniformOutput', false));

hold off;
drawnow;
fprintf('Figure: Initial workspace with matched formatting generated successfully.\n');
end