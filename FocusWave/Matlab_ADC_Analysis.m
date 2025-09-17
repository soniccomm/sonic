% 函数功能：
% 1、读取ADC数据，做波束合成获取RF；
% 2、根据需求对RF数据进行后处理获取B图像数据；
% 3、运行过程中可选对RF数据做频谱分析

clear all
clc
% close all

currentPath = pwd;
parentDir = fileparts(currentPath);
addpath(genpath(parentDir));

bprocess_flag = 1;                          %是否对RF做后处理
imgshowflag = 1;                            %是否显示图像


folderpath = 'D:\script\FocusWave\20250829095929';  %添加对应ADC路径

eval(strcat('load',32,folderpath,'\Acq_Config.mat'))
eval(strcat('load ',32,folderpath,'\ADC_Data.mat'))

AcqConfig = Acq_Config;
probe = Acq_Config.Probe;
%% 成像参数

frameN = size(ADC_Data,2);                                 %采集N帧数据

%%        图像截取位置
image_start = 0.0012;
startpt = floor(image_start/(AcqConfig.Tx.sos/AcqConfig.Rx.fs/2));
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


frame_nums = 1;
tx_num = 1;
% 后处理参数
postprocess.demo_depth = [0 0.12];          %解调深度
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
postprocess.knobgain = 60;
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



for i= 1:frameN

    i
    recv_data =  ADC_Data{i};
    rf = zeros(rfsize,size(recv_data,2));
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
      figure(101)
      imshow(bimg(:,:,:,i) )

    end
end



