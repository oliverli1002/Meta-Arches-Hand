function [Sl1_ini, Sl2_ini] = calculate_initial_palm_screws(Sl1, Sl2, alpha, q0)
%CALCULATE_INITIAL_PALM_SCREWS
% 将包含关节变量 the(1:6) 与参数 alp(1:6) 的符号旋量 Sl1/Sl2 数值化，
% 并在给定初始关节值 q0、设计参数 alpha 处求值。
%
% 用法：
%   [Sl1_ini, Sl2_ini] = calculate_initial_palm_screws(Sl1, Sl2, alpha);          % q0 默认为全0
%   [Sl1_ini, Sl2_ini] = calculate_initial_palm_screws(Sl1, Sl2, alpha, 0);       % 所有关节变量取0
%   [Sl1_ini, Sl2_ini] = calculate_initial_palm_screws(Sl1, Sl2, alpha, zeros(1,6));
%
% 输入：
%   Sl1, Sl2 : 符号表达式（可包含 the(1:6), alp(1:6) 的子集）
%   alpha    : 1×6 double，设计参数
%   q0       : 标量或 1×6 double，初始关节角（默认 0）
%
% 输出：
%   Sl1_ini, Sl2_ini : 在 (q0, alpha) 处的数值结果
%   fSl1, fSl2       : matlabFunction 生成的函数句柄（可选）

    if nargin < 4 || isempty(q0)
        q0 = 0;
    end
    if nargin < 3 || isempty(alpha)
        error('必须传入 alpha（1×6）。');
    end

    % ---- 标准化输入 ----
    alpha = double(alpha(:).');                 % 1×6
    assert(numel(alpha) == 6, 'alpha 必须是 1×6。');

    if isscalar(q0)
        q0 = repmat(double(q0), 1, 6);          % 1×6
    else
        q0 = double(q0(:).');                   % 1×6
        assert(numel(q0) == 6, 'q0 必须是标量或 1×6。');
    end

    % ---- 明确声明符号变量顺序（避免 symvar 顺序不确定）----
    syms the [1 6] real
    syms alp [1 6] real
    theVars = the;          % [the1..the6]
    alpVars = alp;          % [alp1..alp6]

    % ---- 找出 Sl1/Sl2 实际用到了哪些变量，并按固定顺序组织 ----
    v1 = symvar(Sl1);
    v2 = symvar(Sl2);

    useThe1 = ismember(theVars, v1);
    useAlp1 = ismember(alpVars, v1);
    vars1 = [theVars(useThe1), alpVars(useAlp1)];

    useThe2 = ismember(theVars, v2);
    useAlp2 = ismember(alpVars, v2);
    vars2 = [theVars(useThe2), alpVars(useAlp2)];

    % 对应的数值输入（顺序必须与 vars* 完全一致）
    vals1 = [q0(useThe1), alpha(useAlp1)];
    vals2 = [q0(useThe2), alpha(useAlp2)];

    % ---- 生成函数句柄并求值 ----
    fSl1 = matlabFunction(Sl1, 'Vars', {vars1});
    fSl2 = matlabFunction(Sl2, 'Vars', {vars2});

    Sl1_ini = fSl1(vals1);
    Sl2_ini = fSl2(vals2);
end