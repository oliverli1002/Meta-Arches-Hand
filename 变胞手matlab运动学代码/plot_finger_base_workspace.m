function plot_finger_base_workspace(g_all, fingerNames, maxPts)
%PLOT_FINGER_BASE_WORKSPACE  绘制手掌上5个指根坐标系原点的工作空间点云（带自动避让label）

    arguments
        g_all double
        fingerNames = ["Thumb","Index","Middle","Ring","Little"]
        maxPts (1,1) double {mustBePositive, mustBeFinite} = 5000
    end

    sz = size(g_all);
    assert(numel(sz) == 4 && sz(1)==4 && sz(2)==4 && sz(3)==5, ...
        "g_all 必须是 4×4×5×N 的数组。");

    % 颜色（5根手指）
    C = lines(5);

    figure('Color','w'); hold on; grid on; axis equal;
    xlabel('X'); ylabel('Y'); zlabel('Z');
    title('Finger base workspace (origins)');
    view(3);

    % 用所有点的整体中心，作为“往外移”的参考
    Pall = reshape(g_all(1:3,4,:,:), 3, []); % 3×(5N)
    vAll = all(isfinite(Pall),1);
    P0 = mean(Pall(:,vAll), 2);             % 3×1，全局中心

    % （可调）label 外移强度：整体尺度的百分比
    % 如果还挡住，把 0.06 调到 0.10；如果太远，调小
    globalScale = max(std(Pall(:,vAll),0,2));  % 一个粗略尺度
    labelOffset = 0.10 * globalScale;

    for i = 1:5
        % 提取第 i 根手指所有姿态下的原点位置：3×N
        P = squeeze(g_all(1:3,4,i,:));   % 3×N
        x = P(1,:); y = P(2,:); z = P(3,:);

        % 去掉 NaN/Inf
        valid = isfinite(x) & isfinite(y) & isfinite(z);
        x = x(valid); y = y(valid); z = z(valid);
        P = [x; y; z];

        % 降采样，避免点太多画得慢
        nPts = size(P,2);
        if nPts > maxPts
            idx = round(linspace(1, nPts, maxPts));
            P = P(:,idx);
            x = P(1,:); y = P(2,:); z = P(3,:);
            nPts = maxPts;
        end

        scatter3(x, y, z, 8, ...
            'MarkerEdgeColor', C(i,:), ...
            'MarkerFaceColor', C(i,:), ...
            'MarkerFaceAlpha', 0.25, ...
            'MarkerEdgeAlpha', 0.25);

        % --------- 关键：更聪明的 label 位置 ---------
        if nPts > 10
            % 用点云中心作为基准
            Pc = mean(P, 2);

            % 主方向（第一主成分）用于找“靠外”的代表点
            Q = P - Pc;
            [~,~,V] = svd(Q.', 'econ');   % Q' 是 n×3
            dir1 = V(:,1);                % 3×1

            % 在主方向上取最外侧的点作为 anchor（更像“边界点”）
            t = dir1.' * Q;               % 1×n
            [~, j] = max(t);
            Pa = P(:,j);                  % anchor 点

            % 往全局中心的反方向偏移（把文字推到点云外侧）
            v = Pa - P0;
            if norm(v) < 1e-9
                v = dir1; % 退化情况
            end
            v = v / norm(v);

            Plabel = Pa + labelOffset * v;

            text(Plabel(1), Plabel(2), Plabel(3), string(fingerNames(i)), ...
                'Color', C(i,:), ...
                'FontSize', 11, ...
                'FontWeight','bold', ...
                'BackgroundColor','w', ...   % ★白底避免被点遮
                'Margin', 2, ...
                'Interpreter','none');
        end
    end

    legend(string(fingerNames), 'Location','bestoutside');
end