function  [NumsPerFile,File_nums,frameN] = DAQ_Acquisition_ARFI(AcqConfig,ScanList,prf,filepath,is_show,is_save,bfparams)


if is_show == 1
    disp("本次运行显示图像")
else
    disp("本次运行不显示图像")
end
if is_save == 1
    disp("本次运行保存数据")
else
    disp("本次运行不保存数据")
end
if is_show == 0 && is_save == 0
    disp("程序不会运行")
    NumsPerFile = 0;
    File_nums = 0;
    frameN = 0;
    return
end



tx_chan_ind = AcqConfig.Probe.tx_ele_map;
ch_map = AcqConfig.Probe.rx_ele_map;

Revpt = AcqConfig.Rx.Revpt;
RxChannel = 128;
TxChannel = 128;

trigger_delay = 76;

%加载dll
if ~libisloaded('US_GPU')
    loadlibrary('US_GPU.dll', 'BeamFormingMatlabInterface.h');
end

% 库路径
if ~libisloaded('DAQ_SDK')
    loadlibrary('DAQ_SDK.dll', 'DAQ_SDK.h');
end

%平面波实时成像入口，param1:角度总数，param2:单帧数据长度(带头)
calllib("DAQ_SDK",'RunRealTime',length(AcqConfig.Tx.Steering),(32+AcqConfig.Rx.Revpt*RxChannel*2));
% 创建 libpointer 并传递字符串
ptr = libpointer('cstring', filepath);
calllib('DAQ_SDK', 'SetIsSave',is_save,ptr);


%寄存器配置
if(AcqConfig.Tx.fs/1e6==80 )
    AFE_Registers =  [2 3 4 5 21 33 45 57 67 154 155 156 195 196 197 203];
    AFE_Register_values = [0 0 0 13652 5 5 5 5 0 1024 10098 0 7 8448 0 8];
else
    AFE_Registers =  [2 3 4 5 21 33 45 57 67 154 155 156 195 196 197 203];
    AFE_Register_values = [0 32792 1 13652 5 5 5 5 0 1024 10098 0 5 8448 0 8];
end


for i = 1:length(AFE_Register_values)
    AFE_Register  = AFE_Registers(i);
    AFE_Register_value =  AFE_Register_values(i);
    calllib('DAQ_SDK', 'set_afe_reg',AFE_Register,AFE_Register_value);
end



tvg_time = [0,346,623,900,1177,1455,1732,2009,2286,2563,2840,3117,3394,3671,3948];

% TGC
for i = 1:length(tvg_time)
    calllib('DAQ_SDK', 'set_tvg_arg',length(tvg_time),i-1, 0, tvg_time(i));
end


%% gpu

%接收孔径、变迹信息
Jswininfo.type = 'gauss';
Jswininfo.alpha = 1.2;
L=256;
for i = 1:L
    n = (i-1)- (L-1)/2;
    JsWin(i) = exp(-(1/2)*(Jswininfo.alpha*n/((L-1)/2)).^2);
end

JsAper.Jswin       = single(JsWin);
JsAper.Js_Fn_depth = single([0 0.04]);
JsAper.Js_Fn_value = single([1.2 1]);
JsAper.Js_Min_Aper = single(12);
JsAper.Js_Max_Aper = single(128);
JsAper.Js_Max_Fn   = single(1.2);
JsAper.Js_Min_Fn   = single(1);
JsAper.Js_Fn_value = single([1.2 1]);
Js_fn_setp =  single((JsAper.Js_Fn_value(2)-JsAper.Js_Fn_value(1))/(JsAper.Js_Fn_depth(2)-JsAper.Js_Fn_depth(1)));


% 初始化
single_Steering = single(AcqConfig.Tx.Steering); % 角度制
single_Steering_ptr = libpointer('singlePtr', single_Steering);
single_Steering_len = length(single_Steering);

single_allbeamx = single(bfparams.x_grid_all);
single_allbeamx_ptr = libpointer('singlePtr', single_allbeamx);
single_allbeamx_len = length(single_allbeamx);

if(AcqConfig.Probe.type == "convex")
    bfparams.z_grid_all = bfparams.z_grid_all + AcqConfig.Probe.R;
end

single_allbeamz = single(bfparams.z_grid_all);
single_allbeamz_ptr = libpointer('singlePtr', single_allbeamz);
single_allbeamz_len = length(single_allbeamz);

single_cstartoffset = single(zeros(length(ScanList),1));
single_cstartoffset_ptr = libpointer('singlePtr', single_cstartoffset);
single_cstartoffset_len = length(single_cstartoffset);

single_JsWin = single(JsWin);
single_JsWin_ptr = libpointer('singlePtr', single_JsWin);
single_JsWin_len = length(single_JsWin);

single_ch_map = single(ch_map);
single_ch_map_ptr = libpointer('singlePtr', single_ch_map);
single_ch_map_len = length(single_ch_map);

elexz = cat(2, AcqConfig.Probe.element_pos.x, AcqConfig.Probe.element_pos.z)';
single_elexz = single(elexz);
single_elexz_ptr = libpointer('singlePtr', single_elexz);
single_elexz_len = length(single_elexz);

if (AcqConfig.Probe.type == "linear")
    Demod_AFE_Dynamic = -4;
    AcqConfig.Probe.R = 0;
elseif(AcqConfig.Probe.type == "convex")
    Demod_AFE_Dynamic = -6;
end

gpu_handle = calllib('US_GPU', 'initializeBeamformingGPU', ...
    Demod_AFE_Dynamic, ...
    length(ScanList), ...
    TxChannel, ...
    RxChannel, ...
    AcqConfig.Probe.element_num, ...
    AcqConfig.Probe.element_pitch, ...
    AcqConfig.Probe.R, ...
    AcqConfig.Rx.Revpt,...
    bfparams.Nz,...
    bfparams.scanLine, ...
    AcqConfig.Tx.sos, ...
    AcqConfig.Rx.fs, ...
    JsAper.Js_Min_Aper, ...
    JsAper.Js_Max_Aper, ...
    JsAper.Js_Max_Fn, ...
    JsAper.Js_Min_Fn, ...
    JsAper.Js_Fn_depth(1), ...
    Js_fn_setp, ...
    JsAper.Js_Fn_value(1), ...
    single_Steering_ptr,single_Steering_len,...
    single_allbeamx_ptr,single_allbeamx_len,...
    single_allbeamz_ptr,single_allbeamz_len,...
    single_cstartoffset_ptr,single_cstartoffset_len,...
    single_JsWin_ptr,single_JsWin_len,...
    single_ch_map_ptr,single_ch_map_len,...
    single_elexz_ptr,single_elexz_len);


%%  配置发射参数
% 0xBF:单脉冲发射 0xBE:极性相反 0x7F:连续脉冲发射 0x7E:极性相反 0x3F:不发射
% 电压配置
Txseq.FsFrequency = round(240/( AcqConfig.Tx.sequence{1}.pulse_frequency/1e6));
Txseq.Duration = round(((1 - AcqConfig.Tx.sequence{1}.pulse_duration) * Txseq.FsFrequency/4));
Txseq.Pulse_num = AcqConfig.Tx.sequence{1}.pulse_num*2;
disp("configuring transmit voltage ...");
voltage_commmand_val = AcqConfig.Tx.sequence{1}.pulse_voltage * 3153 * 16 / 100;
calllib('DAQ_SDK', 'set_tx_arg',1,0, ...
    Txseq.Duration, ...
    Txseq.Pulse_num, ...
    uint16(round(AcqConfig.Tx.sequence{1}.delay(1)*240e6)), ...
    Txseq.FsFrequency, ...
    hex2dec('0x3F'),hex2dec('0x5AFF'), ...
    voltage_commmand_val);
calllib('DAQ_SDK', 'set_tx_arg',1,0, ...
    Txseq.Duration, ...
    Txseq.Pulse_num, ...
    uint16(round(AcqConfig.Tx.sequence{1}.delay(1)*240e6)), ...
    Txseq.FsFrequency, ...
    hex2dec('0x3F'),hex2dec('0x5AFE'), ...
    voltage_commmand_val);

pause(0.001);



% 其他发射参数配置
disp("configuring transmit sequence ...");
command_code = '0x3aff';
for tx_idx = 0:numel(AcqConfig.Tx.sequence)-1
    disp("configuring transmit sequence ["+num2str(tx_idx)+"]");
    %为1时，极性相反

    Txseq.FsFrequency = round(240/( AcqConfig.Tx.sequence{tx_idx+1}.pulse_frequency/1e6));
    Txseq.Duration = round(((1 - AcqConfig.Tx.sequence{tx_idx+1}.pulse_duration) * Txseq.FsFrequency/4));
    Txseq.Pulse_num = AcqConfig.Tx.sequence{tx_idx+1}.pulse_num*2;


    if(AcqConfig.Tx.sequence{tx_idx+1}.pulse_polarity==0)
        for element_idx = 1:TxChannel

            if (AcqConfig.Tx.sequence{tx_idx+1}.active(element_idx))

                    calllib('DAQ_SDK', 'set_tx_arg', tx_chan_ind(element_idx),tx_idx,...
                        Txseq.Duration,...
                        Txseq.Pulse_num,...
                        uint16(round(AcqConfig.Tx.sequence{tx_idx+1}.delay(element_idx)*240e6)),...
                        Txseq.FsFrequency ,...
                        hex2dec('0x7E'),....
                        hex2dec(command_code), ...
                        numel(AcqConfig.Tx.sequence)-1);

            else
                calllib('DAQ_SDK', 'set_tx_arg', tx_chan_ind(element_idx),tx_idx,...
                    Txseq.Duration,...
                    Txseq.Pulse_num,...
                    uint16(round(AcqConfig.Tx.sequence{tx_idx+1}.delay(element_idx)*240e6)),...
                    Txseq.FsFrequency ,...
                    hex2dec('0x3F'),....
                    hex2dec(command_code), ...
                    numel(AcqConfig.Tx.sequence)-1);

            end

        end



    else

        for element_idx = 1:TxChannel

            if (AcqConfig.Tx.sequence{tx_idx+1}.active(element_idx))

                    calllib('DAQ_SDK', 'set_tx_arg', tx_chan_ind(element_idx),tx_idx,...
                        Txseq.Duration,...
                        Txseq.Pulse_num,...
                        uint16(round(AcqConfig.Tx.sequence{tx_idx+1}.delay(element_idx)*240e6)),...
                        Txseq.FsFrequency ,...
                        hex2dec('0x7F'),....
                        hex2dec(command_code),...
                        numel(AcqConfig.Tx.sequence)-1);

            else
                calllib('DAQ_SDK', 'set_tx_arg', tx_chan_ind(element_idx),tx_idx,...
                    Txseq.Duration,...
                    Txseq.Pulse_num,...
                    uint16(round(AcqConfig.Tx.sequence{tx_idx+1}.delay(element_idx)*240e6)),...
                    Txseq.FsFrequency ,...
                    hex2dec('0x3F'),....
                    hex2dec(command_code),...
                    numel(AcqConfig.Tx.sequence)-1);

            end



        end
    end

end


% 一帧超声图像对应总线数  当前模式结束线号
calllib('DAQ_SDK', 'set_afe_mode',0,0,0,size(ScanList,2), size(ScanList,2));

profile_v = int32([0,0,0,0,0,0,0,0,0,0,0,0,0,16]);
bytePtr = libpointer('int32Ptr', fliplr(profile_v));
calllib('DAQ_SDK', 'set_afe_profile',0,0,bytePtr,length(profile_v));

AFEFilter.Filtercoef=[20,136,92,65068,64688,588,3928,6424;65520,72,164,65408,64752,65100,2140,5500];
AFEFilter.Rows = 2;
for i = 0:AFEFilter.Rows-1
    calllib('DAQ_SDK', 'set_afe_filter',AFEFilter.Rows-1, i, AFEFilter.Filtercoef(i+1,1),AFEFilter.Filtercoef(i+1,2),AFEFilter.Filtercoef(i+1,3), ...
        uint16(AFEFilter.Filtercoef(i+1,4)),AFEFilter.Filtercoef(i+1,5),AFEFilter.Filtercoef(i+1,6),AFEFilter.Filtercoef(i+1,7),AFEFilter.Filtercoef(i+1,8));
end


%每通道采样次数
Rx_sample_num = Revpt;

% %配置发射序列头部的所有数据
for i = 1:size(ScanList,2)
    calllib('DAQ_SDK', 'set_scanHead',0, ScanList(i).Sln, 0,  0, ...
        1, ScanList(i).PluseType,ScanList(i).Frameend, ScanList(i).Framestart, ScanList(i).SampleN);
end

% 如果prf超过上限，则自动设置为上限
maxprf = floor(3.0/((Rx_sample_num*RxChannel*2+32)/1024/1024/1024)/2)*2;
if(prf>maxprf)
    disp("The prf you selected = " + prf + " has exceeded the limit")
    prf = maxprf;
    disp("automatically adjust to max prf = "+num2str(prf))
end

if(bfparams.update_fre>60)
    disp("The update frequency you selected = " + bfparams.update_fre + " has exceeded the limit")
    bfparams.update_fre = 60;
    disp("automatically adjust to max frequency = "+num2str(60))
end


% seqNums = frames*size(AcqConfig.Tx.sequence,2);
% [TotalLines,frame_num,frameSize,receiveSize,prf] = LinesperFile(Rx_sample_num,RxChannel,prf,seqNums);
% NumsPerFile = TotalLines;
% File_nums = frame_num;
trigger_fs = prf;

% 3. 准备调用参数
param = struct( 'adc_fs', AcqConfig.Tx.fs,...
    'sample_num', Rx_sample_num,...
    'frame_num_in_callback', 1,...  %无效
    'sensor_num', TxChannel,...
    'trigger_fs', trigger_fs,...
    'trigger_mode', 1,...     %   设置DAQ为内触发还是外触发，true为内触发，false为外触发
    'enable_2_network', 0,...
    'enable_upload', 6,...
    'extra_port_num', 0,...
    'merge_channel_num', 0,...
    'trigger_shield', 0,...
    'trigger_delay1', trigger_delay,...
    'trigger_delay2', trigger_delay,...
    'trigger_delay3', trigger_delay,...
    'tgc_gain1', 0,...
    'tgc_gain2', 0,...
    'tgc_gain3', 0,...
    'vca_gain1', 0,...
    'vca_gain2', 0,...
    'vca_gain3', 0);

% 4. 调用函数
result = calllib('DAQ_SDK', 'setDAQ', param, 1);

if result==0
    disp("set DAQ ok");
else
    unloadlibrary('DAQ_SDK');
    disp("set DAQ failed");
    return;
end

pause(5)

% 5. 采集设置
% 原始数据长度
BData_len = length(ScanList) *(2 * Rx_sample_num*TxChannel+32) ;
data_empty = zeros(BData_len, 1, 'int8');
BData = libpointer('int8Ptr', data_empty);
% bf数据长度
bfdata=zeros(1, bfparams.Nz*bfparams.scanLine);
bfdata = single(bfdata);
bfdata_ptr = libpointer('singlePtr', bfdata);

% param1：单次接收数据总量(不带头):，param2:单次接收数据总量(带头)
% frame_num_pack = prf/bfparams.update_fre; % 每次打包的数量
frame_num_pack = length(ScanList);
if is_save==1
    disp("每包数据(NumsPerFile)有"+frame_num_pack+"帧")
end
if is_show==1
    disp("图像刷新理论帧率为"+(prf/frame_num_pack)+"Hz")
end
frameSize = frame_num_pack*2*Rx_sample_num*TxChannel;
receiveSize = frame_num_pack*(2*Rx_sample_num*TxChannel+32);
NumsPerFile = frame_num_pack;

% 存bf结果
all_bf_data = zeros(bfparams.Nz, bfparams.scanLine, length(ScanList));

% 开始采集
calllib("DAQ_SDK",'start_sample',frameSize, receiveSize);
disp("start_sample ok");
disp("扫查中......")


% 图窗
show_flag = 0;

% 增益
DTGC.Depth  = [0,0.005,0.01,0.04,0.08,0.10,0.14];
DTGC.Value  = [-7,-5,-3,0,6,8,10];
dtgc = interp1(DTGC.Depth,DTGC.Value,linspace(0, AcqConfig.Rx.ImageDepth, bfparams.Nz),"linear",DTGC.Value(end));
d_tgc = repmat(dtgc', 1, bfparams.scanLine);

% dsc
if(AcqConfig.Probe.type == "convex")
    valid_rad = atan(bfparams.x_grid./(bfparams.z_grid+AcqConfig.Probe.R));
    dsc_table = (valid_rad>AcqConfig.Probe.element_pos.theta(1)) .* (valid_rad<AcqConfig.Probe.element_pos.theta(end));

    valid_range = (sqrt(bfparams.x_grid.^2 + (bfparams.z_grid+AcqConfig.Probe.R).^2)>=(AcqConfig.Probe.R+0.001));
    dsc_table = dsc_table.*valid_range;

    dsc_table = reshape(dsc_table, bfparams.Nz, bfparams.scanLine);
end

% weight
if(AcqConfig.Probe.type == "convex")
    
for i = 1:numel(AcqConfig.Tx.Steering)
    a = 15/180*3.1415926;
    b = 25/180*3.1415926;
    pixel_rad = atan(bfparams.x_grid./(bfparams.z_grid+AcqConfig.Probe.R));
    theta_rad = abs(pixel_rad - deg2rad(AcqConfig.Tx.Steering(i)) );

    dsc_weight = (theta_rad<=a).*1 + (theta_rad>a & theta_rad<b).*(1 - (theta_rad - a)/(b - a));
    dsc_weight(theta_rad>b) = 0;

    dsc_weight_table(:,:,i) = reshape(dsc_weight, bfparams.Nz, bfparams.scanLine);
end

end


% 根据framid控制停止
frameid = 0;
frameN = 1;
max_frameid = frameN*length(ScanList);
File_nums = max_frameid;

while(frameid <= max_frameid)

    % 调用一次会从frame_num打包的数据取N帧，这N帧数据拷贝到BData, 并返回frameid
    frameid=calllib("DAQ_SDK",'getOneFrameData', BData);

    % 防止取数据太快
    pause(0.001);

    if(frameid == -1) % 取数据失败
        continue;
    end
    % fprintf("current_frame_id: %d\n",frameid);
%     frameid_all = [frameid_all;frameid];

    if is_show==1

        BData_len_single = BData_len/length(ScanList);
        for angle_i = 1:length(ScanList)
            ret = calllib('US_GPU', 'processDataBeamformingGPU', gpu_handle, BData+(angle_i-1)*BData_len_single, BData_len_single, bfdata_ptr);
            img_temp = reshape(bfdata_ptr.Value, [bfparams.Nz bfparams.scanLine]);
            if (AcqConfig.Probe.type == "convex")
                all_bf_data(:,:,angle_i) = img_temp.*dsc_weight_table(:,:,angle_i);
            else
                all_bf_data(:,:,angle_i) = img_temp;
            end
        end
        img = squeeze(mean(all_bf_data,3));
        
        % dsc
        if (AcqConfig.Probe.type == "convex")
            img(dsc_table==0) = 0;
        end

        pad_h = 300;
        img_pad = padarray(img,[pad_h,0]);
        img_pad = log_compressed(abs(hilbert(img_pad)));
        img = img_pad(pad_h+1:end-pad_h,:);

        
        img = d_tgc+img;
        % dsc
        if (AcqConfig.Probe.type == "convex")
            img(dsc_table==0) = -inf;
        end


        if show_flag == 0

            show_flag = 1;
            % 获取屏幕尺寸
            screen_size = get(0, 'ScreenSize');
            screen_width = screen_size(3);
            screen_height = screen_size(4);
            
            xx = bfparams.x_axis;
            zz = bfparams.z_axis;

            zz_cut = zz(zz<=AcqConfig.Rx.ImageDepth);
            Nz_cut = numel(zz_cut);

            % 
            real_width = xx(end)- xx(1);
            real_height = zz(end) - zz(1);

            % 规定窗口占据屏幕比例
            fig_width_ratio = 0.4;
            fig_height_ratio = real_height/real_width*fig_width_ratio*2;
            % 设置窗口大小
            fig_width = screen_width * fig_width_ratio;
            fig_height = screen_height * fig_height_ratio;
            % 设置窗口位置
            fig_left = screen_width * (1-fig_width_ratio)/2;
            fig_bottom = screen_height * (1-fig_height_ratio)/2;

            hFig = figure('Name',"planewave realtime",'NumberTitle','off','Position', [fig_left, fig_bottom, fig_width, fig_height]);
            hIm = imagesc(xx*100,zz_cut*100,img(1:Nz_cut,:));
            colormap(gray);title("平面波实时成像");clim([-60, 0]);xlabel("cm");ylabel("cm")
            axis equal;axis tight

        else
            hIm.CData = img(1:Nz_cut,:);
        end

    end

end


if is_show == 1
    delete(hFig);
    clear hFig
end


%% 卸载

disp('扫查完成')
calllib('DAQ_SDK', 'stop_sample');
disp('STOP_DAQ')
calllib('DAQ_SDK', 'close_sample');
disp('CLOSE_DAQ')
deleteDaq = calllib('DAQ_SDK', 'deleteDAQHandle');
disp('DELETE_DAQ')
pause(1)
% 卸载库
if libisloaded('DAQ_SDK')
    unloadlibrary('DAQ_SDK');
    disp('库已成功卸载');
end

%释放显存
calllib('US_GPU', 'deleteBeamformingGPUHandle', gpu_handle);
disp('GPU库已成功卸载');
%卸载dll
unloadlibrary('US_GPU');


clear BData;



end



function  atgc = AtgcInfo_new(Depth,Value,c,fs)
 % 最大256段，量化公式（0~1.5）/3.3*65536  对应 衰减-40~0db


changliang = (c/fs/2);


[VGA_Depth,VGA_Value] = linearInterp(Depth,Value,16);

% VGA_Depth =Depth;
% VGA_Value = Value;
% figure;plot(VGA_Depth,VGA_Value)

% 计算原始数据的步长
DL = length(VGA_Depth);
if(DL>256)
    DL =256;
end

mindb = 0;
maxdb = -40;
minv = 0;
maxv = 1.5;
dsetp = -1*(maxv-minv)/abs(maxdb-mindb);
vol = dsetp*(VGA_Value-mindb);
vol = min(max(vol,minv),maxv);
val = round(vol/3.3*65536);




% figure;plot(fliplr(vol),VGA_Value)

% figure;plot(VGA_Depth,vol)
% figure;plot(VGA_Depth,tvg_val)
pt = 80;% 80M量化，最小时间1us

tvg_time(1) = 0;
tvg_id(1) = 0;
idx = 2;
tvg_val(1) = val(1);

for i = 2:DL
    temp = (VGA_Depth(i)-0.002)/changliang/ fs*1e6;
    a = round(temp*pt);
    if(a<80)
        continue;
    end
    tvg_val(idx) = val(i);
    tvg_time(idx) = a;
    tvg_id(idx) = idx-1;
    idx = idx+1;

end



% figure;plot(tvg_time,vol)
atgc.tvg_id = tvg_id;
atgc.tvg_val = tvg_val;
atgc.tvg_time =  tvg_time;
atgc.tvg_serial_num = idx-2;

end


function [value0,value1] = linearInterp(a,b,interpN)

n = numel(a);
a_step = (a(end) - a(1)) / (interpN - 1);

value0 = zeros(1, interpN);
value1 = zeros(1, interpN);

for i = 1:interpN
    value0(i) = a(1) + (i - 1) * a_step;
end

% 线性插值
for i = 1:interpN

    for j = 1:n-1
        if value0(i) >= a(j) && value0(i) <= a(j+1)

            value1(i) = b(j) + (b(j+1) - b(j)) * (value0(i) - a(j)) / (a(j+1) - a(j));
            break;
        end
    end
end
end










