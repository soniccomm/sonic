function out = Tint_map(idx)
%  Function: Pseudo color mapping
load tintmap.mat
if(idx ==1)
    out = tintmap(:,:,:,1);
elseif(idx ==2)
    out = tintmap(:,:,:,2);
end
end
