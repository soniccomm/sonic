% arfidata = arfidata(:,:,12:end-1);dir = 0;
% i=800;
function [dirdata] = direct_filter(arfidata,dir)
[row,col,Frames] = size(arfidata);
mask = zeros(col,Frames);
mask(1:floor(col/2),1:floor(Frames/2))=1;
mask(floor(col/2)+1:end,floor(Frames/2)+1:end)=1;
if(dir==0)
    mask = flipud(mask);
end
dirdata = zeros(col,Frames,row);
temp = permute(arfidata,[2,3,1]);
for i = 1:row
    X = fft2(temp(:,:,i));
    Y = X.*mask;
    y = ifft2(Y);
    dirdata(:,:,i) = real(y);
end
dirdata = permute(dirdata,[3,1,2]);
end