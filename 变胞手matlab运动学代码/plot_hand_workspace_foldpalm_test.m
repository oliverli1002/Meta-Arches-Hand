function WS = plot_hand_workspace_foldpalm_test(H_t_num, num_samples)
% PLOT_HAND_WORKSPACE_FOLDPALM_TEST 绘制后翻工作空间，并叠加 STL 变胞手模型。
% 全面升级：前5张独立图与第6张综合图格式 100% 绝对统一（投影、线宽、排版、全局统一包围盒）

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
    0.0039,  0.1255,  0.1882; % 对应最短距离
    0.0745,  0.4039,  0.5412;
    0.2706,  0.7686,  0.6902;
    0.6039,  0.9216,  0.6392;
    0.8549,  0.9922,  0.7294  % 对应最远距离
    ];
custom_cmap = interp1(linspace(0, 1, size(color_nodes, 1)), color_nodes, linspace(0, 1, 256));

% ================= 第一步：纯数据预处理，计算全局统一的坐标极限 =================
fprintf('--- 正在预处理数据并计算全局坐标包围盒 ---\n');
for i = 1:5
    X_orig = reshape(H_t_num{i}(1, 4, :, :), 1, []);
    Y_orig = reshape(H_t_num{i}(2, 4, :, :), 1, []);
    Z_orig = reshape(H_t_num{i}(3, 4, :, :), 1, []);

    %对坐标进行轮换原始 x -> 绘图 Z 的负方向；原始 y -> 绘图 X；原始 z -> 绘图 Y 的负方向
    X_full = Y_orig; Y_full = -Z_orig; Z_full = -X_orig;

    global_min = min([global_min, min(X_full), min(Y_full), min(Z_full)]);
    global_max = max([global_max, max(X_full), max(Y_full), max(Z_full)]);

    total_points = length(X_full);
    if total_points > num_samples
        idx = select_workspace_sample_indices(X_full, Y_full, Z_full, size(H_t_num{i}, 3), size(H_t_num{i}, 4), num_samples);
        X = X_full(idx); Y = Y_full(idx); Z = Z_full(idx);
        fprintf('Finger %d (%s): Boundary-preserving downsampled to %d points.\n', i, finger_names{i}, length(idx));
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
end

% 确立整个体系的"绝对尺寸"，保证 6 张图的坐标盒一模一样大
global_axis_span = global_max - global_min;
global_margin = global_axis_span * 0.3;
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

% % ================= 第二步：绘制 1~5 张图（完美继承 Figure 6 格式） =================
% for i = 1:5
%     figure('Name', sprintf('%s Finger Workspace', finger_names{i}), 'Color', 'w');
%     hold on; grid on;
% 
%     % 100% 对齐 Figure 6 的坐标轴格式
%     set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 40, 'Color', [0.98, 0.98, 0.98], ...
%         'LineWidth', 2,'GridLineWidth', 2,'GridAlpha', 0.25);
%     view(-37.5, 20);
% 
%     X = WS{i}.X; Y = WS{i}.Y; Z = WS{i}.Z; Distances = WS{i}.Distances;
% 
%     % 计算单个手指的噪点阈值（防止单指面积太小被全局阈值误删）
%     local_axis_span = max([max(X)-min(X), max(Y)-min(Y), max(Z)-min(Z)]);
%     local_area_scale = local_axis_span^2;
%     hole_thresh = local_area_scale * 0.015;
%     region_thresh = local_area_scale * 0.005;
% 
%     % --- 绘制主体点云 ---
%     scatter3(X, Y, Z, 100, Distances, 'filled', 'MarkerFaceAlpha', 1, 'MarkerEdgeColor', 'none');
% 
%     % --- XY 平面投影 ---
%     shp_xy = alphaShape(X', Y'); shp_xy.Alpha = shp_xy.Alpha * alpha_shrink;
%     shp_xy.HoleThreshold = hole_thresh; shp_xy.RegionThreshold = region_thresh;
%     [Xg_xy, Yg_xy] = meshgrid(linspace(min(X), max(X), grid_pts), linspace(min(Y), max(Y), grid_pts));
%     F_xy = scatteredInterpolant(X', Y', Distances', 'linear', 'none');
%     Cg_xy = F_xy(Xg_xy, Yg_xy); in_xy = inShape(shp_xy, Xg_xy, Yg_xy); Cg_xy(~in_xy) = NaN;
%     surf(Xg_xy, Yg_xy, repmat(z_floor, size(Xg_xy)), Cg_xy, 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'FaceColor', 'interp');
%     [bf_xy, P_xy] = boundaryFacets(shp_xy);
%     edgeX_xy = [P_xy(bf_xy(:,1), 1)'; P_xy(bf_xy(:,2), 1)'; NaN(1, size(bf_xy,1))];
%     edgeY_xy = [P_xy(bf_xy(:,1), 2)'; P_xy(bf_xy(:,2), 2)'; NaN(1, size(bf_xy,1))];
%     plot3(edgeX_xy(:), edgeY_xy(:), repmat(z_floor + offset, numel(edgeX_xy), 1), '-', 'Color', edge_color, 'LineWidth', line_w, 'LineJoin', 'round');
% 
%     % --- YZ 平面投影 ---
%     shp_yz = alphaShape(Y', Z'); shp_yz.Alpha = shp_yz.Alpha * alpha_shrink;
%     shp_yz.HoleThreshold = hole_thresh; shp_yz.RegionThreshold = region_thresh;
%     [Yg_yz, Zg_yz] = meshgrid(linspace(min(Y), max(Y), grid_pts), linspace(min(Z), max(Z), grid_pts));
%     F_yz = scatteredInterpolant(Y', Z', Distances', 'linear', 'none');
%     Cg_yz = F_yz(Yg_yz, Zg_yz); in_yz = inShape(shp_yz, Yg_yz, Zg_yz); Cg_yz(~in_yz) = NaN;
%     surf(repmat(x_wall, size(Yg_yz)), Yg_yz, Zg_yz, Cg_yz, 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'FaceColor', 'interp');
%     [bf_yz, P_yz] = boundaryFacets(shp_yz);
%     edgeY_yz = [P_yz(bf_yz(:,1), 1)'; P_yz(bf_yz(:,2), 1)'; NaN(1, size(bf_yz,1))];
%     edgeZ_yz = [P_yz(bf_yz(:,1), 2)'; P_yz(bf_yz(:,2), 2)'; NaN(1, size(bf_yz,1))];
%     plot3(repmat(x_wall - offset, numel(edgeY_yz), 1), edgeY_yz(:), edgeZ_yz(:), '-', 'Color', edge_color, 'LineWidth', line_w, 'LineJoin', 'round');
% 
%     % --- XZ 平面投影 ---
%     shp_xz = alphaShape(X', Z'); shp_xz.Alpha = shp_xz.Alpha * alpha_shrink;
%     shp_xz.HoleThreshold = hole_thresh; shp_xz.RegionThreshold = region_thresh;
%     [Xg_xz, Zg_xz] = meshgrid(linspace(min(X), max(X), grid_pts), linspace(min(Z), max(Z), grid_pts));
%     F_xz = scatteredInterpolant(X', Z', Distances', 'linear', 'none');
%     Cg_xz = F_xz(Xg_xz, Zg_xz); in_xz = inShape(shp_xz, Xg_xz, Zg_xz); Cg_xz(~in_xz) = NaN;
%     surf(Xg_xz, repmat(y_wall, size(Xg_xz)), Zg_xz, Cg_xz, 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'FaceColor', 'interp');
%     [bf_xz, P_xz] = boundaryFacets(shp_xz);
%     edgeX_xz = [P_xz(bf_xz(:,1), 1)'; P_xz(bf_xz(:,2), 1)'; NaN(1, size(bf_xz,1))];
%     edgeZ_xz = [P_xz(bf_xz(:,1), 2)'; P_xz(bf_xz(:,2), 2)'; NaN(1, size(bf_xz,1))];
%     plot3(edgeX_xz(:), repmat(y_wall - offset, numel(edgeX_xz), 1), edgeZ_xz(:), '-', 'Color', edge_color, 'LineWidth', line_w, 'LineJoin', 'round');
% 
%     % --- 配置 Colorbar 及排版 (与图6一模一样) ---
%     colormap(custom_cmap);
%     cb = colorbar;
%     cb.LineWidth = 2; cb.TickLabelInterpreter = 'latex'; cb.FontSize = 40;
%     cb.Position = [0.75, 0.15, 0.015, 0.7];
% 
%     hx = xlabel('$y_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
%     hy = ylabel('$z_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
%     hz = zlabel('$x_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
%     drawnow;
% 
%     hx.Rotation = 25; hy.Rotation = -35;
% 
%     daspect([1 1 1]); pbaspect([1 1 1]);
%     xlim(global_uniform_lim); ylim(global_uniform_lim); zlim(global_uniform_lim);
%     zticklabels(string(-zticks)); yticklabels(string(-yticks));
% 
%     % =================================================================
%     % [新增] 强制三轴步长绝对一致为 50，并修复 LaTeX 倾斜 Bug (图1-5)
%     % =================================================================
%     tick_step = 100;
%     uniform_ticks = -1000 : tick_step : 1000;
%     xticks(uniform_ticks);
%     yticks(uniform_ticks);
%     zticks(uniform_ticks);
% 
%     hold off; drawnow;
% end

% ================= 第三步：绘制第 6 张图（综合工作空间与三视图投影） =================
max_combined_points = 1000000;
total_combined = length(X_combined);
if total_combined > max_combined_points
    idx_comb = select_geometry_preserving_indices(X_combined, Y_combined, Z_combined, max_combined_points);
    X_combined = X_combined(idx_comb); Y_combined = Y_combined(idx_comb);
    Z_combined = Z_combined(idx_comb); Distances_combined = Distances_combined(idx_comb);
    fprintf('Figure 6: Boundary-preserving downsampled from %d to %d.\n', total_combined, length(idx_comb));
end

figure('Name', 'Combined Workspace of All Fingers', 'Color', 'w');
hold on; grid on;
set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 40, 'Color', [0.98, 0.98, 0.98], ...
    'LineWidth', 3,'GridLineWidth', 2,'GridAlpha', 0.25);

view(-37.5, 20);

model_file = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
    '变胞手绘图用sw图', 'metamorphic hand 2.0', 'Hand with 5 Fingers', 'MetaHand-Backfolding max.STL');
model_options = struct();
model_options.ApplyCoordinateMapping = true;      % true 时执行下方 map_original_to_plot_coordinates 坐标转换
model_options.Scale = 1;                         % STL 坐标缩放比例
model_options.RotationDeg = [0, 0, 0];           % 坐标轮换后绕绘图 X/Y/Z 轴旋转 [rx, ry, rz]，单位：deg
model_options.FaceColor = [0.72, 0.72, 0.68];    % 模型颜色
model_options.FaceAlpha = 1;                  % 模型透明度
model_options.EdgeAlpha = 0.01;                  % 模型网格线透明度
model_options.ReduceRatio = 0.1;                % STL 面片简化比例；调大更精细但更卡
add_stl_model_to_workspace(gca, model_file, model_options);

area_scale = global_axis_span^2;
hole_thresh = area_scale * 0.015;
region_thresh = area_scale * 0.005;

% 1. 绘制主体点云
scatter3(X_combined, Y_combined, Z_combined, 100, Distances_combined, 'filled', 'MarkerFaceAlpha', 1, 'MarkerEdgeColor', 'none');

% 2. 绘制三面投影
% XY平面
shp_xy = alphaShape(X_combined', Y_combined'); shp_xy.Alpha = shp_xy.Alpha * alpha_shrink;
shp_xy.HoleThreshold = hole_thresh; shp_xy.RegionThreshold = region_thresh;
[Xg_xy, Yg_xy] = meshgrid(linspace(min(X_combined), max(X_combined), grid_pts), linspace(min(Y_combined), max(Y_combined), grid_pts));
F_xy = scatteredInterpolant(X_combined', Y_combined', Distances_combined', 'linear', 'none');
Cg_xy = F_xy(Xg_xy, Yg_xy); in_xy = inShape(shp_xy, Xg_xy, Yg_xy); Cg_xy(~in_xy) = NaN;
surf(Xg_xy, Yg_xy, repmat(z_floor, size(Xg_xy)), Cg_xy, 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'FaceColor', 'interp');
[bf_xy, P_xy] = boundaryFacets(shp_xy);
edgeX_xy = [P_xy(bf_xy(:,1), 1)'; P_xy(bf_xy(:,2), 1)'; NaN(1, size(bf_xy,1))];
edgeY_xy = [P_xy(bf_xy(:,1), 2)'; P_xy(bf_xy(:,2), 2)'; NaN(1, size(bf_xy,1))];
plot3(edgeX_xy(:), edgeY_xy(:), repmat(z_floor + offset, numel(edgeX_xy), 1), '-', 'Color', edge_color, 'LineWidth', line_w, 'LineJoin', 'round');

% YZ平面
shp_yz = alphaShape(Y_combined', Z_combined'); shp_yz.Alpha = shp_yz.Alpha * alpha_shrink;
shp_yz.HoleThreshold = hole_thresh; shp_yz.RegionThreshold = region_thresh;
[Yg_yz, Zg_yz] = meshgrid(linspace(min(Y_combined), max(Y_combined), grid_pts), linspace(min(Z_combined), max(Z_combined), grid_pts));
F_yz = scatteredInterpolant(Y_combined', Z_combined', Distances_combined', 'linear', 'none');
Cg_yz = F_yz(Yg_yz, Zg_yz); in_yz = inShape(shp_yz, Yg_yz, Zg_yz); Cg_yz(~in_yz) = NaN;
surf(repmat(x_wall, size(Yg_yz)), Yg_yz, Zg_yz, Cg_yz, 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'FaceColor', 'interp');
[bf_yz, P_yz] = boundaryFacets(shp_yz);
edgeY_yz = [P_yz(bf_yz(:,1), 1)'; P_yz(bf_yz(:,2), 1)'; NaN(1, size(bf_yz,1))];
edgeZ_yz = [P_yz(bf_yz(:,1), 2)'; P_yz(bf_yz(:,2), 2)'; NaN(1, size(bf_yz,1))];
plot3(repmat(x_wall - offset, numel(edgeY_yz), 1), edgeY_yz(:), edgeZ_yz(:), '-', 'Color', edge_color, 'LineWidth', line_w, 'LineJoin', 'round');

% XZ平面
shp_xz = alphaShape(X_combined', Z_combined'); shp_xz.Alpha = shp_xz.Alpha * alpha_shrink;
shp_xz.HoleThreshold = hole_thresh; shp_xz.RegionThreshold = region_thresh;
[Xg_xz, Zg_xz] = meshgrid(linspace(min(X_combined), max(X_combined), grid_pts), linspace(min(Z_combined), max(Z_combined), grid_pts));
F_xz = scatteredInterpolant(X_combined', Z_combined', Distances_combined', 'linear', 'none');
Cg_xz = F_xz(Xg_xz, Zg_xz); in_xz = inShape(shp_xz, Xg_xz, Zg_xz); Cg_xz(~in_xz) = NaN;
surf(Xg_xz, repmat(y_wall, size(Xg_xz)), Zg_xz, Cg_xz, 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'FaceColor', 'interp');
[bf_xz, P_xz] = boundaryFacets(shp_xz);
edgeX_xz = [P_xz(bf_xz(:,1), 1)'; P_xz(bf_xz(:,2), 1)'; NaN(1, size(bf_xz,1))];
edgeZ_xz = [P_xz(bf_xz(:,1), 2)'; P_xz(bf_xz(:,2), 2)'; NaN(1, size(bf_xz,1))];
plot3(edgeX_xz(:), repmat(y_wall - offset, numel(edgeX_xz), 1), edgeZ_xz(:), '-', 'Color', edge_color, 'LineWidth', line_w, 'LineJoin', 'round');

% Colorbar 及排版
colormap(custom_cmap);
cb_combined = colorbar;
cb_combined.LineWidth = 2; cb_combined.TickLabelInterpreter = 'latex'; cb_combined.FontSize = 40;
cb_combined.Position = [0.75, 0.15, 0.015, 0.7];

hx = xlabel('$y_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
hy = ylabel('$z_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
hz = zlabel('$x_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
drawnow;

hx.Rotation = 15; hy.Rotation = -25;
% hx.Position = [0, -340, -390]; hy.Position = [-340, 0, -390]; hz.Position = [-340, 390, 0 ];

daspect([1 1 1]); pbaspect([1 1 1]);
xlim(global_uniform_lim); ylim(global_uniform_lim); zlim(global_uniform_lim);

% =================================================================
% [新增] 强制三轴步长绝对一致为 50，并修复 LaTeX 倾斜 Bug (图6)
% =================================================================
tick_step = 150;
uniform_ticks = -1000 : tick_step : 1000;
xticks(uniform_ticks);
yticks(uniform_ticks);
zticks(uniform_ticks);

zticklabels(string(-zticks)); yticklabels(string(-yticks));
hold off;
drawnow;

end

function add_stl_model_to_workspace(ax, model_file, options)
%ADD_STL_MODEL_TO_WORKSPACE Insert an STL model into the workspace axes.
%   STL coordinates are mapped with the same convention used for point clouds:
%   original x -> plot -Z, original y -> plot X, original z -> plot -Y.

if ~isfile(model_file)
    warning('STL model not found: %s', model_file);
    return;
end

if ~isfield(options, 'Scale')
    options.Scale = 1;
end
if ~isfield(options, 'ApplyCoordinateMapping')
    options.ApplyCoordinateMapping = true;
end
if ~isfield(options, 'RotationDeg')
    options.RotationDeg = [0, 0, 0];
end
if ~isfield(options, 'FaceColor')
    options.FaceColor = [0.72, 0.72, 0.68];
end
if ~isfield(options, 'FaceAlpha')
    options.FaceAlpha = 0.18;
end
if ~isfield(options, 'EdgeAlpha')
    options.EdgeAlpha = 0.02;
end
if ~isfield(options, 'ReduceRatio')
    options.ReduceRatio = 0.06;
end

model = stlread(model_file);
if ~isa(model, 'triangulation')
    error('stlread did not return a triangulation object for %s', model_file);
end

faces = model.ConnectivityList;
vertices = model.Points;

if options.ReduceRatio > 0 && options.ReduceRatio < 1
    [faces, vertices] = reducepatch(faces, vertices, options.ReduceRatio);
end

if options.ApplyCoordinateMapping
    vertices = map_original_to_plot_coordinates(vertices);
end

vertices = vertices * options.Scale;

R = rotation_matrix_deg(options.RotationDeg);
vertices = (R * vertices')';

if options.EdgeAlpha <= 0
    edge_color = 'none';
else
    edge_color = [0.15, 0.15, 0.15];
end

patch(ax, ...
    'Faces', faces, ...
    'Vertices', vertices, ...
    'FaceColor', options.FaceColor, ...
    'FaceAlpha', options.FaceAlpha, ...
    'EdgeColor', edge_color, ...
    'EdgeAlpha', options.EdgeAlpha, ...
    'LineWidth', 0.2, ...
    'HandleVisibility', 'off');

camlight(ax, 'headlight');
lighting(ax, 'gouraud');
material(ax, 'dull');
end

function vertices_plot = map_original_to_plot_coordinates(vertices_original)
%MAP_ORIGINAL_TO_PLOT_COORDINATES Match the workspace plotting convention.
vertices_plot = [vertices_original(:, 1), -vertices_original(:, 3), vertices_original(:, 2)];
end

function idx = select_workspace_sample_indices(X, Y, Z, n_config, n_palm, max_samples)
%SELECT_WORKSPACE_SAMPLE_INDICES Uniformly sample pose-grid points and keep extrema.
total_points = numel(X);
max_samples = min(total_points, max(1, floor(max_samples)));

if total_points <= max_samples
    idx = (1:total_points).';
    return;
end

extreme_idx = geometry_extreme_indices(X, Y, Z);

if n_palm <= 1
    uniform_idx = round(linspace(1, total_points, max_samples)).';
else
    n_config_sample = min(n_config, max(2, floor(sqrt(max_samples))));
    n_palm_sample = min(n_palm, max(2, floor(max_samples / n_config_sample)));

    while n_config_sample * n_palm_sample > max_samples && n_palm_sample > 1
        n_palm_sample = n_palm_sample - 1;
    end

    config_idx = unique(round(linspace(1, n_config, n_config_sample))).';
    palm_idx = unique(round(linspace(1, n_palm, n_palm_sample))).';
    [config_grid, palm_grid] = ndgrid(config_idx, palm_idx);
    uniform_idx = config_grid(:) + (palm_grid(:) - 1) * n_config;
end

idx = cap_sample_indices([extreme_idx; uniform_idx], extreme_idx, total_points, max_samples);
end

function idx = select_geometry_preserving_indices(X, Y, Z, max_samples)
%SELECT_GEOMETRY_PRESERVING_INDICES Keep geometric extrema during final thinning.
total_points = numel(X);
max_samples = min(total_points, max(1, floor(max_samples)));
extreme_idx = geometry_extreme_indices(X, Y, Z);
uniform_idx = round(linspace(1, total_points, max_samples)).';
idx = cap_sample_indices([extreme_idx; uniform_idx], extreme_idx, total_points, max_samples);
end

function idx = geometry_extreme_indices(X, Y, Z)
%GEOMETRY_EXTREME_INDICES Preserve axis and radial extreme workspace points.
r2 = X.^2 + Y.^2 + Z.^2;
[~, ix_min] = min(X); [~, ix_max] = max(X);
[~, iy_min] = min(Y); [~, iy_max] = max(Y);
[~, iz_min] = min(Z); [~, iz_max] = max(Z);
[~, ir_min] = min(r2); [~, ir_max] = max(r2);
idx = unique([ix_min; ix_max; iy_min; iy_max; iz_min; iz_max; ir_min; ir_max], 'stable');
end

function idx = cap_sample_indices(candidate_idx, protected_idx, total_points, max_samples)
%CAP_SAMPLE_INDICES Trim/fill sample indices while keeping protected extrema.
candidate_idx = unique(candidate_idx(:), 'stable');
protected_idx = unique(protected_idx(:), 'stable');

if numel(candidate_idx) < max_samples
    fill_idx = round(linspace(1, total_points, max_samples)).';
    candidate_idx = unique([protected_idx; candidate_idx; fill_idx], 'stable');
end

if numel(candidate_idx) > max_samples
    protected_idx = protected_idx(1:min(numel(protected_idx), max_samples));
    remaining = setdiff(candidate_idx, protected_idx, 'stable');
    keep_count = max_samples - numel(protected_idx);
    if keep_count > 0 && ~isempty(remaining)
        keep = unique(round(linspace(1, numel(remaining), min(keep_count, numel(remaining))))).';
        idx = [protected_idx; remaining(keep)];
    else
        idx = protected_idx;
    end
else
    idx = candidate_idx;
end

idx = idx(1:min(numel(idx), max_samples));
end

function R = rotation_matrix_deg(rotation_deg)
%ROTATION_MATRIX_DEG Return Rz * Ry * Rx for [rx, ry, rz] degrees.
rx = deg2rad(rotation_deg(1));
ry = deg2rad(rotation_deg(2));
rz = deg2rad(rotation_deg(3));

Rx = [1, 0, 0; 0, cos(rx), -sin(rx); 0, sin(rx), cos(rx)];
Ry = [cos(ry), 0, sin(ry); 0, 1, 0; -sin(ry), 0, cos(ry)];
Rz = [cos(rz), -sin(rz), 0; sin(rz), cos(rz), 0; 0, 0, 1];

R = Rz * Ry * Rx;
end
