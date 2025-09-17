% 函数功能：
% 1、读取软件采集的ADC数据，做波束合成后显示图像；
clear all
clc
close all
%% 加载当前环境变量
currentPath = pwd;
parentDir = fileparts(currentPath);
addpath(genpath(parentDir));
imgshowflag = 1;                            %是否显示图像
saveflag = 1;                               %是否保存bf后数据
filepath = 'E:\20250909144326\ADC\';   %用于解析的ADC文件路径
adc_folder =filepath;
fileparts(fileparts(filepath))

if(saveflag==1)
    bf_folder = strcat(fileparts(fileparts(filepath)),'\BF');   %用于保存BF文件路径
    if ~exist(bf_folder,'dir')
        mkdir(bf_folder);
    end
    disp("数据保存路径为："+bf_folder)
else
    bf_folder = [];
end
[fs,prf,sampleNum,scanLine,imagedepth,focus_depth,cstartoffset,frame_nums,NumsPerFile,steer,scaninfo] = read_adc_para(strcat(filepath,'\Param.txt'),'plane wave');

savepara.startframe =1;                      %起始帧
savepara.packsize = 1;                       %一次保存的bf数量
savepara.endframe = floor(frame_nums/savepara.packsize)*savepara.packsize;  %结束帧
savepara.saveflag = saveflag;

%% 成像参数
sos = 1540;
channel = 128;
wavetype ='plane_wave';
probe_name = 'L10-20';                        %探头名称

probe =  Probe_para(probe_name);

AcqConfig.Probe = probe;
AcqConfig.Rx.fs = fs;
AcqConfig.Rx.sos = sos;
AcqConfig.Rx.channel = channel;
AcqConfig.Rx.Steering = steer;
AcqConfig.Rx.NumsPerFile = NumsPerFile;
AcqConfig.Rx.Revpt =sampleNum;
AcqConfig.Rx.Revdepth = sos/fs/2*sampleNum;

AcqConfig.Rx.aperture.js_win = hamming(256)';
AcqConfig.Rx.aperture.fn_depth = [0 0.04];   %接收F#s深度
AcqConfig.Rx.aperture.fn_value = [1.2 1];    %接收F#
AcqConfig.Rx.aperture.min_Aper = 16;         %最大接收孔径
AcqConfig.Rx.aperture.max_Aper = 128;        %最小接收孔径

%解调低通滤波器
postpara.demo_value = 15e6;
postpara.filtertype  = 'hamming';
postpara.filterorder = 64;
postpara.filtercoef = 0.15;
% 平面波成像区域

startx = scaninfo.start_x(1);
startz = scaninfo.start_z(1);
setpx = scaninfo.step_x(1);
setpz = scaninfo.step_z(1);


Nx = length(scaninfo.start_x);
Nz = sampleNum;

x_axis = (0:setpx:(Nx-1) * setpx)+ startx;
z_axis = (0:setpz:(Nz-1) * setpz)+ startz;

AcqConfig.Rx.rev_line.x = x_axis;
AcqConfig.Rx.rev_line.z = z_axis;

PlaneWave_IQBF_GPUM(AcqConfig,postpara,adc_folder,bf_folder,savepara,imgshowflag);










