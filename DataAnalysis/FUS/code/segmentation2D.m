

function segmented= segmentation2D(Lut,scanfus)     

Data=scanfus.Data;
nt=size(Data,3);        

% normalization (optional can be commented)
m=mean(Data,3);
for it=1:nt         
   Data(:,:,it)=Data(:,:,it)./m;
end

[pl,pr]=projectLut3D(Data,Lut); 
segmented.Left=pl;
segmented.Right=pr;
end


function [pl,pr]=projectLut3D(data,Lut)
nr=Lut.nregion; 
[nx,ny,nt]=size(data);
nxy =nx*ny;
pl=zeros(nr,nt);
pr=zeros(nr,nt);
for ir=1:nr
    indL =Lut.ind{ir};
    coefL=Lut.Coef{ir};
    indR =Lut.ind{ir+nr};
    coefR=Lut.Coef{ir+nr};
    for it=1:nt
       pl(ir,it)=sum( data(indL+(it-1)*nxy).*coefL);
       pr(ir,it)=sum( data(indR+(it-1)*nxy).*coefR);
    end
end
end



