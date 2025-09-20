

function ras=register_Data(atlas,x,Transf)
Dint=interpolate2D(atlas,x);
T=affine2d(Transf.M);
ref=imref2d(Transf.size);
ras=imwarp(Dint.Data,T,'OutputView',ref);
end




 