function [Rx ,Revpt,Revdepth]= SampleInfo(para,imagedepth)
%  Function:  Calculate the number of sampling points according to the depth required by the user.
%             An additional 0.0015cm will be artificially added during the actual sampling process.
Rx.fs =   para.Tx.fs;
ptnum = round((imagedepth+0.0015)*para.Tx.fs*2/para.Tx.sos);
Revpt = round(ptnum/64)*64;
Revdepth  =  Revpt* para.Tx.sos/( para.Tx.fs*2);
Rx.ImageDepth  =  imagedepth;
Rx.sample_num =  round(imagedepth*para.Tx.fs*2/para.Tx.sos);
Rx.sos = para.Tx.sos;
if(Rx.sample_num>Revpt)
    Rx.sample_num  = Revpt;
end
end
