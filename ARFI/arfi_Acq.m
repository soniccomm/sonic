% 函数功能：
% 1、连续采集N帧ADC数据；

clear all
clc
close all

currentPath = pwd;
parentDir = fileparts(currentPath);
addpath(genpath(parentDir));

%% 基本设置

savedataflag = 1;                           %是否保存数据
update_fre = 47;                            %图像刷新帧率


%% 成像参数

prf = 6000;                                 % prf
probe_name = 'L5-10';                         %探头名称    80M:'L10-20'    40M:'L5-10' 
imagedepth = 0.025;                          %成像深度（米）   80M:0.02m 
scanLine = 128;                             %扫描线数量
sysrate = 40e6;                             %采样率 20\40\80
pw_tx_angle  = [-4 0 4];               %平面波发射角度

sos = 1540;                                 %声速
channel = 128;                              %通道
% 发射波形
txwave.voltage = 60;                        %发射电压
txwave.pulse_num = 1;                       %发射周期
txwave.pulse_duration = 1;                  %占空比
txwave.pulse_frequency = 5e6;             %发射频率    80M:15e6   40M:7.5e6
txwave.pulse_Polarity = 0;                  %发射极性

% ARFI参数
Ref_Frame_Nums = 5;                         % 参考帧数量
Track_Frame_Nums = 50;                      % 跟踪帧数量
Ex_Aperture = 1:64;                         % 孔径
ARFI_Pulse_Num = 700;                       % 长脉冲周期数量
ARFI_Pulse_Frequency = 5e6;                 % 长脉冲频率
%% 配置参数
probe =  Probe_para(probe_name);
AcqConfig.Probe = probe;
AcqConfig.Tx.channel = channel;
AcqConfig.Tx.fs = sysrate;
AcqConfig.Tx.sos = sos;
AcqConfig.Tx.Steering = pw_tx_angle;
ARFI_tx_focus_depth = [0.010 0.015 0.02];     %声辐射力焦点
AcqConfig.Rx.fs = sysrate;
AcqConfig.Rx.sos = sos;

%% 采样点数

[Rx,Revpt,Revdepth ]= SampleInfo(AcqConfig,imagedepth);
sampt = round(imagedepth/(AcqConfig.Tx.sos/AcqConfig.Tx.fs/2));

AcqConfig.Rx = Rx;
AcqConfig.Rx.Revpt =Revpt;
AcqConfig.Rx.Revdepth = Revdepth;


revloc.z_num =  sampt;
revloc.start_z =  AcqConfig.Probe.image_start ;
revloc.step_z = AcqConfig.Tx.sos/AcqConfig.Tx.fs/2;


revloc.start_x = AcqConfig.Probe.element_pos.x(1);
revloc.step_x = (AcqConfig.Probe.element_pos.x(end)-AcqConfig.Probe.element_pos.x(1))/(scanLine-1);
revloc.x_num = scanLine;

AcqConfig.Rx.post_process_fs = AcqConfig.Tx.sos/revloc.step_z/2;
[tx_info,scanlist,rx_info]=  Tx_beamform_ARFI(pw_tx_angle,AcqConfig,txwave,revloc,ARFI_tx_focus_depth,Ref_Frame_Nums,Track_Frame_Nums,Ex_Aperture,ARFI_Pulse_Num,ARFI_Pulse_Frequency);
AcqConfig.Tx.sequence = tx_info.sequence;
ScanList = scanlist;
AcqConfig.Rx.sequence = rx_info.sequence;
%平面波都是一样的，先算好

startx = revloc.start_x;
startz = revloc.start_z;
setpx = revloc.step_x;
setpz = revloc.step_z;

Nx = revloc.x_num;
Nz = revloc.z_num;

x_axis = (0:setpx:(Nx-1) * setpx)+ startx;
z_axis = (0:setpz:(Nz-1) * setpz)+ startz;

AcqConfig.Rx.rev_line.x = x_axis;
AcqConfig.Rx.rev_line.z = z_axis;

[x_grid, z_grid] = meshgrid(x_axis,z_axis);
f_number = 1.5;
x_grid = reshape(x_grid,[Nz*Nx,1]);
z_grid = reshape(z_grid,[Nz*Nx,1]);


f_mask = zeros(Nx*Nz,probe.element_num);
for i = 1:probe.element_num
    f_mask(:,i) = z_grid./abs(x_grid - probe.element_pos.x(i))/2 > f_number;
end
AcqConfig.Rx.apod  = f_mask;

x_grid_all = single(repmat(x_grid,length(ScanList),1));
z_grid_all = single(repmat(z_grid,length(ScanList),1));

lasting_time = 0.1;                          %扫查时长（秒）
bfparams.Nx = Nx;
bfparams.Nz = Nz;
bfparams.x_axis = x_axis;
bfparams.z_axis = z_axis;
bfparams.x_grid = x_grid;
bfparams.z_grid = z_grid;
bfparams.x_grid_all = x_grid_all;
bfparams.z_grid_all = z_grid_all;
bfparams.scanLine = scanLine;
bfparams.update_fre = update_fre;
bfparams.lasting_time = lasting_time;

imgshowflag = 0;                            %是否显示图像
if savedataflag~=0
    folderPath = 'D:\ARFIdata';
    if folderPath ~= 0
        currentTime = datetime('now');
        currentTime.Format = 'yyyyMMddHHmmss';
        timeStr = char(currentTime);  % 将 datetime 转换为 char 类型的字符串
        fullPath = fullfile(folderPath, timeStr);
        if ~exist(fullPath,'dir')
            mkdir(fullPath);
        end
        disp("数据保存路径为："+fullPath)

    
        [NumsPerFile,File_nums,frameN] = DAQ_Acquisition_ARFI(AcqConfig,scanlist,prf,fullPath,imgshowflag,savedataflag,bfparams);

    
        filename_para = strcat(fullPath, '\Param.txt');
        fileID = fopen(filename_para,'w');
        fprintf(fileID, 'frames: %d\n',1);
        fprintf(fileID, 'numsPerFile: %d\n',NumsPerFile);
        fprintf(fileID, 'fs: %d\n',AcqConfig.Rx.fs);
        fprintf(fileID, 'sampleNum: %d\n',AcqConfig.Rx.Revpt);
        fprintf(fileID, 'imageDepth: %f\n',AcqConfig.Rx.Revdepth);
        fprintf(fileID, 'length: %f\n',size(AcqConfig.Tx.sequence,2));
        fprintf(fileID, 'steer_num: %d\n',size(AcqConfig.Tx.Steering,2));
        fprintf(fileID, 'steer: ');
        for i = 1:size(pw_tx_angle,2)
            fprintf(fileID, '%f ',pw_tx_angle(i));
        end
        fprintf(fileID, '\n');
        fprintf(fileID, 'focus: %f\n',-1);
        
        fprintf(fileID, 'cstartoffset: ');
        for i = 1:size(AcqConfig.Tx.sequence,2)
            fprintf(fileID, '%f ',AcqConfig.Rx.sequence{1, i}.cstartoffset);
        end
        fprintf(fileID, '\n');
        fprintf(fileID, 'Ref_Frame_Nums: %d\n',Ref_Frame_Nums);
        fprintf(fileID, 'Track_Frame_Nums: %d\n',Track_Frame_Nums);
        fprintf(fileID, 'ARFI_Focus_Num: %d\n',size(ARFI_tx_focus_depth,2));
        fprintf(fileID, 'ARFI_tx_focus_depth: ');
        for i = 1:size(ARFI_tx_focus_depth,2)
            fprintf(fileID, '%f ',ARFI_tx_focus_depth(i));
        end
        fprintf(fileID, '\n');
        fclose(fileID);
        disp("参数文件保存路径为："+filename_para)
    
    end

else
    fullPath = [];
    [NumsPerFile,File_nums,frameN] = DAQ_Acquisition_ARFI(AcqConfig,scanlist,prf,fullPath,imgshowflag,savedataflag,bfparams);
    
end



