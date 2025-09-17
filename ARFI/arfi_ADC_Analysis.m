% 函数功能：
% 1、读取软件采集的ADC数据，做波束合成
% 2、进行必要后处理，剪切波追踪并计算速度map

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

filepath = '.\20250917203259';   %用于解析的ADC文件路径
adc_folder =filepath;

%% 成像参数
wavetype ='plane_wave';
chmap =[82 ,114 ,86 ,118 ,90 ,122 ,94 ,126 ,80 ,112 ,84 ,116 ,88 ,120 ,92 ,124 ,83 ,115 ,87 ,119 ,91 ,123 ,95 ,127 ,81 ,113 ,85 ,117 ,89 ,121 ,93 ,125 ,34 ,98 ,38 ,102 ,42 ,106 ,46 ,110 ,32 ,96 ,36 ,100 ,40 ,104 ,44 ,108 ,35 ,99 ,39 ,103 ,43 ,107 ,47 ,111 ,33 ,97 ,37 ,101 ,41 ,105 ,45 ,109 ,18 ,66 ,22 ,70 ,26 ,74 ,30 ,78 ,16 ,64 ,20 ,68 ,24 ,72 ,28 ,76 ,19 ,67 ,23 ,71 ,27 ,75 ,31 ,79 ,17 ,65 ,21 ,69 ,25 ,73 ,29 ,77 ,2 ,50 ,6 ,54 ,10 ,58 ,14 ,62 ,0 ,48 ,4 ,52 ,8 ,56 ,12 ,60 ,3 ,51 ,7 ,55 ,11 ,59 ,15 ,63 ,1 ,49 ,5 ,53 ,9 ,57 ,13 ,61 ];
probe_name = 'L5-10';                        %探头名称
sos = 1540;
channel = 128;

[fs,sampleNum,imagedepth,focus_depth,cstartoffset,frame_nums,NumsPerFile,steer,~,Ref_Frame_Nums,Track_Frame_Nums,ARFI_Focus_Num,ARFI_tx_focus_depth] = arfi_adc_para(strcat(filepath,'\Param.txt'),wavetype);

Filenums =  frame_nums*NumsPerFile;
[temp,adc_scan_length] =ReadADC (adc_folder,channel ,NumsPerFile,Filenums);
temp = reshape(temp,channel ,adc_scan_length(1),NumsPerFile,frame_nums);
temp = permute(temp,[2,1,3,4]);
adc_data = temp(:,chmap+1,:,:);
temp = adc_data;
frame_nums=Ref_Frame_Nums+Track_Frame_Nums;
adc_data = adc_data(:,:,[1:Ref_Frame_Nums*length(steer),end-Track_Frame_Nums*length(steer)+1:end]);
adc_data = reshape(adc_data,adc_scan_length(1),channel,length(steer),[]);
% showFrames(temp,1:133)

% 接收孔径
rev_aper.max_Aper = 128;                    %最大接收孔径
rev_aper.min_Aper = 12;                     %最小接收孔径
rev_aper.fn_depth = [0 0.04];               %深度
rev_aper.fn_value = [1.1 1];                %接收F#
rev_aper.js_win = hamming(256);

% 后处理参数
postprocess.demo_depth = [0 0.04];          %解调深度
postprocess.demo_value = [7.5e6 5e6];         %解调频率
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
postprocess.slider5 = 128;
%旋钮增益
postprocess.knobgain = 50;
%动态范围
postprocess.dynamic_range = 60;
%空间平滑档位
postprocess.spatial_smooth_level = 1;
%fir滤波器阶数、系数、窗函数
postprocess.filterorder = 64;
postprocess.filtercoef = 0.2;
postprocess.filtertype = 'hamming';
postprocess.smooth_level = 1;
%灰阶档位
postprocess.grayMapidx = 1;
%伪彩档位
postprocess.timtMapidx = 2;
%扫描变换
postprocess.dsc_height = 640;
postprocess.dsc_width = 800;

%%        配置参数
probe =  Probe_para(probe_name);
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

scanLine = 128;
scan.start_x = linspace(AcqConfig.Probe.element_pos.x(1),AcqConfig.Probe.element_pos.x(end),scanLine);
scan.start_z = 0*ones(1,scanLine);
scan.step_z = AcqConfig.Rx.sos/AcqConfig.Rx.fs/2*ones(1,scanLine);
scan.step_x = 0*ones(1,scanLine);
scan.x = scan.start_x;

for i = 1:scanLine
    rx_info.sequence{i}.step_x  = scan.step_x(i);
    rx_info.sequence{i}.step_y = 0;
    rx_info.sequence{i}.step_z  = scan.step_z(i);
    %接收起始
    rx_info.sequence{i}.start_x = scan.start_x(i);
    rx_info.sequence{i}.start_y = 0;
    rx_info.sequence{i}.start_z = scan.start_z(i);
    rx_info.sequence{i}.cstartoffset = 0;
end


Nx = scanLine;
Nz = AcqConfig.Rx.sample_num;

x_axis = scan.start_x;
z_axis = (0:scan.step_z(1):(Nz-1) * scan.step_z(1))+ scan.start_z(1);

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



AcqConfig.Rx.sequence  = rx_info.sequence;

rf = zeros(AcqConfig.Rx.sample_num ,scanLine);
for i = 1:frame_nums
    disp("frame"+i)
    recv_data = adc_data(:,:,:,i);
    for tx_num = 1:size(recv_data,3)

        temp = DAS_PlaneWave(recv_data(:,:,tx_num),AcqConfig.Rx.rev_line.x,AcqConfig.Rx.rev_line.z,AcqConfig.Rx.apod,  ...
            AcqConfig.Rx.fs,sos,AcqConfig.Probe, steer(tx_num));

        rf(:,:,tx_num,i) =  temp;

        tx_num = tx_num+1;

    end
end
rf_compound = zeros(adc_scan_length(1),channel,frame_nums);
for i = 1:frame_nums
    rf_compound(:,:,i) = sum(rf(:,:,:,i),3);
end

%%  后处理

if(bprocess_flag)
    for i = 1:frame_nums
        IQ(:,:,i) = ARFI_BProcess(rf_compound(:,:,i), fs,sos,scan, probe,postprocess,1);
    end
end
arfidata = ARFI_displacement(IQ,13,1540,5e6);
dirdata = direct_filter(arfidata(:,:,12:end-1),0);
dirdata = dirdata(:,:,1:30);
for i = 1:50
    temp = arfidata(:,:,i);
    imagesc(temp);
    colorbar;
    colormap(hot)
    clim([-4e-6 4e-6]);
    title(strcat(num2str(i)));
    pause(0.05);
end
ROI_Axial = 401:1000;
ROI_Lateral = 75:115;
PRT = 1/2000;
N_pixel = 6;
pixel_pitch = 3e-4;
Time_Interp_Factor = 5;
[vel_map] = ARFI_TOF(dirdata,ROI_Axial,ROI_Lateral,PRT,N_pixel,pixel_pitch,Time_Interp_Factor);
imagesc(vel_map);
colorbar;
clim([0 5]);














