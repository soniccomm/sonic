function  out = DTgc(src,seg_depth,seg_gain,global_gain,knobgain,tgcvalue,target_depth,sample_num)
%  Function: Add digital gain, including slider gain, knob gain, global gain, segment gain
%  Parameters:  src            -   input data                          
%               seg_depth      -   Depth corresponding to segment gain
%               seg_gain       -   The value corresponding to the segment gain
%               global_gain    -   global gain
%               knobgain       -   The value corresponding to the knob gain
%               tgcvalue       -   The value corresponding to slider gain
%               target_depth   -   Image Depth
%               sample_num     -   Sampling points corresponding to image depth
%
%  Return:      out            -   The data after gain process
          
target_gain = Interp(seg_depth,seg_gain,target_depth,sample_num);
target_knobgain = XuanNiuGain(knobgain);
bogan_gain = BoganTgc(tgcvalue,target_depth,sample_num);
gain = target_gain'+global_gain+target_knobgain+bogan_gain';
out =  src+gain*463.2040;
out(out>65535) = 65535;
out(out<0) = 0;
end

function  out = BoganTgc(tgcvalue,image_depth,sample_num)
%  Function:    Generate slider TGC gain (the range is -40~40dB)
%  Parameters:  tgcvalue       -   The value corresponding to slider gain (slider adjustment range is 0~255)                           
%               image_depth    -   Image Depth
%               sample_num     -   Sampling points corresponding to image depth
%
%  Return:      out            -   slider gain

tgcrange = 80;
boganNum = 6;
depth = linspace(0,image_depth,boganNum);
maxValue = 255;
db_value  = tgcvalue/maxValue*tgcrange-tgcrange/2;
pt_depth = linspace(0,image_depth,sample_num);
out = interp1(depth,db_value,pt_depth);

end
function out = XuanNiuGain(src)

% Function:     Calculate knob gain, the range is 0-100, the corresponding minimum and maximum db 
%               ranges are MinValue and MaxValue
% Parameters:   src  -   input data     
%
% Return:       out   -   knob gain

MaxValue = 50;
MinValue = -90;
ratio = src/100;
temp = ratio*(MaxValue-MinValue)+MinValue;
out = temp;
end

function out = Interp(a,b,c,d)
% Function: Linear interpolation
if(a(end)<c)
    a = [a,c];
    b = [b,b(end)];
end
if(a(1)>0)
    a = [0,a];
    b = [b(1),b];
end
target_a = linspace(0,c,d); 

out = interp1(a,b,target_a);
end
