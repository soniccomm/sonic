% 函数功能：
% 1、采集N帧ADC数据；
% 2、采集完成后做波束合成获取RF；
% 3、对RF数据进行后处理获取B图像数据；
% 4、保存ADC\RF\B数据，

clear all
clc
close all
% 加载当前环境变量
currentPath = pwd;
parentDir = fileparts(currentPath);
addpath(genpath(parentDir));
libpath = strcat(parentDir,'\lib\DAQ_SDK_C.dll');%添加库路径
bprocess_flag = 1;                           %是否对RF做后处理
imgshowflag = 1;                             %是否显示图像
savedataflag = 1;                            %是否保存图像
% 成像参数
frameN = 2;                                  %采集N帧数据
probe_name = 'L10-20';                        %探头名称

imagedepth = 0.03;                            %成像深度  m
focus_depth = 0.015;                          %聚焦深度  m
scanLine = 128;                              %扫描线数量
sos = 1540;                                  %声速    m/s
sysrate = 80e6;                              %采样率  支持10M 20M 40M 80M
channel = 128;                               %通道

% 发射波形
txwave.voltage = 35;                        %发射电压  v
txwave.pulse_num = 1;                       %发射周期
txwave.pulse_duration = 1;                  %占空比
txwave.pulse_frequency = 15e6;             %发射频率 MHz
txwave.pulse_Polarity = 0;                  %发射极性
% 发射孔径
tx_aper.max_Aper = 64;                      %最大发射孔径
tx_aper.min_Aper = 12;                      %最小发射孔径
tx_aper.fn_depth = [0 0.04];                %深度
tx_aper.fn_value = [4 4];                   %发射F#

% 接收孔径
rev_aper.max_Aper = 128;                    %最大接收孔径
rev_aper.min_Aper = 12;                     %最小接收孔径
rev_aper.fn_depth = [0 0.12];               %深度
rev_aper.fn_value = [1.2 1];                %接收F#
rev_aper.js_win = hamming(256);
% 后处理参数
postprocess.demo_depth = [0 0.04];          %解调深度
postprocess.demo_value = [15e6 15e6];     %解调频率
postprocess.dgain_global_value = -15;       %全局增益
% 分段增益
postprocess.dgain_depth = [0 0.0050 0.0100 0.0150 0.0200 0.0400];
postprocess.dgain_value = [0 0 0 0 0 0];
% 拨杆增益
postprocess.slider0 = 128;
postprocess.slider1 = 128;
postprocess.slider2 = 128;
postprocess.slider3 = 128;
postprocess.slider4 = 128;
postprocess.slider5 = 128;
% 旋钮增益
postprocess.knobgain = 60;
% 动态范围
postprocess.dynamic_range = 50;
% 空间平滑档位
postprocess.spatial_smooth_level = 1;
% fir滤波器阶数、系数、窗函数
postprocess.filterorder = 64;
postprocess.filtercoef = 0.12;
postprocess.filtertype = 'hamming';
postprocess.smooth_level = 1;
% 灰阶档位
postprocess.grayMapidx = 1;
% 伪彩档位
postprocess.timtMapidx = 2;
% 扫描变换
postprocess.dsc_height = 480;
postprocess.dsc_width = 640;

% 采集速度
prf = 3000;                               %PRF


%        配置参数
probe =  Probe_para(probe_name);
AcqConfig.Probe = probe;
AcqConfig.Tx.channel = channel;
AcqConfig.Tx.fs = sysrate;
AcqConfig.Tx.sos = sos;
AcqConfig.Tx.focus_depth =   focus_depth;
%        采样点数
[Rx,Revpt,Revdepth ]= SampleInfo(AcqConfig,imagedepth);

if(Revpt>3968)
    disp('The number of sampling points must be less than 3968 points,Please set the sound speed or imaging depth appropriately')
    return;
end
if(Revpt<500)
    disp('The number of sampling points must be more than 519 points,Please set the sound speed or imaging depth appropriately')
    return;
end
AcqConfig.Rx = Rx;
AcqConfig.Rx.Revpt = Revpt;
AcqConfig.Rx.Revdepth = Revdepth;
%        发射、接收线位置
[emit_line,rev_line] = FsJsLineLoc(AcqConfig.Probe,scanLine);
AcqConfig.Tx.emit_line = emit_line;
AcqConfig.Rx.rev_line = rev_line;

%        发射孔径
AcqConfig.Tx.aperture = Aperature(tx_aper, AcqConfig.Tx.focus_depth,probe,channel);
AcqConfig.Rx.aperture = rev_aper;

%        接收孔径、变迹
AcqConfig.Rx.aperture = rev_aper;

%        发射、接收
[tx_info,scanlist,cstartoffset ]= Tx_beamform(emit_line,AcqConfig,txwave);
AcqConfig.Tx.sequence = tx_info.sequence;
rx_info = Rev_Info(rev_line,cstartoffset,AcqConfig);
AcqConfig.Rx.sequence  = rx_info.sequence;
%        图像截取位置
startpt = floor(probe.image_start/(AcqConfig.Tx.sos/AcqConfig.Rx.fs/2));
if(startpt<1)
    startpt =1;
end
sampt = AcqConfig.Rx.sample_num;
endpt = startpt+sampt-1;
if( endpt>AcqConfig.Rx.Revpt)
    startpt = 1;
    endpt = sampt;
end
rfsize = endpt -startpt+1;
dev_manager = DAQ(AcqConfig,scanlist,libpath,AcqConfig.Rx.Revpt,prf);
% 将修改的属性发送到DAQ节点
disp("set DAQ ...");
res = dev_manager.set_DAQ(1);
if res==0
    disp("set DAQ ok");
else
    disp('DAQ setup failed. Please run the program again. If it still fails, please shut down and restart the device');
    System.GC.Collect();

    dev_manager.stop_sample;
    dev_manager.close_DAQ;
    return;
end

%     数据采集
disp("start sample ...");
res =  dev_manager.start_sample;
if res
    disp("start sample ok");
else
    disp('DAQ setup failed. Please run the program again. If it still fails, please shut down and restart the device');
    System.GC.Collect();

    dev_manager.stop_sample;
    dev_manager.close_DAQ;

    return;
end

disp("apply for frame_buf .NET memory ...");
frame_buf = NET.createArray("System.Int16",  AcqConfig.Rx.Revpt* AcqConfig.Tx.channel);
disp("apply for frame_buf .NET memory ok");

frame_nums = 1;
tx_num = 1;

while(frame_nums<=frameN )

    recv_data = zeros(AcqConfig.Rx.Revpt,min(AcqConfig.Tx.channel,AcqConfig.Probe.element_num),numel(AcqConfig.Tx.sequence));
    pre_frame_id = -1;
    elapsedTime = 0;
    tic;
    while tx_num <= numel(AcqConfig.Tx.sequence)

        [flag, ~, ~, frame_id] = dev_manager.get_frame_data(frame_buf);

        while(tx_num==1&&flag==0)
            tic
            [flag, ~, ~, frame_id] = dev_manager.get_frame_data(frame_buf);
            tempTime = toc;
            elapsedTime = elapsedTime+tempTime;
            if(elapsedTime>10)
                disp('If the data cannot be uploaded, please disable MATLAB and collect it again, if the data from the above operations still cannot be uploaded, please turn off the device and restart it');
                System.GC.Collect();

                dev_manager.stop_sample;
                dev_manager.close_DAQ;
                return;
            end
        end

        cur_frame_id = mod(frame_id,numel(AcqConfig.Tx.sequence));
        if flag
            if(cur_frame_id-pre_frame_id==1)
                disp("recv successfully:"+num2str(cur_frame_id));
                pre_frame_id = cur_frame_id;
            else
                disp("recv failed frame:"+num2str(cur_frame_id));
                System.GC.Collect();

                dev_manager.stop_sample;
                dev_manager.close_DAQ;
                return;

            end

            recv_data(:,:,tx_num) = vxreshape(AcqConfig,AcqConfig.Rx.Revpt,single(frame_buf));

            tx_num = tx_num+1;
        end

    end
    ADC_Data{frame_nums} = recv_data;
    frame_nums = frame_nums+1;
    tx_num = 1;
    clear recv_data
end
System.GC.Collect();

dev_manager.stop_sample;
dev_manager.close_DAQ;
Acq_Config = AcqConfig;
for i= 1:frameN


    recv_data =  ADC_Data{i};

    rf = zeros(rfsize,numel(Acq_Config.Rx.sequence));
    for tx_num = 1:size(recv_data,3)
        tx_num

        temp = DAS(recv_data(:,:,tx_num),AcqConfig.Rx.sequence{tx_num},AcqConfig.Rx.aperture,AcqConfig.Rx.Revpt, ...
            AcqConfig.Rx.fs,AcqConfig.Tx.sos,min(AcqConfig.Tx.channel,AcqConfig.Probe.element_num),AcqConfig.Probe);

        rf(:,tx_num) =  temp(startpt:endpt);

    end
    RF_Data{i} = rf;

    clear rf
end

if(strcmp(probe.type,'linear'))
    scan.x = ([0:probe.element_num-1]-(probe.element_num-1)/2)*probe.element_pitch;

elseif(strcmp(probe.type,'convex'))
    theta = ([0:probe.element_num-1]-(probe.element_num-1)/2)*probe.element_pitch/probe.element_radius;
    scan.theta =  theta;

end

if(bprocess_flag)
    for i = 1:frameN
        bimg(:,:,:,i) = BProcess(RF_Data{i} ,AcqConfig.Rx.fs,AcqConfig.Tx.sos,scan, probe,postprocess,1);
        B_Data{i} = bimg;
        if(imgshowflag)
            figure(101)
            imshow(bimg(:,:,:,i) )
        end

    end
end


% 保存数据

if (savedataflag)
    currentTime = datetime('now');
    currentTime.Format = 'yyyyMMddHHmmss';
    timeStr = char(currentTime);  % 将 datetime 转换为 char 类型的字符串
    fullPath = fullfile(currentPath, timeStr);
    if ~exist(fullPath,'dir')
        mkdir(fullPath);
    end
    save([fullPath,filesep,'Acq_Config.mat'],'Acq_Config','-v7.3');
    save([fullPath,filesep,'ADC_Data.mat'],"ADC_Data",'-v7.3');
    save([fullPath,filesep,'RF_Data.mat'],"RF_Data",'-v7.3');
    if(bprocess_flag)
        save([fullPath,filesep,'B_Data.mat'],"B_Data",'-v7.3');
    end
end
