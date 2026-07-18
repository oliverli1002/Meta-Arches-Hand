function deg_double = symRad2DoubleDeg(sym_rad)
% SYMRAD2DOUBLEDEG 将符号(sym)类型的弧度矩阵转换为双精度(double)类型的角度矩阵
%
%   用法:
%       deg = symRad2DoubleDeg(sym_matrix)
%
%   输入:
%       sym_rad - 包含弧度值的 sym 类型向量或矩阵 (例如: [sym(pi), sym(pi/2)])
%
%   输出:
%       deg_double - 对应角度值的 double 类型矩阵
%
%   注意:
%       输入的 sym 矩阵必须是可以求值的（即只包含数字和常数，如 pi, sqrt(2)），
%       不能包含未定义的符号变量（如 q1, theta 等），否则 double() 转换会报错。

    % 1. 检查输入是否为 sym 类型，如果不是，给出提示但继续执行（兼容普通 double 输入）
    if ~isa(sym_rad, 'sym')
        warning('输入数据不是 sym 类型，将直接视为数值进行计算。');
    end

    % 2. 执行弧度转角度计算
    % 使用 sym(180)/sym(pi) 确保运算在符号域内进行，保持最高精度直到最后一步
    sym_deg = sym_rad * (sym(180) / sym(pi));

    % 3. 尝试将符号结果转换为 double 类型
    try
        % double() 函数会强制计算符号表达式的数值解
        deg_double = double(sym_deg);
    catch ME
        % 捕捉常见错误：如果符号表达式中含有未赋值的变量（如 x, q1），double() 会失败
        error(['转换失败！输入矩阵中包含无法求值的符号变量。' ...
               '请确保输入矩阵只包含数值型符号（如 pi, 3/4 等），' ...
               '而不是抽象变量（如 theta1）。错误信息: %s'], ME.message);
    end
end