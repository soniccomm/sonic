% clear;clc
% filename = 'D:\shear_wave\ARFI0912\ARFI\20250912174110\Param.txt';
% wavetype ='plane_wave';
function [fs,sampleNum,imageDepth,focus,cstartoffset,frame_nums,NumsPerFile,steer,scanLine,Ref_Frame_Nums,Track_Frame_Nums,ARFI_Focus_Num,ARFI_tx_focus_depth] = arfi_adc_para(filename,wavetype)

% 打开文件
fileID = fopen(filename, 'r');
if fileID == -1
    error('无法打开文件！');
end


line = fgetl(fileID);
frame_nums = str2double(regexp(line, '\d+', 'match', 'once'));

line = fgetl(fileID);
NumsPerFile = str2double(regexp(line, '\d+', 'match', 'once'));

line = fgetl(fileID);
fs = str2double(regexp(line, '\d+', 'match', 'once'));

line = fgetl(fileID);
sampleNum = str2double(regexp(line, '\d+', 'match', 'once'));

line = fgetl(fileID);
imageDepth = str2double(regexp(line, '[\d.]+', 'match', 'once'));

line = fgetl(fileID);
scanLine = str2double(regexp(line, '[\d.]+', 'match', 'once'));

line = fgetl(fileID);
steer_num = str2double(regexp(line, '[\d.]+', 'match', 'once'));

line = fgetl(fileID);
match = regexp(line, 'steer: (.*)', 'tokens', 'once');
if ~isempty(match)
    temp = str2double(strsplit(match{1}));
    if(strcmp(wavetype,'focus_wave'))
        steer = temp(~isnan(temp));
    else
        temp = temp(~isnan(temp));
        steer = temp(1:steer_num);
    end
else
    error('未找到 steer 数据！');
end



line = fgetl(fileID);
focus = str2double(regexp(line, '[\d.]+', 'match', 'once'));


if(strcmp(wavetype,'focus_wave'))
    line = fgetl(fileID);
    match = regexp(line, 'start_x step_x start_z step_z: (.*)', 'tokens', 'once');
    if ~isempty(match)
        xyz = str2double(strsplit(match{1}));
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
    cstartoffset  = temp(1,1:scanLine);
else
    error('未找到 cstartoffset 数据！');
end

line = fgetl(fileID);
Ref_Frame_Nums = str2double(regexp(line, '[\d.]+', 'match', 'once'));

line = fgetl(fileID);
Track_Frame_Nums = str2double(regexp(line, '[\d.]+', 'match', 'once'));

line = fgetl(fileID);
ARFI_Focus_Num = str2double(regexp(line, '[\d.]+', 'match', 'once'));

line = fgetl(fileID);
match = regexp(line, 'ARFI_tx_focus_depth: (.*)', 'tokens', 'once');
if ~isempty(match)
    temp = str2double(strsplit(match{1}));
    temp = temp(~isnan(temp));
    ARFI_tx_focus_depth = temp(1:ARFI_Focus_Num);
else
    error('未找到 steer 数据！');
end
% % 关闭文件
fclose(fileID);

