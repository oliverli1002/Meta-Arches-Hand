function [H_palm_num, H_palm_sym] = calculate_palm_H(Sl1, Sl2, theta)
%CALCULATE_PALM_H 先构造手掌齐次变换矩阵解析式，再代入 theta 得数值
%
% 输入：
%   Sl1   : 6×3 (或 6×m，至少用到(:,1:3))，可为 sym 或 double
%   Sl2   : 6×3 (至少用到(:,2:3))，可为 sym 或 double
%   theta : 6×N 数值（th(1..6) 对应你原函数里的 th(1),th(2),th(3),th(5),th(6)）
%
% 输出：
%   H_palm_num : 4×4×5×N 数值
%   H_palm_sym : 4×4×5   符号解析式（以 th1..th6 为变量）
%   F          : 函数句柄，H = F(th) 其中 th 为 6×1

    % ---------- 1) 构造解析解（只做一次）----------
    syms the [6 1] real;

    H_Lb = yield_H(Sl2(:,3), the(6));
    H_Rb = H_Lb;
    H_Mb = H_Lb * yield_H(Sl2(:,2), the(5));
    H_Ib = H_Mb;
    H_Tb = yield_H(Sl1(:,1), the(1)) * yield_H(Sl1(:,2), the(2)) * yield_H(Sl1(:,3), the(3));

    H_palm_sym = sym(zeros(4,4,5));
    H_palm_sym(:,:,1) = H_Tb;
    H_palm_sym(:,:,2) = H_Ib;
    H_palm_sym(:,:,3) = H_Mb;
    H_palm_sym(:,:,4) = H_Rb;
    H_palm_sym(:,:,5) = H_Lb;

    % 导出数值函数：输入 6×1 的 th，输出 4×4×5 的 H
    F = matlabFunction(H_palm_sym, 'Vars', {the});

    % ---------- 2) 代入 theta 得数值（向量化每一帧）----------
    N = size(theta,2);
    H_palm_num = zeros(4,4,5,N);

    for k = 1:N
        H_palm_num(:,:,:,k) = F(theta(:,k)); 
    end
end