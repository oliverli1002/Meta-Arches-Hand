function WS = plot_palm_workspace(g_base_num, num_samples)
% PLOT_PALM_WORKSPACE 绘制变胞手掌指根坐标系的整体工作空间
% 升级版：取消距离热力图，改为五指独立纯色分类点云，保留淡淡的球壳参考

if nargin < 2
    num_samples = 50000; % 默认降采样数
end

finger_names = {'Thumb Base', 'Finger Bases'};

% --- 1. 提取与整合所有指根的数据 ---
X_combined = [];
Y_combined = [];
Z_combined = [];
FingerID_combined = []; % 新增：用于记录每个点属于哪根手指

for i = 1:5
    % 提取当前指根（第 i 根手指）的绝对空间坐标
    X_orig = reshape(g_base_num(1, 4, i, :), 1, []);
    Y_orig = reshape(g_base_num(2, 4, i, :), 1, []);
    Z_orig = reshape(g_base_num(3, 4, i, :), 1, []);
    
    % 严格保持相同的坐标旋转置换 (x->y, y->-z, z->-x)
    X = Y_orig;
    Y = -Z_orig;
    Z = -X_orig;
    
    X_combined = [X_combined, X];
    Y_combined = [Y_combined, Y];
    Z_combined = [Z_combined, Z];
    FingerID_combined = [FingerID_combined, i * ones(1, length(X))]; % 打上 1~5 的标签
end

% 随机降采样以保证渲染流畅度
total_points = length(X_combined);
if total_points > num_samples
    idx = randperm(total_points, num_samples);
    X_combined = X_combined(idx);
    Y_combined = Y_combined(idx);
    Z_combined = Z_combined(idx);
    FingerID_combined = FingerID_combined(idx); % 同步降采样标签
    fprintf('Palm Workspace: Downsampled from %d to %d points.\n', total_points, num_samples);
else
    fprintf('Palm Workspace: Total points %d.\n', total_points);
end

% 仅用于计算参考球面半径
Distances_combined = sqrt(X_combined.^2 + Y_combined.^2 + Z_combined.^2);
WS = struct('X', X_combined, 'Y', Y_combined, 'Z', Z_combined, 'FingerID', FingerID_combined);

% --- 2. 核心修改：计算包含参考球面的自适应坐标极限 ---
R_ref = mean(Distances_combined); 

% 为了防止画出的球面被坐标轴截断，将球面的范围 (-R_ref 到 R_ref) 也纳入极限计算
global_min = min([min(X_combined), min(Y_combined), min(Z_combined), -R_ref]);
global_max = max([max(X_combined), max(Y_combined), max(Z_combined),  R_ref]);

global_axis_span = global_max - global_min;
global_margin = global_axis_span * 0.2; % 留出 20% 的空白边距
global_uniform_lim = [global_min - global_margin, global_max + global_margin];

% --- 3. 初始化顶级排版图表 ---
figure('Name', 'Palm Base Workspace', 'Color', 'w');
hold on; grid on;
set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 40, 'Color', [0.98, 0.98, 0.98], ...
    'LineWidth', 3, 'GridLineWidth', 2, 'GridAlpha', 0.25);
view(45, 20);

% ==================== 1. 绘制辅助参考球体 (淡淡球壳) ====================
[sx, sy, sz] = sphere(40);
surf(sx * R_ref, sy * R_ref, sz * R_ref, ...
    'FaceColor', 'w', ...
    'LineWidth', 1.5, ...
    'EdgeColor', 'k', ...       
    'EdgeAlpha', 0.04, ...
    'FaceAlpha', 0.3);             

% ==================== 2. 绘制主体 3D 分类点云 ====================
% 自定义五指的高级纯色配色 (经典学术期刊分类配色)
colors = [
    60 , 103, 142; 
    140, 190, 178; 
    140, 190, 178; 
    140, 190, 178; 
    140, 190, 178  
]./255;

% 循环 5 次，每次只画对应手指的点云
for i = 1:5
    mask = (FingerID_combined == i); % 提取当前手指的点
    scatter3(X_combined(mask), Y_combined(mask), Z_combined(mask), 100, colors(i,:), 'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeColor', 'none');
end

% ==================== 3. 添加图例 (Legend) ====================
% 绘制隐形的参考点，专门用于生成干净的图例
p_lgd = gobjects(1, 2);
for i = 1:2
    p_lgd(i) = plot(NaN, NaN, 'o', 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'none', 'MarkerSize', 15);
end

% 设置为 northeast（坐标轴内部右上角）
lgd = legend(p_lgd, finger_names, 'Interpreter', 'latex', 'FontSize', 30, 'Location', 'northeast');

% --- 核心修改：打造高级质感的图例方框 ---
lgd.Box = 'on';                       % 开启方框边界
lgd.Color = [1, 1, 1, 0.85];          % 背景设为白色，且带 85% 不透明度（微微透出背后网格，非常高级）
lgd.EdgeColor = [0.15, 0.15, 0.15];   % 边框颜色设为深灰色（比纯黑看起来更柔和现代）
lgd.LineWidth = 1.5;                  % 方框的线条粗细
lgd.Position = [0.6342    0.5843    0.0619    0.2007]; % legend位置

% ==================== 4. 字体与排版 ====================
hx = xlabel('$y_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
hy = ylabel('$z_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
hz = zlabel('$x_{p}$ (mm)', 'Interpreter', 'latex', 'FontSize', 40);
drawnow;

hx.Rotation = -25; 
hy.Rotation = 25;

% 尺寸自适应的绝对居中逻辑
mid_pos = (global_uniform_lim(1) + global_uniform_lim(2)) / 2;
neg_pos1 = global_uniform_lim(1) - global_axis_span * 0.15;
neg_pos2 = global_uniform_lim(1) - global_axis_span * 0.25;
pos_pos1 = global_uniform_lim(2) + global_axis_span * 0.15;

daspect([1 1 1]);
pbaspect([1 1 1]);
xlim(global_uniform_lim);
ylim(global_uniform_lim);
zlim(global_uniform_lim);

% =================================================================
% 【新增】强制三轴步长绝对一致为 50，不干涉其他任何逻辑
% =================================================================
tick_step = 100; 
uniform_ticks = -1000 : tick_step : 1000;
xticks(uniform_ticks);
yticks(uniform_ticks);
zticks(uniform_ticks);

current_zticks_comb = zticks;
zticklabels(string(-current_zticks_comb));
current_yticks_comb = yticks;
yticklabels(string(-current_yticks_comb));

hold off;
drawnow;

end