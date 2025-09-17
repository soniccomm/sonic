% 函数功能：
% 1、连续采集N帧ADC数据；

clear all
clc
close all


currentPath = pwd;
parentDir = fileparts(currentPath);
addpath(genpath(parentDir));

%% 基本设置

lasting_time = 0.2;                          %扫查时长（秒）
imgshowflag = 1;                            %是否显示图像
savedataflag = 1;                           %是否保存数据
update_fre = 47;                            %图像刷新帧率



%% 成像参数

prf = 4000;                                 % prf
probe_name = 'L10-20';                       %探头名称    80M:'L10-20'    40M:'L5-10'
imagedepth = 0.03;                          %成像深度（米）   80M:0.02m
scanLine = 128;                             %扫描线数量
sysrate = 80e6;                             %采样率 20\40\80
pw_tx_angle  = [-5 -3 0 3 5];               %平面波发射角度

sos = 1540;                                 %声速
channel = 128;                              %通道
% 发射波形
txwave.voltage = 30;                        %发射电压
txwave.pulse_num = 1;                       %发射周期
txwave.pulse_duration = 1;                  %占空比
txwave.pulse_frequency = 15e6;             %发射频率    80M:15e6   40M:7.5e6
txwave.pulse_Polarity = 0;                  %发射极性


%% 配置参数
probe =  Probe_para(probe_name);
AcqConfig.Probe = probe;
AcqConfig.Tx.channel = channel;
AcqConfig.Tx.fs = sysrate;
AcqConfig.Tx.sos = sos;
AcqConfig.Tx.Steering = pw_tx_angle;
AcqConfig.Rx.fs = sysrate;
AcqConfig.Rx.sos = sos;

%% 采样点数

[Rx,Revpt,Revdepth ]= SampleInfo(AcqConfig,imagedepth);
sampt = round(imagedepth/(AcqConfig.Tx.sos/AcqConfig.Tx.fs/2));

AcqConfig.Rx = Rx;
AcqConfig.Rx.Revpt =Revpt;
AcqConfig.Rx.Revdepth = Revdepth;

AcqConfig.Rx.aperture.js_win = hamming(256)';
AcqConfig.Rx.aperture.fn_depth = [0 0.04];
AcqConfig.Rx.aperture.min_Aper = 16;
AcqConfig.Rx.aperture.max_Aper = 128;

AcqConfig.Rx.aperture.fn_value = [1.2 1];

revloc.z_num =  sampt;
revloc.start_z =  AcqConfig.Probe.image_start ;
revloc.step_z = AcqConfig.Tx.sos/AcqConfig.Tx.fs/2;


revloc.start_x = AcqConfig.Probe.element_pos.x(1);
revloc.step_x = (AcqConfig.Probe.element_pos.x(end)-AcqConfig.Probe.element_pos.x(1))/(scanLine-1);
revloc.x_num = scanLine;

AcqConfig.Rx.post_process_fs = AcqConfig.Tx.sos/revloc.step_z/2;
[tx_info,scanlist,rx_info]=  Tx_beamform_PlaneWave(pw_tx_angle,AcqConfig,txwave,revloc);
AcqConfig.Tx.sequence = tx_info.sequence;
ScanList = scanlist;
AcqConfig.Rx.sequence = rx_info.sequence;
%平面波成像区域

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

%解调低通滤波器
postpara.demo_value = txwave.pulse_frequency;
postpara.filtertype  = 'hamming';
postpara.filterorder = 128;
postpara.filtercoef = 0.15;



if savedataflag~=0
    folderPath = uigetdir('', 'Select Folder to Save');
    if folderPath ~= 0
        currentTime = datetime('now');
        currentTime.Format = 'yyyyMMddHHmmss';
        timeStr = char(currentTime);  % 将 datetime 转换为 char 类型的字符串
        fullPath = fullfile(folderPath, timeStr);
        if ~exist(fullPath,'dir')
            mkdir(fullPath);
        end
        disp("数据保存路径为："+fullPath)


    
        [NumsPerFile,File_nums,frameN] = DAQ_RealTime_PlaneWaveIQM(AcqConfig,postpara,scanlist,prf,lasting_time,update_fre,fullPath,1,1);


        filename_para = strcat(fullPath, '\Param.txt');
        fileID = fopen(filename_para,'w');
        fprintf(fileID, 'frames: %d\n',frameN);
        fprintf(fileID, 'prf: %d\n',prf);
        fprintf(fileID, 'numsPerFile: %d\n',NumsPerFile);
        fprintf(fileID, 'fs: %d\n',AcqConfig.Rx.fs);
        fprintf(fileID, 'sampleNum: %d\n',AcqConfig.Rx.Revpt);
        fprintf(fileID, 'scanLine: %d\n',length(AcqConfig.Rx.rev_line.x));    
        fprintf(fileID, 'imageDepth: %f\n',imagedepth);
        fprintf(fileID, 'steer: ');
        for i = 1:size(pw_tx_angle,2)
            fprintf(fileID, '%f ',pw_tx_angle(i));
        end
        fprintf(fileID, '\n');
        fprintf(fileID, 'focus: %f\n',-1);
        fprintf(fileID, 'start_x step_x start_z step_z: ');
        for i = 1:length(AcqConfig.Rx.rev_line.x)
            fprintf(fileID, '%f ',AcqConfig.Rx.rev_line.x(i),AcqConfig.Rx.sequence{1, 1}.step_x,...
                AcqConfig.Rx.sequence{1, 1}.start_z,AcqConfig.Rx.sequence{1, 1}.step_z);
        end
        fprintf(fileID, '\n');

        fprintf(fileID, 'cstartoffset: ');
        for i = 1:size(AcqConfig.Tx.sequence,2)
            fprintf(fileID, '%f ',AcqConfig.Rx.sequence{1, i}.cstartoffset);
        end
        fclose(fileID);
        disp("参数文件保存路径为："+filename_para)

    end

else
    fullPath = [];
    [NumsPerFile,File_nums,frameN] = DAQ_RealTime_PlaneWaveIQM(AcqConfig,postpara,scanlist,prf,lasting_time,update_fre,fullPath,0,1);

end



