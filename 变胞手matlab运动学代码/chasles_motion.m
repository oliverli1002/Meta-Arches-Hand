function S_new = chasles_motion(S,s,theta,d)
%{
该函数用于计算旋量的Chasles运动。第一个值为原旋量轴线，第二个值为旋转轴线，
第三个值为绕旋转轴线旋转的角度，第四个值为平移向量。该部分用于求关节旋量。
注意，若使用Chasles运动的方法计算各关节单位旋量，则相当于每一次运动都是
绕前一根杆件的局部坐标系进行的。
%}

%声明输入参数的默认值
    arguments
        S = [0;0;0;0;0;0] %S的默认值
        s = [0;0;0]; %s的默认值
        theta = 0; %theta的默认值
        d = [0;0;0]; %d的默认值
    end

R =  yield_R(s,theta);
NR = yield_NR(R);
Nt = yield_Nt(d);
S_new = Nt*NR*S;
% S_new = simplify(real(S_new),'Steps',50);


end