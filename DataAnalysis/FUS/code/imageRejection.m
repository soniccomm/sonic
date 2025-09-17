function scanfusRej=imageRejection(scanfus,outliers,method)

if nargin==2
    method='linear';
end
[~,~,nz,nt]=size(scanfus.Data);

accepted=1-outliers;

scanfusRej=scanfus;
time=[1:nt];
for iz=1:nz
    timeAccepted=find(accepted(iz,:));
    DataAccepted= squeeze(scanfus.Data(:,:,iz,timeAccepted));
    DataAccepted= permute(DataAccepted,[3,1,2]);
    DataInterp= interp1(timeAccepted,DataAccepted,time,method,'extrap');
    DataInterp = permute(DataInterp,[2,3,1]);
    scanfusRej.Data(:,:,iz,:)=DataInterp;  
end

end