function WS = plot_finger_tip_workspace(H_t_num, varargin)
%PLOT_HAND_WORKSPACE_NO_DEDUP_TOPVIEW 不去重绘制工作空间点云（更清晰），默认俯视(-Z)且X轴竖直
%
% 默认视角：
%   - 沿 z 轴负方向观察（从 +z 往下看）
%   - 屏幕竖直方向为 X 轴：view(90, -90)

p = inputParser;
p.addRequired('H_t_num', @(x) isnumeric(x) && ndims(x) >= 2 && size(x,1)==4 && size(x,2)==4);

p.addParameter('FingerDim', [], @(x) isempty(x) || (isscalar(x) && x==round(x) && x>=3));
p.addParameter('PerFinger', true, @(x) islogical(x) && isscalar(x));

p.addParameter('FingerNames', {'Thumb','Index','Middle','Ring','Little'}, @(c) iscell(c) || isstring(c));
p.addParameter('Colors', [], @(c) isempty(c) || (isnumeric(c) && size(c,2)==3));

% 可见性相关（默认比之前“更显”）
p.addParameter('MarkerSize', 6, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('FaceAlpha', 0.20, @(x) isnumeric(x) && isscalar(x) && x>=0 && x<=1);
p.addParameter('EdgeAlpha', 0.35, @(x) isnumeric(x) && isscalar(x) && x>=0 && x<=1);
p.addParameter('EdgeColor', [0 0 0], @(c) isnumeric(c) && numel(c)==3);

% 自动平衡：让点多的手指更透明、点少的更不透明（提高区分度）
p.addParameter('BalanceAlphaByCount', true, @(x) islogical(x) && isscalar(x));
p.addParameter('Unit', 'mm', @(s) ischar(s) || isstring(s));
p.addParameter('ShowAxesEqual', true, @(x) islogical(x) && isscalar(x));

p.parse(H_t_num, varargin{:});

fingerDim   = p.Results.FingerDim;
perFinger   = p.Results.PerFinger;
fingerNames = string(p.Results.FingerNames);
colorsIn    = p.Results.Colors;

ms          = p.Results.MarkerSize;
faceA0      = p.Results.FaceAlpha;
edgeA0      = p.Results.EdgeAlpha;
edgeColor   = p.Results.EdgeColor;

balAlpha    = p.Results.BalanceAlphaByCount;
unitStr     = string(p.Results.Unit);
showAxesEq  = p.Results.ShowAxesEqual;

% ---- 维度与手指维 ----
nd = ndims(H_t_num);
sz = size(H_t_num);
if isempty(fingerDim), fingerDim = nd; end
if fingerDim < 3 || fingerDim > nd
    error('FingerDim=%d 不合法，应在 [3, ndims(H_t_num)] 内。', fingerDim);
end
Nfinger = sz(fingerDim);

% ---- 颜色：更“深”的方案 ----
if isempty(colorsIn)
    base = lines(Nfinger);
    % 把颜色整体加深（乘系数 <1），并略微提高饱和感
    colors = max(min(base * 0.85, 1), 0);
else
    colors = colorsIn;
    if size(colors,1) ~= Nfinger
        error('Colors 行数应等于 Nfinger=%d。', Nfinger);
    end
end

if numel(fingerNames) ~= Nfinger
    fingerNames = "Finger " + (1:Nfinger);
end

% ---- 提取位置并整理为：3 × Nsamples × Nfinger ----
Pall = squeeze(H_t_num(1:3,4,:,:,:,:,:,:)); % 3 × dims(3..nd)
fingerDimInP = fingerDim - 1;

dimsP = ndims(Pall);
ord = [1, setdiff(2:dimsP, fingerDimInP, 'stable'), fingerDimInP];
Pall2 = permute(Pall, ord);

sz2 = size(Pall2);
Nfinger = sz2(end);
Nsamples = prod(sz2(2:end-1));
Pflat = reshape(Pall2, 3, Nsamples, Nfinger);

WS = struct();
WS.P_raw = cell(1, Nfinger);
WS.P_all_raw = [];

counts = zeros(1, Nfinger);
for f = 1:Nfinger
    Pf = squeeze(Pflat(:,:,f)).'; % Nsamples × 3
    WS.P_raw{f} = Pf;
    WS.P_all_raw = [WS.P_all_raw; Pf]; %#ok<AGROW>
    counts(f) = size(Pf,1);
end

% ---- 绘图 ----
figure('Color','w'); hold on; grid on;

if perFinger
    h = gobjects(1, Nfinger);

    % 透明度平衡：点越多越透明，点越少越不透明（但限定范围）
    if balAlpha
        cmin = max(min(counts), 1);
        cmax = max(counts);
        if cmax == cmin
            faceA = repmat(faceA0, 1, Nfinger);
        else
            t = (log(counts) - log(cmin)) / (log(cmax) - log(cmin)); % 0..1
            % faceA 在 [0.12, 0.35] 内变化（可按需改）
            faceA = 0.35 - t * (0.35 - 0.12);
        end
    else
        faceA = repmat(faceA0, 1, Nfinger);
    end

    for f = 1:Nfinger
        Pf = WS.P_raw{f};
        if isempty(Pf), continue; end

        h(f) = scatter3(Pf(:,1), Pf(:,2), Pf(:,3), ms, ...
            'MarkerFaceColor', colors(f,:), ...
            'MarkerEdgeColor', edgeColor);

        % 边/面透明度分开设，稀疏点也更“立得住”
        h(f).MarkerFaceAlpha = faceA(f);
        h(f).MarkerEdgeAlpha = edgeA0;
    end

    legend(h, fingerNames, 'Location', 'bestoutside');
    title("工作空间点云（不去重，按手指着色）");
else
    P0 = WS.P_all_raw;
    s = scatter3(P0(:,1), P0(:,2), P0(:,3), ms, ...
        'MarkerFaceColor', [0.15 0.15 0.15], ...
        'MarkerEdgeColor', [0 0 0]);
    s.MarkerFaceAlpha = faceA0;
    s.MarkerEdgeAlpha = edgeA0;
    title("工作空间点云（不去重，所有手指合并）");
end

xlabel("X (" + unitStr + ")");
ylabel("Y (" + unitStr + ")");
zlabel("Z (" + unitStr + ")");

if showAxesEq, axis equal; end

% 关键：俯视(-Z) + 让 X 在竖直方向（比 view(0,-90) 多旋转 90°）
view(90, -90);

end