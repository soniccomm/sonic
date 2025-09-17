function out = Interp(a,b,c,d)
% Function: Linear interpolation
if(a(end)<c)
    a = [a,c];
    b = [b,b(end)];
end
if(a(1)>0)
    a = [0,a];
    b = [b(1),b];
end
target_a = linspace(0,c,d); 

out = interp1(a,b,target_a);
end

