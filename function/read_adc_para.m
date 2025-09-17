function [fs,prf,sampleNum,scanLine,imageDepth,focus,cstartoffset,frame_nums,NumsPerFile,steer,scan] = read_adc_para(filename,wavetype)

% 打开文件
fileID = fopen(filename, 'r');
if fileID == -1
    error('无法打开文件！');
end


line = fgetl(fileID);
frame_nums = str2double(regexp(line, '\d+', 'match', 'once'));

line = fgetl(fileID);
prf = str2double(regexp(line, '\d+', 'match', 'once'));


line = fgetl(fileID);
NumsPerFile = str2double(regexp(line, '\d+', 'match', 'once'));

line = fgetl(fileID);
fs = str2double(regexp(line, '\d+', 'match', 'once'));

line = fgetl(fileID);
sampleNum = str2double(regexp(line, '\d+', 'match', 'once'));

 
line = fgetl(fileID);
scanLine = str2double(regexp(line, '[\d.]+', 'match', 'once'));


line = fgetl(fileID);
imageDepth = str2double(regexp(line, '[\d.]+', 'match', 'once'));



line = fgetl(fileID);
match = regexp(line, 'steer: (.*)', 'tokens', 'once');
if ~isempty(match)
    temp = str2double(strsplit(match{1}));
    steer = temp(find(~isnan(temp)));
    
else
    error('未找到 steer 数据！');
end



line = fgetl(fileID);
focus = str2double(regexp(line, '[\d.]+', 'match', 'once'));


 if(strcmp(wavetype,'focus_wave'))
    line = fgetl(fileID);
    match = regexp(line, 'start_x step_x start_z step_z: (.*)', 'tokens', 'once');
    if ~isempty(match)
        xyzs = str2double(strsplit(match{1}));
        xyz = xyzs(find(~isnan(xyzs)));
        scan.start_x = xyz(1,1:4:scanLine*4);
        scan.step_x = xyz(1,2:4:scanLine*4);
        scan.start_z = xyz(1,3:4:scanLine*4);
        scan.step_z = xyz(1,4:4:scanLine*4);
    else
        error('未找到 strat_x step_x strat_z step_z 数据！');
    end
 else
    line = fgetl(fileID);
    match = regexp(line, 'start_x step_x start_z step_z: (.*)', 'tokens', 'once');
    if ~isempty(match)
        xyzs = str2double(strsplit(match{1}));
        xyz = xyzs(find(~isnan(xyzs)));
        scan.start_x = xyz(1,1:4:scanLine*4);
        scan.step_x = xyz(1,2:4:scanLine*4);
        scan.start_z = xyz(1,3:4:scanLine*4);
        scan.step_z = xyz(1,4:4:scanLine*4);
    else
        error('未找到 strat_x step_x strat_z step_z 数据！');
    end


 end


line = fgetl(fileID);
match = regexp(line, 'cstartoffset: (.*)', 'tokens', 'once');
if ~isempty(match)
    temp = str2double(strsplit(match{1}));

    cstartoffset  = temp(find(~isnan(temp)));
else
    error('未找到 cstartoffset 数据！');
end

% % 关闭文件
fclose(fileID);

