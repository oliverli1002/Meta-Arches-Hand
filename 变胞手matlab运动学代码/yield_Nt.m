function Nt = yield_Nt(d)
%该函数用于输出沿d轴线平移的有限位移旋量矩阵的平移部分Nt

A = [0 -d(3) d(2);d(3) 0 -d(1);-d(2) d(1) 0]; %生成输入向量的反对称矩阵
Nt = [eye(3) zeros(3);A eye(3)];%生成有限位移旋量矩阵的平移部分Nt
Nt = simplify(sym(Nt));

end