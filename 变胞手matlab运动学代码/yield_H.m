function H = yield_H(S,theta)
%该函数用于输出绕旋量S轴线旋转与平移d后的齐次变换矩阵（se(3)->SE(3)）

S = S(:);%将输入旋量轴线转换成列向量
As = [0 -S(3) S(2);S(3) 0 -S(1);-S(2) S(1) 0]; %生成输入向量的反对称矩阵
E = [As S(4:6);zeros(1,3) 0];
H = eye(4)+sin(theta)*E+(1-cos(theta))*E^2;%罗德里格斯公式
% H = expm(theta*E);
% H = simplify(H);
end