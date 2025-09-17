function [emit_line,rev_line] = FsJsLineLoc(Probe,lineN)
%  Function:     Calculate the position of the transmitting line and receiving line
%  Parameters:   Probe      ：    Probe parameters, including array pitch and array number            
%                lineN      ：    number of scan lines
%
%  Return：      emit_line  ：    The position of the transmitting line
%                rev_line   ：    The position of the receiving line

pitch = Probe.element_pitch;
ele_N = Probe.element_num;
ele_L = pitch*(ele_N-1);
if(lineN==1)
    emit_line.x  =  pitch*0.5;
    emit_line.y  =  zeros(1,length(emit_line.x));
    emit_line.z  =  zeros(1,length(emit_line.x));
        emit_line.theta  =  zeros(1,length(emit_line.x));
    rev_line = emit_line;
else
    dx = ele_L/(lineN-1);
    EmitN = round(ele_L/dx+1);
    emit_line.x  = (0:EmitN-1)*dx-(EmitN-1)/2*dx;
    emit_line.y  =  zeros(1,length(emit_line.x));
    emit_line.z  =  zeros(1,length(emit_line.x));
        emit_line.theta  =  zeros(1,length(emit_line.x));
    rev_line = emit_line;
end