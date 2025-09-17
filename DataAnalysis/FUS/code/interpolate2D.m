

function scanInt=interpolate2D(atlas,scanNoperm)

scan=scanNoperm;

dz=scan.VoxelSize(1);
dx=scan.VoxelSize(2);


dzint=atlas.VoxelSize(1);
dxint=atlas.VoxelSize(2);


[nz,nx]=size(scan.Data);

n1x=round((nx-1)*dx/dxint)+1;
n1z=round((nz-1)*dz/dzint)+1;

[Xq,Yq] = meshgrid( (0:n1x-1)*dxint/dx+1,(0:n1z-1)*dzint/dz+1 );
ai=interp2(scan.Data,Xq,Yq,'linear',0);

scanInt.Data=ai;
scanInt.VoxelSize=atlas.VoxelSize;
scanInt.Direction=scan.Direction;
end
