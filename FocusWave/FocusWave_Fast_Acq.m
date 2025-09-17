% 函数功能：
% 1、采集N帧ADC数据；
% 2、采集完成后做波束合成获取RF；
% 3、根据需求对RF数据进行后处理获取B图像数据；
% 4、保存ADC\RF\B数据，
% 5、运行过程中对RF数据做频谱分析

clear all
clc
close all
%% 加载当前环境变量
currentPath = pwd;
parentDir = fileparts(currentPath);
addpath(genpath(parentDir));
spectrum_flag = 0;                          %是否做频谱分析
bprocess_flag = 1;                          %是否对RF做后处理
imgshowflag = 1;                            %是否显示图像
%% 成像参数
frameN = 2;                                 %采集N帧数据
probe_name = 'L10-20';                        %探头名称
imagedepth = 0.03;                          %成像深度
focus_depth = 0.015;                         %聚焦深度
scanLine = 128;                             %扫描线数量
sos = 1540;                                 %声速
sysrate = 80e6;                             %采样率
channel = 128;                              %通道

% 发射波形
txwave.voltage = 30;                        %发射电压
txwave.pulse_num = 1;                       %发射周期
txwave.pulse_duration = 1;                  %占空比
txwave.pulse_frequency = 15e6;               %发射频率
txwave.pulse_Polarity = 0;                  %发射极性
% 发射孔径
tx_aper.max_Aper = 1;                     %最大发射孔径
tx_aper.min_Aper = 1;                      %最小发射孔径
tx_aper.fn_depth = [0 0.04];                %深度
tx_aper.fn_value = [4 4];                   %发射F#

% 接收孔径
rev_aper.max_Aper = 128;                    %最大接收孔径
rev_aper.min_Aper = 12;                     %最小接收孔径
rev_aper.fn_depth = [0 0.04];               %深度
rev_aper.fn_value = [1.1 1];                %接收F#
rev_aper.js_win = hamming(256);

%采集速度
prf = 2000;


%%        配置参数
probe =  Probe_para(probe_name);
AcqConfig.Probe = probe;
AcqConfig.Tx.channel = channel;
AcqConfig.Tx.fs = sysrate;
AcqConfig.Tx.sos = sos;
AcqConfig.Tx.focus_depth =   focus_depth;
%%        采样点数
[Rx,Revpt,Revdepth ]= SampleInfo(AcqConfig,imagedepth);


AcqConfig.Rx = Rx;
AcqConfig.Rx.Revpt = Revpt;
AcqConfig.Rx.Revdepth = Revdepth;
%%        发射、接收线位置
[emit_line,rev_line] = FsJsLineLoc(AcqConfig.Probe,scanLine);
AcqConfig.Tx.emit_line = emit_line;
AcqConfig.Rx.rev_line = rev_line;

%%        发射孔径
AcqConfig.Tx.aperture = Aperature(tx_aper, AcqConfig.Tx.focus_depth,probe,channel);
AcqConfig.Rx.aperture = rev_aper;

%%        接收孔径、变迹
AcqConfig.Rx.aperture = rev_aper;

%%        发射、接收
[tx_info,scanlist,cstartoffset ]= Tx_beamform(emit_line,AcqConfig,txwave);
AcqConfig.Tx.sequence = tx_info.sequence;
rx_info = Rev_Info(rev_line,cstartoffset,AcqConfig);
AcqConfig.Rx.sequence  = rx_info.sequence;



folderPath = uigetdir('', 'Select Folder to Save');
if folderPath ~= 0
    currentTime = datetime('now');
    currentTime.Format = 'yyyyMMddHHmmss';
    timeStr = char(currentTime);  % 将 datetime 转换为 char 类型的字符串
    fullPath = fullfile(folderPath, timeStr);
    if ~exist(fullPath,'dir')
        mkdir(fullPath);
    end

    [NumsPerFile] = DAQ_Acquisition(AcqConfig,scanlist,prf,frameN,fullPath );

    filename_para = strcat(fullPath, '\Param.txt');
    fileID = fopen(filename_para,'w');
    fprintf(fileID, 'frames: %d\n',frameN);
    fprintf(fileID, 'prf: %d\n',prf);   
    fprintf(fileID, 'numsPerFile: %d\n',NumsPerFile);
    fprintf(fileID, 'fs: %d\n',AcqConfig.Rx.fs);
    fprintf(fileID, 'sampleNum: %d\n',AcqConfig.Rx.Revpt);
    fprintf(fileID, 'scanLine: %f\n',size(AcqConfig.Tx.sequence,2));    
    fprintf(fileID, 'imageDepth: %f\n',imagedepth);    
    fprintf(fileID, 'steer: : %f\n',0);    
    fprintf(fileID, 'focus: %f\n',AcqConfig.Tx.focus_depth);
    fprintf(fileID, 'start_x step_x start_z step_z: '); 
    for i = 1:size(AcqConfig.Tx.sequence,2)
        fprintf(fileID, '%f ',AcqConfig.Rx.sequence{1, i}.start_x,AcqConfig.Rx.sequence{1, i}.step_x,...
            AcqConfig.Rx.sequence{1, i}.start_z,AcqConfig.Rx.sequence{1, i}.step_z);
    end
 
    fprintf(fileID, '\n');
    fprintf(fileID, 'cstartoffset: ');
    for i = 1:size(AcqConfig.Tx.sequence,2)
        fprintf(fileID, '%f ',AcqConfig.Rx.sequence{1, i}.cstartoffset);
    end
    fclose(fileID);
    disp("参数文件保存路径为："+filename_para)

end




