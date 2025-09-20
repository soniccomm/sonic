
%%
function selectSegmented=selectBrainRegions(atlas,region_list,segmented)
D=readFileList(region_list,atlas.infoRegions);
selectSegmented.Left = select(D,segmented.Left );
selectSegmented.Right= select(D,segmented.Right);
end


function px=select(D,p)
[nz,nt]=size(p);
nr=length(D.parts);

px=zeros(nr,nt);
for ir=1:nr
    parts=D.parts{ir};
    nsp=length(parts);
    tmp=zeros(1,nt);
    for isp=1:nsp
        idx = parts(isp);
        if(idx<=nz)
            tmp=tmp+p(idx,:);
        end
    end
    px(ir,:)=tmp./(nsp+1e-10);

end

% normalize data as Z-score for visualization
for ir=1:nr
    px(ir,:)=px(ir,:)-mean(px(ir,:));
    px(ir,:)=px(ir,:)./(std(px(ir,:))+1e-10);
end

end


