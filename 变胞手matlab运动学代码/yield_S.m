function S = yield_S(s,r)
%该函数用于构造旋量S。传入旋量轴线s与位置向量r，传出单位旋量S。

S = [s;cross(r,s)];
end