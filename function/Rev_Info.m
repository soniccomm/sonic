function out = Rev_Info(rev_line,cstartoffset,para)
%  Function    :  calculates the starting position and step of the receiving lines
%  Parameters  :  rev_line      -   The location of the receiving lines
%                 cstartoffset  -   The time from the start of the transmission to the effective 
%                                   receipt of the data 
%                 para          -   includes probe parameters, sampling rate, and sound speed
%
%  Return:        out           -   The starting position and step of the receiving lines
probe = para.Probe;
sos = para.Tx.sos;
linenums = length(rev_line.x);
bf_interval = sos/para.Rx.fs/2;

for i = 1:linenums
    idx =  i;
    tmp_dist = abs(probe.element_pos.x - rev_line.x(i));
    center_idxs = find(tmp_dist == min(tmp_dist));
    center_idx = center_idxs(1);
    theta = probe.element_pos.theta(center_idx);

    out.sequence{idx}.step_x  = bf_interval*sin(theta);
    out.sequence{idx}.step_y = 0;
    out.sequence{idx}.step_z  = bf_interval*cos(theta);
    %接收起始点
    out.sequence{idx}.start_x = rev_line.x(i);
    out.sequence{idx}.start_y = rev_line.y(i);
    out.sequence{idx}.start_z = rev_line.z(i);
    out.sequence{idx}.cstartoffset = cstartoffset(i);


end

end





