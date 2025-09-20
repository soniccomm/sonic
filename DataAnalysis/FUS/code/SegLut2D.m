

function lut = segLut2D(Transf,atlas,fusData)     



regions=atlas.Regions;

tform=affine2d(Transf.M);

[nz,nx]=size(regions);
[X,Z] = meshgrid((0:nx-1),(0:nz-1));
[Xt,Zt]=transformPointsInverse(tform,X,Z);

% adjust size of the mesh 
dataperm= fusData;
Xt=Xt*atlas.VoxelSize(1)/dataperm.VoxelSize(1)+1;
Zt=Zt*atlas.VoxelSize(2)/dataperm.VoxelSize(2)+1;

% nearest point "low corner" 
xe=floor(Xt);
ze=floor(Zt);

dx=Xt-xe;
dz=Zt-ze;


% linear interpolation coefficients
C00=(1-dx).*(1-dz);
C01=(1-dx).*(dz  );
C10=(dx  ).*(1-dz);
C11=(dx  ).*(dz  );

nreg=max(atlas.Regions(:));

% mark right hemisphere 
nt2=round(size(regions,2)/2);
regions(:,1:nt2)=nreg+regions(:,1:nt2);
[regSort,ind]=sort(regions(:));   % sort is faster than using find
regSort(end+1)=nreg*2+1;          % last point to stop.

[nzr,nxr,~]=size(dataperm.Data);
cum=zeros(nzr,nxr,'single');
lutCoef=cell(nreg*2,1);
lutInd=cell(nreg*2,1);
i=1;
for ireg=1:nreg*2
    
    while regSort(i)==ireg
        x0=xe(ind(i));
        z0=ze(ind(i));
           
        if(x0>0&&z0>0&&x0<nxr&&z0<nzr&&x0<nx&&z0<nz)         
            cum(z0,x0  )= cum(z0,x0  ) + C00(z0,x0);
            cum(z0,x0+1)= cum(z0, x0+1) + C01(z0,x0);
            cum(z0+1,x0  )= cum(z0+1, x0  ) + C10(z0,x0);
            cum(z0+1,x0+1)= cum(z0+1,  x0+1) + C11(z0,x0);
        end
        i=i+1;
    end
    
    indDest=find(cum>0);
    lutCoef{ireg}=cum(indDest);
    lutInd{ireg}=indDest;
    cum(indDest)=0;         %reset cum
end

lut.ind=lutInd;
lut.Coef=lutCoef;
lut.nregion=nreg;
lut.Direction=atlas.Direction;
end


