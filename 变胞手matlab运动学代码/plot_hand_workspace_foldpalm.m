function WS = plot_hand_workspace_foldpalm(g_tip_num, num_samples)
%PLOT_HAND_WORKSPACE_FOLDPALM 绘制后翻状态下五指指尖工作空间。
%   WS = plot_hand_workspace_foldpalm(g_tip_num, num_samples)
%
%   g_tip_num{i} 为第 i 根手指指尖位姿矩阵，尺寸通常为 4 x 4 x 姿态数 x 手掌构型数。
%   num_samples 控制每根手指最多绘制多少个点；降采样时会保留几何边界极值点。

if nargin < 2 || isempty(num_samples)
    num_samples = 50000;
end

finger_names = {'Thumb', 'Index', 'Middle', 'Ring', 'Little'};
num_fingers = numel(finger_names);

style = workspace_plot_style();
custom_cmap = build_workspace_colormap();

WS = cell(1, num_fingers);
X_parts = cell(1, num_fingers);
Y_parts = cell(1, num_fingers);
Z_parts = cell(1, num_fingers);
Distance_parts = cell(1, num_fingers);

global_min = inf;
global_max = -inf;

fprintf('--- 正在预处理数据并计算全局坐标包围盒 ---\n');

for i = 1:num_fingers
    [X_full, Y_full, Z_full] = extract_tip_points_in_plot_frame(g_tip_num{i});

    % 用完整点云计算全局坐标范围，避免降采样后丢失边界导致坐标盒变小。
    global_min = min([global_min, min(X_full), min(Y_full), min(Z_full)]);
    global_max = max([global_max, max(X_full), max(Y_full), max(Z_full)]);

    total_points = numel(X_full);
    if total_points > num_samples
        sample_idx = select_workspace_sample_indices( ...
            X_full, Y_full, Z_full, size(g_tip_num{i}, 3), size(g_tip_num{i}, 4), num_samples);
        fprintf('Finger %d (%s): Boundary-preserving downsampled to %d points.\n', ...
            i, finger_names{i}, numel(sample_idx));
    else
        sample_idx = 1:total_points;
        fprintf('Finger %d (%s): Total points %d.\n', i, finger_names{i}, total_points);
    end

    X = X_full(sample_idx);
    Y = Y_full(sample_idx);
    Z = Z_full(sample_idx);
    Distances = sqrt(X.^2 + Y.^2 + Z.^2);

    WS{i} = struct('X', X, 'Y', Y, 'Z', Z, 'Distances', Distances);
    X_parts{i} = X;
    Y_parts{i} = Y;
    Z_parts{i} = Z;
    Distance_parts{i} = Distances;
end

global_axis_span = global_max - global_min;
global_uniform_lim = make_global_axis_limits(global_min, global_max, style.GlobalMarginRatio);
walls = make_projection_walls(global_uniform_lim, global_axis_span, style.View);

% % 前 5 张图：每根手指单独绘制，方便检查各手指工作空间差异。
% for i = 1:num_fingers
%     local_span = point_cloud_span(WS{i}.X, WS{i}.Y, WS{i}.Z);
%     draw_workspace_figure( ...
%         sprintf('%s Finger Workspace', finger_names{i}), ...
%         WS{i}, ...
%         [], ...
%         local_span^2, ...
%         global_uniform_lim, ...
%         walls, ...
%         custom_cmap, ...
%         style, ...
%         style.SingleAxesLineWidth, ...
%         style.SingleTickStep, ...
%         style.SingleLabelRotation);
% end

combined = combine_workspace_parts(X_parts, Y_parts, Z_parts, Distance_parts);
combined = downsample_combined_workspace(combined, style.MaxCombinedPoints);

% 第 6 张图：五指综合工作空间，并叠加参考图片。
reference_image = make_reference_image_options(global_axis_span);
draw_workspace_figure( ...
    'Combined Workspace of All Fingers', ...
    combined, ...
    reference_image, ...
    global_axis_span^2, ...
    global_uniform_lim, ...
    walls, ...
    custom_cmap, ...
    style, ...
    style.CombinedAxesLineWidth, ...
    style.CombinedTickStep, ...
    style.CombinedLabelRotation);

end

function style = workspace_plot_style()
%WORKSPACE_PLOT_STYLE 集中管理绘图样式，后续调图时优先改这里。
style.View = [52.5, 20];
style.FontSize = 40;
style.AxesColor = [0.98, 0.98, 0.98];
style.GridLineWidth = 2;
style.GridAlpha = 0.25;
style.ScatterSize = 100;
style.ProjectionAlpha = 0.4;
style.ProjectionLineWidth = 2.0;
style.ProjectionEdgeColor = [0.0039, 0.1255, 0.1882];
style.GridPts = 200;
style.AlphaShrink = 1.6;
style.HoleThresholdRatio = 0.015;
style.RegionThresholdRatio = 0.005;
style.GlobalMarginRatio = 0.3;
style.MaxCombinedPoints = 1000000;
style.SingleAxesLineWidth = 2;
style.CombinedAxesLineWidth = 3;
style.SingleTickStep = 100;
style.CombinedTickStep = 150;
style.SingleLabelRotation = [25, -35];
style.CombinedLabelRotation = [15, -25];
style.ColorbarPosition = [0.75, 0.15, 0.015, 0.7];
end

function custom_cmap = build_workspace_colormap()
%BUILD_WORKSPACE_COLORMAP 自定义距离色标：深色表示近，浅绿色表示远。
color_nodes = [
    0.0039, 0.1255, 0.1882
    0.0745, 0.4039, 0.5412
    0.2706, 0.7686, 0.6902
    0.6039, 0.9216, 0.6392
    0.8549, 0.9922, 0.7294
    ];

custom_cmap = interp1( ...
    linspace(0, 1, size(color_nodes, 1)), ...
    color_nodes, ...
    linspace(0, 1, 256));
end

function [X_plot, Y_plot, Z_plot] = extract_tip_points_in_plot_frame(H_tip)
%EXTRACT_TIP_POINTS_IN_PLOT_FRAME 提取指尖位置，并转换到论文绘图坐标系。
X_orig = reshape(H_tip(1, 4, :, :), 1, []);
Y_orig = reshape(H_tip(2, 4, :, :), 1, []);
Z_orig = reshape(H_tip(3, 4, :, :), 1, []);

% 坐标轮换：原始 x -> 绘图 -Z；原始 y -> 绘图 X；原始 z -> 绘图 -Y。
X_plot = Y_orig;
Y_plot = -Z_orig;
Z_plot = -X_orig;
end

function global_uniform_lim = make_global_axis_limits(global_min, global_max, margin_ratio)
%MAKE_GLOBAL_AXIS_LIMITS 统一六张图的坐标范围，保证尺度完全一致。
global_axis_span = global_max - global_min;
global_margin = global_axis_span * margin_ratio;
global_uniform_lim = [global_min - global_margin, global_max + global_margin];
end

function walls = make_projection_walls(global_uniform_lim, global_axis_span, view_angles)
%MAKE_PROJECTION_WALLS 根据当前视角，将投影面放在远离相机的一侧。
offset = global_axis_span * 0.005;
camera_direction = view_angles_to_camera_direction(view_angles);

[walls.XWall, walls.XEdgeOffset] = far_wall_from_camera_direction( ...
    camera_direction(1), global_uniform_lim, offset);
[walls.YWall, walls.YEdgeOffset] = far_wall_from_camera_direction( ...
    camera_direction(2), global_uniform_lim, offset);
[walls.ZFloor, walls.ZEdgeOffset] = far_wall_from_camera_direction( ...
    camera_direction(3), global_uniform_lim, offset);
end

function camera_direction = view_angles_to_camera_direction(view_angles)
%VIEW_ANGLES_TO_CAMERA_DIRECTION 将 MATLAB view(az, el) 近似转换为相机所在方向。
az = view_angles(1);
el = view_angles(2);
camera_direction = [cosd(el) * sind(az), -cosd(el) * cosd(az), sind(el)];
end

function [wall_value, edge_offset] = far_wall_from_camera_direction(camera_component, axis_lim, offset)
%FAR_WALL_FROM_CAMERA_DIRECTION 选择相机对侧的投影墙，并给轮廓线一个向内偏移。
if camera_component >= 0
    wall_value = axis_lim(1);
    edge_offset = offset;
else
    wall_value = axis_lim(2);
    edge_offset = -offset;
end
end

function combined = combine_workspace_parts(X_parts, Y_parts, Z_parts, Distance_parts)
%COMBINE_WORKSPACE_PARTS 汇总五指点云，避免循环中反复扩展大数组。
combined = struct();
combined.X = [X_parts{:}];
combined.Y = [Y_parts{:}];
combined.Z = [Z_parts{:}];
combined.Distances = [Distance_parts{:}];
end

function combined = downsample_combined_workspace(combined, max_points)
%DOWNSAMPLE_COMBINED_WORKSPACE 综合图点数过多时，再做一次边界保留降采样。
total_points = numel(combined.X);
if total_points <= max_points
    return;
end

sample_idx = select_geometry_preserving_indices(combined.X, combined.Y, combined.Z, max_points);
combined.X = combined.X(sample_idx);
combined.Y = combined.Y(sample_idx);
combined.Z = combined.Z(sample_idx);
combined.Distances = combined.Distances(sample_idx);

fprintf('Figure 6: Boundary-preserving downsampled from %d to %d.\n', ...
    total_points, numel(sample_idx));
end

function reference_image = make_reference_image_options(global_axis_span)
%MAKE_REFERENCE_IMAGE_OPTIONS 参考图片的文件路径、位置、尺寸和透明度。
repo_root = fileparts(fileparts(mfilename('fullpath')));

reference_image = struct();
reference_image.File = fullfile(repo_root, '资源 6后翻工作空间示意.png');
reference_image.Options = struct();

% 手动调图入口：
% Center 控制图片中心 [X, Y, Z]；Size 控制 [宽, 高]；RollDeg 控制相机平面内旋转。
reference_image.Options.Center = [-50, 60, 20];
reference_image.Options.Size = [global_axis_span*0.77, NaN];
reference_image.Options.RollDeg = 25;
reference_image.Options.Alpha = 0.85;
reference_image.Options.WhiteThreshold = 0.18;
end

function draw_workspace_figure(fig_name, data, reference_image, area_scale, ...
    global_uniform_lim, walls, custom_cmap, style, axes_line_width, tick_step, label_rotation)
%DRAW_WORKSPACE_FIGURE 绘制单张工作空间图：点云、三面投影、色标和坐标轴。
figure('Name', fig_name, 'Color', 'w');
ax = gca;
hold(ax, 'on');
grid(ax, 'on');
configure_workspace_axes(ax, style, axes_line_width);
view(ax, style.View(1), style.View(2));

if ~isempty(reference_image)
    add_workspace_reference_image(ax, reference_image.File, reference_image.Options);
end

hole_thresh = area_scale * style.HoleThresholdRatio;
region_thresh = area_scale * style.RegionThresholdRatio;

draw_workspace_cloud(ax, data, style);
draw_workspace_projections(ax, data, walls, style, hole_thresh, region_thresh);
apply_workspace_layout(ax, custom_cmap, style, global_uniform_lim, tick_step, label_rotation);

hold(ax, 'off');
drawnow;
end

function configure_workspace_axes(ax, style, axes_line_width)
%CONFIGURE_WORKSPACE_AXES 设置统一坐标轴外观。
set(ax, ...
    'TickLabelInterpreter', 'latex', ...
    'FontSize', style.FontSize, ...
    'Color', style.AxesColor, ...
    'LineWidth', axes_line_width, ...
    'GridLineWidth', style.GridLineWidth, ...
    'GridAlpha', style.GridAlpha);
end

function draw_workspace_cloud(ax, data, style)
%DRAW_WORKSPACE_CLOUD 绘制指尖可达点云，颜色表示到原点的距离。
scatter3(ax, data.X, data.Y, data.Z, style.ScatterSize, data.Distances, ...
    'filled', ...
    'MarkerFaceAlpha', 1, ...
    'MarkerEdgeColor', 'none');
end

function draw_workspace_projections(ax, data, walls, style, hole_thresh, region_thresh)
%DRAW_WORKSPACE_PROJECTIONS 在 XY、YZ、XZ 三个边界平面上绘制投影和外轮廓。
draw_xy_projection(ax, data, walls, style, hole_thresh, region_thresh);
draw_yz_projection(ax, data, walls, style, hole_thresh, region_thresh);
draw_xz_projection(ax, data, walls, style, hole_thresh, region_thresh);
end

function draw_xy_projection(ax, data, walls, style, hole_thresh, region_thresh)
%DRAW_XY_PROJECTION 将工作空间投影到 XY 平面，即 z = z_floor。
shp = alphaShape(data.X', data.Y');
shp.Alpha = shp.Alpha * style.AlphaShrink;
shp.HoleThreshold = hole_thresh;
shp.RegionThreshold = region_thresh;

[Xg, Yg] = meshgrid( ...
    linspace(min(data.X), max(data.X), style.GridPts), ...
    linspace(min(data.Y), max(data.Y), style.GridPts));
F = scatteredInterpolant(data.X', data.Y', data.Distances', 'linear', 'none');
Cg = F(Xg, Yg);
Cg(~inShape(shp, Xg, Yg)) = NaN;

surf(ax, Xg, Yg, repmat(walls.ZFloor, size(Xg)), Cg, ...
    'EdgeColor', 'none', ...
    'FaceAlpha', style.ProjectionAlpha, ...
    'FaceColor', 'interp');

[bf, P] = boundaryFacets(shp);
edgeX = [P(bf(:, 1), 1)'; P(bf(:, 2), 1)'; NaN(1, size(bf, 1))];
edgeY = [P(bf(:, 1), 2)'; P(bf(:, 2), 2)'; NaN(1, size(bf, 1))];
plot3(ax, edgeX(:), edgeY(:), repmat(walls.ZFloor + walls.ZEdgeOffset, numel(edgeX), 1), ...
    '-', 'Color', style.ProjectionEdgeColor, 'LineWidth', style.ProjectionLineWidth, 'LineJoin', 'round');
end

function draw_yz_projection(ax, data, walls, style, hole_thresh, region_thresh)
%DRAW_YZ_PROJECTION 将工作空间投影到 YZ 平面，即 x = x_wall。
shp = alphaShape(data.Y', data.Z');
shp.Alpha = shp.Alpha * style.AlphaShrink;
shp.HoleThreshold = hole_thresh;
shp.RegionThreshold = region_thresh;

[Yg, Zg] = meshgrid( ...
    linspace(min(data.Y), max(data.Y), style.GridPts), ...
    linspace(min(data.Z), max(data.Z), style.GridPts));
F = scatteredInterpolant(data.Y', data.Z', data.Distances', 'linear', 'none');
Cg = F(Yg, Zg);
Cg(~inShape(shp, Yg, Zg)) = NaN;

surf(ax, repmat(walls.XWall, size(Yg)), Yg, Zg, Cg, ...
    'EdgeColor', 'none', ...
    'FaceAlpha', style.ProjectionAlpha, ...
    'FaceColor', 'interp');

[bf, P] = boundaryFacets(shp);
edgeY = [P(bf(:, 1), 1)'; P(bf(:, 2), 1)'; NaN(1, size(bf, 1))];
edgeZ = [P(bf(:, 1), 2)'; P(bf(:, 2), 2)'; NaN(1, size(bf, 1))];
plot3(ax, repmat(walls.XWall + walls.XEdgeOffset, numel(edgeY), 1), edgeY(:), edgeZ(:), ...
    '-', 'Color', style.ProjectionEdgeColor, 'LineWidth', style.ProjectionLineWidth, 'LineJoin', 'round');
end

function draw_xz_projection(ax, data, walls, style, hole_thresh, region_thresh)
%DRAW_XZ_PROJECTION 将工作空间投影到 XZ 平面，即 y = y_wall。
shp = alphaShape(data.X', data.Z');
shp.Alpha = shp.Alpha * style.AlphaShrink;
shp.HoleThreshold = hole_thresh;
shp.RegionThreshold = region_thresh;

[Xg, Zg] = meshgrid( ...
    linspace(min(data.X), max(data.X), style.GridPts), ...
    linspace(min(data.Z), max(data.Z), style.GridPts));
F = scatteredInterpolant(data.X', data.Z', data.Distances', 'linear', 'none');
Cg = F(Xg, Zg);
Cg(~inShape(shp, Xg, Zg)) = NaN;

surf(ax, Xg, repmat(walls.YWall, size(Xg)), Zg, Cg, ...
    'EdgeColor', 'none', ...
    'FaceAlpha', style.ProjectionAlpha, ...
    'FaceColor', 'interp');

[bf, P] = boundaryFacets(shp);
edgeX = [P(bf(:, 1), 1)'; P(bf(:, 2), 1)'; NaN(1, size(bf, 1))];
edgeZ = [P(bf(:, 1), 2)'; P(bf(:, 2), 2)'; NaN(1, size(bf, 1))];
plot3(ax, edgeX(:), repmat(walls.YWall + walls.YEdgeOffset, numel(edgeX), 1), edgeZ(:), ...
    '-', 'Color', style.ProjectionEdgeColor, 'LineWidth', style.ProjectionLineWidth, 'LineJoin', 'round');
end

function apply_workspace_layout(ax, custom_cmap, style, global_uniform_lim, tick_step, label_rotation)
%APPLY_WORKSPACE_LAYOUT 统一色标、坐标轴标签、比例和刻度显示。
colormap(ax, custom_cmap);
cb = colorbar(ax);
cb.LineWidth = 2;
cb.TickLabelInterpreter = 'latex';
cb.FontSize = style.FontSize;
cb.Position = style.ColorbarPosition;

hx = xlabel(ax, '$y_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', style.FontSize);
hy = ylabel(ax, '$z_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', style.FontSize);
zlabel(ax, '$x_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', style.FontSize);
hx.Rotation = label_rotation(1);
hy.Rotation = label_rotation(2);

daspect(ax, [1 1 1]);
pbaspect(ax, [1 1 1]);
xlim(ax, global_uniform_lim);
ylim(ax, global_uniform_lim);
zlim(ax, global_uniform_lim);

uniform_ticks = -1000:tick_step:1000;
xticks(ax, uniform_ticks);
yticks(ax, uniform_ticks);
zticks(ax, uniform_ticks);

% 由于绘图坐标经过轮换，Y/Z 轴刻度标签取反以对应原始物理坐标方向。
yticklabels(ax, string(-yticks(ax)));
zticklabels(ax, string(-zticks(ax)));
end

function add_workspace_reference_image(ax, image_file, options)
%ADD_WORKSPACE_REFERENCE_IMAGE 将参考图作为面向相机的半透明贴片叠加到综合图中。
% 当前版本使用相机朝向来确定图片平面；如果要固定到某个坐标平面，可改 image_right/image_up。

if ~isfile(image_file)
    warning('Reference image not found: %s', image_file);
    return;
end

options = fill_reference_image_defaults(options);

[img, ~, alpha_channel] = imread(image_file);
[alpha_data, img] = make_reference_image_alpha(img, alpha_channel, options);
[image_width, image_height] = reference_image_size(img, options.Size);

[image_right, image_up] = camera_facing_image_axes(ax, options.RollDeg);
[image_x_plot, image_y_plot, image_z_plot] = reference_image_corners( ...
    options.Center, image_width, image_height, image_right, image_up);

surface(ax, ...
    image_x_plot, ...
    image_y_plot, ...
    image_z_plot, ...
    img, ...
    'FaceColor', 'texturemap', ...
    'EdgeColor', 'none', ...
    'FaceAlpha', 'texturemap', ...
    'AlphaData', alpha_data, ...
    'AlphaDataMapping', 'none', ...
    'HandleVisibility', 'off');
end

function options = fill_reference_image_defaults(options)
%FILL_REFERENCE_IMAGE_DEFAULTS 补齐参考图片参数，避免漏填字段时报错。
if ~isfield(options, 'Center')
    options.Center = [0, 0, 0];
end
if ~isfield(options, 'Size')
    options.Size = [300, NaN];
end
if ~isfield(options, 'RollDeg')
    options.RollDeg = 0;
end
if ~isfield(options, 'Alpha')
    options.Alpha = 0.35;
end
if ~isfield(options, 'WhiteThreshold')
    options.WhiteThreshold = 0.18;
end
end

function [alpha_data, img] = make_reference_image_alpha(img, alpha_channel, options)
%MAKE_REFERENCE_IMAGE_ALPHA 使用 PNG alpha 通道或白底距离生成透明度。
img_double = im2double(img);

if isempty(alpha_channel)
    background_distance = sqrt(sum((img_double - 1).^2, 3));
    alpha_data = min(max(background_distance / options.WhiteThreshold, 0), 1);
else
    alpha_data = im2double(alpha_channel);
end

alpha_data = alpha_data * options.Alpha;
end

function [image_width, image_height] = reference_image_size(img, image_size)
%REFERENCE_IMAGE_SIZE 宽度由 Size(1) 给出，高度可按原图比例自动计算。
image_width = image_size(1);
if numel(image_size) < 2 || isnan(image_size(2))
    image_height = image_width * size(img, 1) / size(img, 2);
else
    image_height = image_size(2);
end
end

function [image_right, image_up] = camera_facing_image_axes(ax, roll_deg)
%CAMERA_FACING_IMAGE_AXES 计算面向当前摄像机的图片局部横向和纵向。
cam_dir = ax.CameraTarget - ax.CameraPosition;
cam_dir = cam_dir / norm(cam_dir);

cam_up = ax.CameraUpVector / norm(ax.CameraUpVector);
cam_right = cross(cam_dir, cam_up);
cam_right = cam_right / norm(cam_right);
cam_up = cross(cam_right, cam_dir);
cam_up = cam_up / norm(cam_up);

roll_rad = deg2rad(roll_deg);
image_right = cam_right * cos(roll_rad) + cam_up * sin(roll_rad);
image_up = -cam_right * sin(roll_rad) + cam_up * cos(roll_rad);
end

function [image_x_plot, image_y_plot, image_z_plot] = reference_image_corners( ...
    center, image_width, image_height, image_right, image_up)
%REFERENCE_IMAGE_CORNERS 根据图片中心、尺寸和方向计算四个角点。
left_top = center - image_width / 2 * image_right + image_height / 2 * image_up;
right_top = center + image_width / 2 * image_right + image_height / 2 * image_up;
left_bottom = center - image_width / 2 * image_right - image_height / 2 * image_up;
right_bottom = center + image_width / 2 * image_right - image_height / 2 * image_up;

image_x_plot = [left_top(1), right_top(1); left_bottom(1), right_bottom(1)];
image_y_plot = [left_top(2), right_top(2); left_bottom(2), right_bottom(2)];
image_z_plot = [left_top(3), right_top(3); left_bottom(3), right_bottom(3)];
end

function idx = select_workspace_sample_indices(X, Y, Z, n_config, n_palm, max_samples)
%SELECT_WORKSPACE_SAMPLE_INDICES 均匀采样姿态网格，并强制保留边界极值点。
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
%SELECT_GEOMETRY_PRESERVING_INDICES 最终降采样时继续保留几何边界点。
total_points = numel(X);
max_samples = min(total_points, max(1, floor(max_samples)));
extreme_idx = geometry_extreme_indices(X, Y, Z);
uniform_idx = round(linspace(1, total_points, max_samples)).';
idx = cap_sample_indices([extreme_idx; uniform_idx], extreme_idx, total_points, max_samples);
end

function idx = geometry_extreme_indices(X, Y, Z)
%GEOMETRY_EXTREME_INDICES 保留 X/Y/Z 轴向极值和距离原点的径向极值。
r2 = X.^2 + Y.^2 + Z.^2;
[~, ix_min] = min(X);
[~, ix_max] = max(X);
[~, iy_min] = min(Y);
[~, iy_max] = max(Y);
[~, iz_min] = min(Z);
[~, iz_max] = max(Z);
[~, ir_min] = min(r2);
[~, ir_max] = max(r2);
idx = unique([ix_min; ix_max; iy_min; iy_max; iz_min; iz_max; ir_min; ir_max], 'stable');
end

function idx = cap_sample_indices(candidate_idx, protected_idx, total_points, max_samples)
%CAP_SAMPLE_INDICES 控制采样点数，同时优先保留 protected_idx 中的边界点。
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
