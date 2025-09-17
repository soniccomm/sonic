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

filepath = 'E:\20250908193432'; %添加对应RF路径
rf_folder =filepath;

% 解析数据
wavetype ='focus_wave';
[fs,sampleNum,imageDepth,focus,cstartoffset,frame_nums,NumsPerFile,steer,scanline,scan] = read_rf_sw_para(strcat(filepath,'\Param.txt'),wavetype);
Filenums =  frame_nums*scanline;
temp =ReadRF (rf_folder ,NumsPerFile,Filenums);
rf = reshape(temp ,[],scanline,frame_nums);
frameN = size(rf,3);

% 探头名称
probe_name = 'L10-20';                        %探头名称
probe =  Probe_para(probe_name);



% 后处理参数
sos = 1540;
postprocess.demo_depth = [0 0.2];          %解调深度
postprocess.demo_value = [15e6 15e6];         %解调频率
postprocess.dgain_global_value = -15;       %全局增益
%分段增益
postprocess.dgain_depth = [0 0.0050 0.0100 0.0150 0.0200 0.0400];
postprocess.dgain_value = [0 0 0 0 0 0];
%拨杆增益
postprocess.slider0 = 128;
postprocess.slider1 = 128;
postprocess.slider2 = 128;
postprocess.slider3 = 128;
postprocess.slider4 = 128;
postprocess.slider5 = 150;
%旋钮增益
postprocess.knobgain = 60;
%动态范围
postprocess.dynamic_range = 60;
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
postprocess.dsc_height = 640;
postprocess.dsc_width = 800;


if(strcmp(probe.type,'linear'))
    AcqConfig.Rx.rev_line.x = scan.start_x;
    AcqConfig.Rx.rev_line.z = scan.start_z;
    scan.x = ([0:probe.element_num-1]-(probe.element_num-1)/2)*probe.element_pitch;


elseif(strcmp(probe.type,'convex'))
    AcqConfig.Rx.rev_line.x = scan.start_x;
    AcqConfig.Rx.rev_line.z = scan.start_z;
    scan.theta =    ([0:probe.element_num-1]-(probe.element_num-1)/2)*probe.element_pitch/probe.element_radius;

      
end



for i= 1:frameN

    rf_data =  rf(:,:,i);

    bimg(:,:,:,i) = BProcess(rf_data, fs,sos,scan, probe,postprocess,1);

    if(imgshowflag)
        figure(101)
        imshow(bimg(:,:,:,i))
    end
    clear bimg
end


