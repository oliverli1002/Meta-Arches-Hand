function R =  yield_R(s,theta)
%该函数用于输出绕S轴线旋转theta的旋转矩阵（so(3)->SO(3)）

As = [0 -s(3) s(2);s(3) 0 -s(1);-s(2) s(1) 0]; %生成输入向量的反对称矩阵
R = eye(3)+sin(theta)*As+(1-cos(theta))*As*As;%罗德里格斯公式
% R = simplify(real(R), 'Steps', 50);

end