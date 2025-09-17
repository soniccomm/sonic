function [value0,value1] = linearInterp(a,b,interpN)

n = numel(a);
a_step = (a(end) - a(1)) / (interpN - 1);

value0 = zeros(1, interpN);
value1 = zeros(1, interpN);

for i = 1:interpN
    value0(i) = a(1) + (i - 1) * a_step;
end

% 线性插值
for i = 1:interpN

    for j = 1:n-1
        if value0(i) >= a(j) && value0(i) <= a(j+1)

            value1(i) = b(j) + (b(j+1) - b(j)) * (value0(i) - a(j)) / (a(j+1) - a(j));
            break;
        end
    end
end

