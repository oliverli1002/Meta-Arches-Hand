function [S, r3_all] = yield_finger_screws()
%YIELD_FINGER_SCREWS 生成五指(拇/食/中/无/小)三关节旋量系，并输出各指 r3
%
% 输出：
%   S      : 6×3×5 的符号数组
%   r3_all : 3×5 的符号矩阵，r3_all(:,f) = 第 f 指第3关节的 r3 向量
%
% 说明：
%   f=1 拇指；f=2 食指；f=3 中指；f=4 无名指；f=5 小指

    syms l   [5 5] positive
    syms bet [1 5] real
    syms gam [1 5] real
    syms the [2 5] real

    S = sym(zeros(6,3,5));
    r3_all = sym(zeros(3,5));

    %% 1) 拇指
    st1 = [-sin(gam(1)); -cos(gam(1)); 0];
    rt1 = [-l(1,1)*cos(bet(1)-gam(1))*cos(gam(1));
            l(1,1)*cos(bet(1)-gam(1))*sin(gam(1));
            0];
    St1 = [st1; cross(rt1, st1)];

    st2 = [0;0;1];
    rt2 = [-l(3,1)*cos(gam(1)) + l(2,1)*sin(gam(1)) - l(1,1)*cos(bet(1));
            l(3,1)*sin(gam(1)) + l(2,1)*cos(gam(1)) + l(1,1)*sin(bet(1));
            0];
    St2 = [st2; cross(rt2, st2)];

    st3 = st2;
    rt3 = [-l(4,1)*cos(gam(1)-the(1,1)) - l(3,1)*cos(gam(1)) + l(2,1)*sin(gam(1)) - l(1,1)*cos(bet(1));
            l(4,1)*sin(gam(1)-the(1,1)) + l(3,1)*sin(gam(1)) + l(2,1)*cos(gam(1)) + l(1,1)*sin(bet(1));
            0];
    St3 = [st3; cross(rt3, st3)];

    S(:,:,1) = [St1, St2, St3];
    r3_all(:,1) = rt3;   % 关键：记录拇指 r3（你这里变量名是 rt3）

    %% 2) 其余四指（2~5）
    sgn_x = [NaN, +1, +1, -1, -1];
    sgn_y = [NaN, +1, +1, -1, -1];

    for f = 2:5
        g   = gam(f);
        b   = bet(f);
        th1 = the(1,f);
        th2 = the(2,f);

        l1 = l(1,f); l2 = l(2,f); l3 = l(3,f); l4 = l(4,f);

        s1 = [ sgn_x(f)*sin(g);  cos(g); 0];

        A1 = (l1*cos(b - g) + l2);
        A2 = (l1*cos(b - g) + l2 + l3*cos(th1));
        A3 = (l1*cos(b - g) + l2 + l3*cos(th1) + l4*cos(th1 + th2));

        % 第1关节
        r1 = [ -A1*cos(g);
                sgn_y(f)*A1*sin(g);
                0];
        S1 = [s1; cross(r1, s1)];

        % 第2关节
        r2 = [ -A2*cos(g);
                sgn_y(f)*A2*sin(g);
                l3*sin(th1)];
        S2 = [s1; cross(r2, s1)];

        % 第3关节
        r3 = [ -A3*cos(g);
                sgn_y(f)*A3*sin(g);
                l3*sin(th1) + l4*sin(th1 + th2)];
        S3 = [s1; cross(r3, s1)];

        S(:,:,f) = [S1, S2, S3];
        r3_all(:,f) = r3;   % 关键：记录该指 r3
    end
end