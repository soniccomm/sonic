function iqdata = BProcessARFI(src, fs,c,scan,probe,para,dscflag)
[pts ,lines]= size(src);
image_depth = pts*(c/fs/2);
iqdata = Demodulation(src,para.demo_depth,para.demo_value,fs,c);
% iqdata = Filter(iqdata,para.filtertype, para.filterorder, para.filtercoef);