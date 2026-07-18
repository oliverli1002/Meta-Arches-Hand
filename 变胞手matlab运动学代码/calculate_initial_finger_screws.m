function Sf_ini = calculate_initial_finger_screws(L, gamma, Sf)
%CALCULATE_INITIAL_FINGER_SCREWS
% 将手指符号旋量系 Sf(6×3×5) 用给定的设计参数 L、gamma 数值化，
% 得到初始位置下的数值旋量轴线 Sf_ini(6×3×5)。
%
% 输入：
%   L     : 5×5 double（每列对应一指），其中前4行用于 l(1..4,f)
%   gamma : 5×5 double（每列对应一指）
%           gamma(1,:)=bet1..bet5
%           gamma(2,:)=gam1..gam5
%           gamma(3,:)=the1_1..the1_5
%           gamma(4,:)=the2_1..the2_5
%   Sf    : 6×3×5 sym，由 yield_finger_screws() 生成
%
% 输出：
%   Sf_ini: 6×3×5 double

    arguments
        L double {mustBeReal, mustBeFinite}
        gamma double {mustBeReal, mustBeFinite}
        Sf sym
    end

    assert(isequal(size(L), [5,5]),     'L 必须是 5×5。');
    assert(isequal(size(gamma), [5,5]), 'gamma 必须是 5×5。');
    assert(isequal(size(Sf), [6,3,5]),  'Sf 必须是 6×3×5 的 sym 数组。');

    % --------- 定义与 yield_finger_screws 相同名字/结构的符号变量 ----------
    % 注意：这里的 syms 名字必须和 Sf 里用的一致（bet, gam, the, l）
    syms l   [5 5] real
    syms bet [1 5] real
    syms gam [1 5] real
    syms the [2 5] real

    % --------- 组装替换表（old -> new） ----------
    % L 只对应 l(1..4,:), 第5行即使给了也不用于 Sf
    old = [ bet,                    gam,                    reshape(l(1:4,:),1,[]), reshape(the(1,:),1,[]), reshape(the(2,:),1,[]) ];
    new = [ gamma(1,:),             gamma(2,:),             reshape(L(1:4,:),1,[]), gamma(3,:),             gamma(4,:)             ];

    % --------- 代入并转为 double ----------
    Sf_sub = subs(Sf, old, new);
    Sf_ini = double(Sf_sub);
end