function out = Aperature(para,depth,probe,channel)
%  Function: Calculate Aperture size
%  Parameters:  para      -   Aperture parameters, including depth and corresponding f number, 
%                             minimum aperture, maximum aperture 
%               depth     -   Focus depth  
%               probe     -   Probe parameters, including array pitch and array number
%
%  Return:      out       -   Aperture size
           
element_num = probe.element_num;
element_pitch = probe.element_pitch;
max_Aper = para.max_Aper;
min_Aper = para.min_Aper;
fn_depth = para.fn_depth;
fn_value = para.fn_value;
Max_Aper = min(min(channel,element_num),max_Aper);

fnumber = interp1(fn_depth, fn_value ,  depth , 'linear', fn_value(end));
out = round(depth/fnumber/element_pitch/2)*2;
out = min(max(min_Aper,out),Max_Aper);

end