function NR = yield_NR(R)
%该函数用旋转矩阵R生成有限位移旋量矩阵的旋转部分NR

NR = blkdiag(R,R);

end