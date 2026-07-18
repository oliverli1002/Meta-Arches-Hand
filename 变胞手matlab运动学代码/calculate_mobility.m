function m = calculate_mobility(f,k,Sr_mul,Sr)
%该函数用于计算环路机构活动度
m = sum(f)-6*(k-1)+size(Sr_mul,2)-rank(Sr);
end