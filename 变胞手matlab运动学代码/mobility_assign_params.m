function [Sl1_num, Sl2_num] = mobility_assign_params(Sl1, Sl2, alpha_val, theta_val)


vars   = [sym('alpha',[1 6]), sym('theta',[1 6])];
values = [alpha_val, theta_val];

Sl1_num = subs(Sl1, vars, values);
Sl2_num = subs(Sl2, vars, values);
Sl1_num = double(Sl1_num);
Sl2_num = double(Sl2_num);
end
