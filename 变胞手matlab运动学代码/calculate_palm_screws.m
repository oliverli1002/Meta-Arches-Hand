function [Sl1_num,Sl2_num] = calculate_palm_screws(Sl1,Sl2,theta)
%{
该函数用于生成手掌关节旋量的数值解。传入两支链旋量系Sl1,Sl2，手掌关节变量theta；
传出两支链旋量系数值解Sl1_num,Sl2_num。
%}

N = size(theta,2);
syms the [1 6] real
fSl1 = matlabFunction(Sl1, 'Vars', {the});
fSl2 = matlabFunction(Sl2, 'Vars', {the});
Sl1_num = zeros(6,3,N);
Sl2_num = zeros(6,3,N);
for k = 1:N
    th = theta(:,k).';
    Sl1_num(:,:,k) = fSl1(th);
    Sl2_num(:,:,k) = fSl2(th);
end
end