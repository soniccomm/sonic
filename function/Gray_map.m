function out = Gray_map(idx)
%  Function: Grayscale Mapping
load graymap.mat
if(idx ==1)
    out = graymap(:,1);
elseif(idx ==2)
    out = graymap(:,2);
end
end


