function scanfusRej =outlier_filter(scanfus)

[~,~,nt,nz]=size(scanfus.Data);
if(nt==1)
    scanfusRej = scanfus;  
    return;
end

% average the image and normalize by the median in each plane
% this value must be "stable" during all the acquisition.
s=squeeze(mean(mean(scanfus.Data)))';
for iz=1:nz
    s(iz,:)=s(iz,:)./median(s(iz,:));
end

N=nz*nt;

% Important: the movement noise is always > 0 i.e outliers are in the
% positive part of the distribution. We compute the sigma with the low part
% of the distribution that is not affected by the outliers
sNoNoise=s(s<1); 
sigma=sqrt(mean((sNoNoise(:)-1).^2));
% sugest a threshold of 3 sigma
threshold=1+sigma*3;
% compute percent of rejencted images
outliers=s>threshold;
Nrejected=sum( outliers(:));

% display results
% figure;
% 
% % histogram 
% subplot(2,1,1)
% hold on
% [ha,hb]=hist(s(:),100);
% bar(hb,ha);  
% plot(hb, exp(-0.5*((hb-1)/sigma).^2)*(N-Nrejected)*(hb(2)-hb(1))/(sigma*sqrt(2*pi)) )
% plot([threshold threshold],[0 max(ha)/2],'r');
% txt=sprintf(' Threshold: %.1f\n Rejection: %.1f%%',threshold,Nrejected/N*100);
% text(double(threshold),max(ha)/2.3,txt)
% title('Intensity distribution');
% xlabel('Normalized intensity');
% ylabel('Number of images')
% hold off
% 
% % outliers position
% subplot(2,1,2)
% imagesc(1-outliers); colormap(gray);
% title('Rejected images');
% xlabel('time');
% ylabel('planes')



accepted=1-outliers;

scanfusRej=scanfus;
time=[1:nt];
for iz=1:nz
    timeAccepted=find(accepted(iz,:));
    DataAccepted= squeeze(scanfus.Data(:,:,timeAccepted,iz));
    DataAccepted= permute(DataAccepted,[3,1,2]);
    DataInterp= interp1(timeAccepted,DataAccepted,time,'linear','extrap');
    DataInterp = permute(DataInterp,[2,3,1]);
    scanfusRej.Data(:,:,:,iz)=DataInterp;  
end


end