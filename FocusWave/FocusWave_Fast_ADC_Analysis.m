clear all
clc
close all
%% 加载当前环境变量
currentPath = pwd;
parentDir = fileparts(currentPath);
addpath(genpath(parentDir));

bprocess_flag = 1;                          %是否对RF做后处理
imgshowflag = 1;                            %是否显示图像

filepath = 'E:\20250908193432\';   %添加对应ADC路径
adc_folder =filepath;
% 获取文件
currentFolder = pwd;
parentFolder = fileparts(currentFolder);
%% 成像参数
wavetype ='focus_wave';
probe_name = 'L10-20';                        %探头名称
sos = 1540;
channel = 128;
probe =  Probe_para(probe_name);

[fs,prf,sampleNum,scanLine,imagedepth,focus_depth,cstartoffset,frame_nums,NumsPerFile,steer,scan] = read_adc_para(strcat(filepath,'\Param.txt'),wavetype);

Filenums =  frame_nums*scanLine;
[temp,adc_scan_length] =ReadADC (adc_folder,channel ,NumsPerFile,Filenums);
temp = reshape(temp,channel ,adc_scan_length(1),scanLine,[]);
temp = permute(temp,[2,1,3,4]);
adc_data = temp(:,probe.rx_ele_map(1:channel)+1,:,:);
adc_data = adc_data(:,1:min(channel,probe.element_num),:,:);

% 接收孔径
rev_aper.max_Aper = 64;                    %最大接收孔径
rev_aper.min_Aper = 12;                     %最小接收孔径
rev_aper.fn_depth = [0 0.04];               %深度
rev_aper.fn_value = [1.1 1];                %接收F#
rev_aper.js_win = hamming(256);

% 后处理参数
postprocess.demo_depth = [0 0.04];          %解调深度
postprocess.demo_value = [15e6 15e6];         %解调频率
postprocess.dgain_global_value = -15;       %全局增益
%分段增益
postprocess.dgain_depth = [0 0.0050 0.0100 0.0150 0.0200 0.0400];
postprocess.dgain_value = [-8 -8 0 0 0 0];
%拨杆增益
postprocess.slider0 = 128;
postprocess.slider1 = 128;
postprocess.slider2 = 128;
postprocess.slider3 = 128;
postprocess.slider4 = 128;
postprocess.slider5 = 128;
%旋钮增益
postprocess.knobgain = 50;
%动态范围
postprocess.dynamic_range = 50;
%空间平滑档位
postprocess.spatial_smooth_level = 1;
%fir滤波器阶数、系数、窗函数
postprocess.filterorder = 64;
postprocess.filtercoef = 0.06;
postprocess.filtertype = 'hamming';
postprocess.smooth_level = 1;
%灰阶档位
postprocess.grayMapidx = 1;
%伪彩档位
postprocess.timtMapidx = 2;
%扫描变换
postprocess.dsc_height = 480;
postprocess.dsc_width = 640;

%%        配置参数

chmap = probe.rx_ele_map;

AcqConfig.Probe = probe;
AcqConfig.Tx.channel = channel;
AcqConfig.Tx.fs = fs;
AcqConfig.Tx.sos = sos;
AcqConfig.Tx.focus_depth =   focus_depth;
%%        采样点数
AcqConfig.Rx.fs = fs;
AcqConfig.Rx.sos = sos;

AcqConfig.Rx.sample_num = sampleNum;

%%        接收孔径、变迹
AcqConfig.Rx.aperture = rev_aper;
%%        接收波束合成
%%       接收线位置
if(strcmp(probe.type,'linear'))
    AcqConfig.Rx.rev_line.x = scan.start_x;
    AcqConfig.Rx.rev_line.z = scan.start_z;
    scan.x = ([0:probe.element_num-1]-(probe.element_num-1)/2)*probe.element_pitch;


elseif(strcmp(probe.type,'convex'))
    AcqConfig.Rx.rev_line.x = scan.start_x;
    AcqConfig.Rx.rev_line.z = scan.start_z;
    scan.theta =    ([0:probe.element_num-1]-(probe.element_num-1)/2)*probe.element_pitch/probe.element_radius;

      
end



for i = 1:scanLine
    rx_info.sequence{i}.step_x  = scan.step_x(i);
    rx_info.sequence{i}.step_y = 0;
    rx_info.sequence{i}.step_z  = scan.step_z(i);
    %接收起始
    rx_info.sequence{i}.start_x = scan.start_x(i);
    rx_info.sequence{i}.start_y = 0;
    rx_info.sequence{i}.start_z = scan.start_z(i);
    rx_info.sequence{i}.cstartoffset = cstartoffset(i);
end



AcqConfig.Rx.sequence  = rx_info.sequence;
rf = zeros(AcqConfig.Rx.sample_num ,scanLine);
for i = 1:frame_nums
    recv_data = adc_data(:,:,:,i);
    for tx_num = 1:size(recv_data,3)
        tx_num
        temp = DAS(recv_data(:,:,tx_num),AcqConfig.Rx.sequence{tx_num},AcqConfig.Rx.aperture,AcqConfig.Rx.sample_num, ...
            AcqConfig.Rx.fs,sos,min(AcqConfig.Tx.channel,AcqConfig.Probe.element_num),AcqConfig.Probe);
        rf(:,tx_num,i) =  temp;
        tx_num = tx_num+1;

    end
end

%%       后处理

if(bprocess_flag)
    for i = 1:frame_nums
        bimg(:,:,:,i) = BProcess(rf(:,:,i), fs,sos,scan, probe,postprocess,1);
    end
end
if(imgshowflag)
    for i = 1:frame_nums
        if(bprocess_flag)

            figure(103)
            imshow(bimg(:,:,:,i))
        end
    end
end


















