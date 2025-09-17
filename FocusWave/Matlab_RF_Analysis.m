% 函数功能：
% 1、读取RF数据进行后处理获取B图像数据；

clear all
clc
% close all
imgshowflag = 1;                            %是否显示图像
currentPath = pwd;
parentDir = fileparts(currentPath);
addpath(genpath(parentDir));

folderpath = 'D:\script\FocusWave\20250829095929';  %添加对应RF路径
eval(strcat('load',32,folderpath,'\Acq_Config.mat'))
eval(strcat('load ',32,folderpath,'\RF_Data.mat'))
AcqConfig = Acq_Config;
probe = Acq_Config.Probe;
%% 成像参数

frameN = size(RF_Data,2);                                 %采集N帧数据


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

if(strcmp(probe.type,'linear'))
  
    scan.x = ([0:probe.element_num-1]-(probe.element_num-1)/2)*probe.element_pitch;

elseif(strcmp(probe.type,'convex'))
    theta = ([0:probe.element_num-1]-(probe.element_num-1)/2)*probe.element_pitch/probe.element_radius;
    scan.theta =  theta;
     
end

for i= 1:frameN

    rf_data =  RF_Data{1,i};

    bimg= BProcess(rf_data ,AcqConfig.Rx.fs,AcqConfig.Tx.sos,scan, probe,postprocess,1);

    if(imgshowflag)
        figure(102)
        imshow(bimg)
       
    end

    B_Data{i} = bimg;
    clear rf bimg
end


