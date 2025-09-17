function  [NumsPerFile,File_nums,frameN] = DAQ_RealTime_ARFI(AcqConfig,postpara,ScanList,prf,lasting_time,frame_rate,filepath,is_save,is_show,hfig)


tx_chan_ind = AcqConfig.Probe.tx_ele_map;
chmap = AcqConfig.Probe.rx_ele_map;

Revpt = AcqConfig.Rx.Revpt;
RxChannel = AcqConfig.Tx.channel;
TxChannel = AcqConfig.Tx.channel;
trigger_delay = 76;
c =  AcqConfig.Tx.sos;
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

% tvg_time = [0,346,623,900,1177,1455,1732,2009,2286,2563,2840,3117,3394,3671,3948];
% 
% % TGC
% for i = 1:length(tvg_time)
%     calllib('DAQ_SDK', 'set_tvg_arg',length(tvg_time),i-1, 0, tvg_time(i));
% end
atgc_depth = [0 0.05 0.01 0.015 0.02 0.025 0.03 0.035 0.04];
atgc_value = [-34 -34 -34 -34 -28 -26 -24 -22 -20];
% atgc_value = [-40 -40 -40 -40 -40 -40 -40 -40 -40 ];

atgc = AtgcInfo_new(atgc_depth,atgc_value,AcqConfig.Tx.fs,AcqConfig.Tx.sos);
for i = 1:atgc.tvg_serial_num+1
    calllib('DAQ_SDK', 'set_tvg_arg',atgc.tvg_serial_num+1,atgc.tvg_id(i), atgc.tvg_val(i), atgc.tvg_time(i));
end

%% gpu
[x_grid, z_grid] = meshgrid(AcqConfig.Rx.rev_line.x,AcqConfig.Rx.rev_line.z);
Nz = length(AcqConfig.Rx.rev_line.z);
Nx = length(AcqConfig.Rx.rev_line.x);
x_grid = reshape(x_grid,[Nz*Nx,1]);
z_grid = reshape(z_grid,[Nz*Nx,1]);
% 计算发射和接收延时
steer = deg2rad(AcqConfig.Tx.Steering); % 角度制
fs = AcqConfig.Tx.fs;
xm = bsxfun(@minus, AcqConfig.Probe.element_pos.x,x_grid);
zm = bsxfun(@minus,AcqConfig.Probe.element_pos.z,z_grid);
rx_delay = sqrt(xm.^2+zm.^2)/c*fs ;
tx_delay = zeros(Nx*Nz,numel(steer));

for i = 1:numel(steer)
    if steer(i) >= 0
        tx_delay(:,i) = ((x_grid - min(AcqConfig.Probe.element_pos.x))*sin(steer(i)) + z_grid*cos(steer(i)))/c*fs;
    else
        tx_delay(:,i) = ((max( AcqConfig.Probe.element_pos.x) - x_grid)*sin(-steer(i)) + z_grid*cos(steer(i)))/c*fs;
    end
end


for i = 1:AcqConfig.Probe.element_num
    f_mask(:,i) = z_grid./abs(x_grid - AcqConfig.Probe.element_pos.x(i))/2 > AcqConfig.Rx.aperture.fn_value(1);
end

for i = 1:size(f_mask,1)
    temp = f_mask(i,:);
    loc = temp==1;


    temp(1,loc) =  AcqConfig.Rx.aperture.js_win(floor(linspace(1,256,sum(temp))));
    f_mask(i,:) = temp;
end

rx_apod  = f_mask;


% 初始化
single_Steering = single(AcqConfig.Tx.Steering);
single_Steering_ptr = libpointer('singlePtr', single_Steering);
single_Steering_len = length(single_Steering);

single_allbeamx = single(x_grid);
single_allbeamx_ptr = libpointer('singlePtr', single_allbeamx);
single_allbeamx_len = length(single_allbeamx);

single_allbeamz = single(z_grid);
single_allbeamz_ptr = libpointer('singlePtr', single_allbeamz);
single_allbeamz_len = length(single_allbeamz);

single_ch_map = single(chmap(1:RxChannel));
single_ch_map_ptr = libpointer('singlePtr', single_ch_map);
single_ch_map_len = length(single_ch_map);


elex = AcqConfig.Probe.element_pos.x;
elez = AcqConfig.Probe.element_pos.z;
elexz = cat(2, elex, elez)';
single_elexz = single(elexz);
single_elexz_ptr = libpointer('singlePtr', single_elexz);
single_elexz_len = length(single_elexz);


single_rx_apod = reshape(rx_apod,[],1);
single_rx_apod_ptr = libpointer('singlePtr', single_rx_apod);
single_rx_apod_len = length(single_rx_apod);

single_rx_delay = reshape(rx_delay,[],1);
single_rx_delay_ptr = libpointer('singlePtr', single_rx_delay);
single_rx_delay_len = length(single_rx_delay);

single_tx_delay = reshape(tx_delay,[],1);
single_tx_delay_ptr = libpointer('singlePtr', single_tx_delay);
single_tx_delay_len = length(single_tx_delay);

single_angle_weight = [];
single_angle_weight_ptr = libpointer('singlePtr', single_angle_weight);
single_angle_weight_len = length(single_angle_weight);

% 低通滤波器
fc = postpara.demo_value(1);
filtertype = postpara.filtertype;
filterorder = postpara.filterorder;
filtercoef = postpara.filtercoef;
if(strcmp(filtertype,'hamming'))
    b_fir = fir1(filterorder-1,filtercoef,"low",hamming(filterorder));
elseif(strcmp(filtertype,'hanning'))
    b_fir = fir1(filterorder-1,filtercoef,"low",hamming(filterorder));
elseif(strcmp(filtertype,'gaussian'))
    b_fir = fir1(filterorder-1,filtercoef,"low",gausswin(filterorder,1.2));
end

single_filter = single(b_fir);
single_filter_ptr = libpointer('singlePtr', single_filter);
single_filter_len = length(single_filter);

sampleNum = Revpt;
gpu_handle = calllib('US_GPU', 'initializeBfiqGPU', ...
    numel(steer), ...
    numel(steer), ... %AcqConfig.Tx.FsNum
    TxChannel, ... %AcqConfig.Tx.Channel
    RxChannel, ... %RxChannel
    AcqConfig.Probe.element_num, ... %AcqConfig.Probe.element_num
    AcqConfig.Probe.element_pitch, ... %AcqConfig.Probe.element_pitch
    0, ... %AcqConfig.Probe.element_radius
    sampleNum, ... %sample_n
    Nz, ... % bf_sample_num
    Nx, ... % BeamN
    c, ...
    fs, ...
    fc, ...
    single_Steering_ptr,single_Steering_len,...
    single_allbeamx_ptr,single_allbeamx_len,...
    single_allbeamz_ptr,single_allbeamz_len,...
    single_ch_map_ptr,single_ch_map_len,...
    single_elexz_ptr,single_elexz_len,...
    single_filter_ptr,single_filter_len,...
    single_rx_apod_ptr,single_rx_apod_len,...
    single_rx_delay_ptr,single_rx_delay_len,...
    single_tx_delay_ptr,single_tx_delay_len,...
    single_angle_weight_ptr,single_angle_weight_len);







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
if(RxChannel==128)
    result = calllib('DAQ_SDK', 'setDAQ', param, 1);
else
    result = calllib('DAQ_SDK', 'setDAQ', param, 3);

end
if result==0
    disp("set DAQ ok");
else
    % unloadlibrary('DAQ_SDK');
    if libisloaded('DAQ_SDK')
        calllib('DAQ_SDK', 'stop_sample');
        calllib('DAQ_SDK', 'close_sample');
        deleteDaq = calllib('DAQ_SDK', 'deleteDAQHandle');
        pause(1)
        % 卸载库
        unloadlibrary('DAQ_SDK');
    end
    if libisloaded('US_GPU')
        %释放显存
        calllib('US_GPU', 'deleteBeamformingGPUHandle', gpu_handle);
        %卸载dll
        unloadlibrary('US_GPU');
    end
    NumsPerFile = -1;
    File_nums = -1;
    frameN =-1;

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
bfdata=zeros(1, 2*Nz*Nx);
bfdata = single(bfdata);
bfdata_ptr = libpointer('singlePtr', bfdata);

% param1：单次接收数据总量(不带头):，param2:单次接收数据总量(带头)
frame_num_pack = prf/frame_rate; % 每次打包的数量

frame_num_pack = round(frame_num_pack/length(ScanList))*length(ScanList);
ii = 1;
while(frame_num_pack<128)

    frame_num_pack = length(ScanList)*ii;
    ii = ii+1;
end
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
all_bf_data = zeros(Nz, Nx);

% 开始采集
calllib("DAQ_SDK",'start_sample',frameSize, receiveSize);
disp("start_sample ok");
disp("扫查中......")

figure(101);
% 图窗
show_flag = 0;

% % 增益
% DTGC.Depth  = [0,0.005,0.01,0.04,0.08,0.10,0.14];
% DTGC.Value  = [-7,-5,-3,0,6,8,10];
%  dtgc = interp1(DTGC.Depth,DTGC.Value,linspace(0, AcqConfig.Rx.ImageDepth, Nz),"linear",DTGC.Value(end));
%  d_tgc = repmat(dtgc', 1, Nx);

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


    if is_show==1

        ret = calllib('US_GPU', 'processDataBeamformingIQGPU', ...
            gpu_handle,  BData, ...
            BData_len, bfdata_ptr);

        rev = bfdata_ptr.Value;
        bfdata_real = reshape(rev(1:2:end),Nz,Nx,[]);
        bfdata_imag = reshape(rev(2:2:end),Nz,Nx,[]);

        all_bf_data = bfdata_real + 1i* bfdata_imag;
        img = all_bf_data;
        

        img = log_compressed(abs(img));

        % img = d_tgc+img;
        if show_flag == 0

            show_flag = 1;
            % 获取屏幕尺寸
            hImg = imagesc(AcqConfig.Rx.rev_line.x*100,AcqConfig.Rx.rev_line.z*100,img);
            colormap  gray;
            clim([-60, 0]);
            axis('equal', 'tight');
        else
            set(hImg, 'CData', img);
            drawnow;
        end

    end

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


