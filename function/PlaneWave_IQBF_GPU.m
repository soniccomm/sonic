function PlaneWave_IQBF_GPU(AcqConfig,postpara,datapath,filepath,savepara,is_show,hfig)

[fs,~,sampleNum,~,~,~,~,~,NumsPerFile,~] = read_adc_para(strcat(datapath,'\Param.txt'),'plane_wave');

chmap = AcqConfig.Probe.rx_ele_map;
% fs = AcqConfig.Tx.fs;
c = AcqConfig.Tx.sos;
RxChannel = AcqConfig.Tx.channel;
TxChannel = AcqConfig.Tx.channel;
Rx_sample_num = AcqConfig.Rx.Revpt;

%接收孔径、变迹信息

[x_grid, z_grid] = meshgrid(AcqConfig.Rx.rev_line.x,AcqConfig.Rx.rev_line.z);
Nz = length(AcqConfig.Rx.rev_line.z);
Nx = length(AcqConfig.Rx.rev_line.x);
x_grid = reshape(x_grid,[Nz*Nx,1]);
z_grid = reshape(z_grid,[Nz*Nx,1]);

% 计算发射和接收延时
steer = deg2rad(AcqConfig.Tx.Steering); % 角度制

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

rx_apod = AcqConfig.Rx.apod;
%加载dll
if ~libisloaded('US_GPU')
    loadlibrary('US_GPU.dll', 'BeamFormingMatlabInterface.h');
end

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



% 5. 采集设置
% 原始数据长度
BData_len = numel(steer) *(2 * Rx_sample_num*TxChannel+32) ;

% bf数据长度
bfdatas =zeros(1, 2*Nz*Nx);
bfdatas = single(bfdatas);
bfdata_ptr = libpointer('singlePtr', bfdatas);



startframe = savepara.startframe;
endframe = savepara.endframe;
packsize = savepara.packsize;
Ns = floor(endframe/packsize);
[~,~,sampleNum,~,~,~,~,~,NumsPerFile] = read_adc_para(strcat(datapath,'\Param.txt'),'plane_wave');
if(sampleNum~=Rx_sample_num)
    disp('error data')
    return;
end
idx = 0;

type ='IQ';
fprintf('BF: [%s] ',type)
previous_msg = '';
filesel = startframe:packsize:Ns*packsize;
N = length(filesel)*packsize;

for i = filesel(1:length(filesel))
    % disp("bf "+idx)
    %text_progress_bar(100*n/N,previous_msg)
    s_idx = (i-1)*single_Steering_len+1;
    e_idx = s_idx+packsize*single_Steering_len-1;


    temp= GetADC(datapath ,RxChannel ,NumsPerFile ,Rx_sample_num, s_idx, e_idx);
    % temp1= GetADC(datapath ,RxChannel ,NumsPerFile ,Rx_sample_num, s_idx, e_idx);


    for j = 1:packsize
        previous_msg = text_progress_bar(100* (idx*packsize+j)/N,previous_msg);

        temp1 = temp(((j-1)*BData_len+1):j*BData_len);
        data_empty = int8(temp1);

        BData = libpointer('int8Ptr', data_empty);


        ret = calllib('US_GPU', 'processDataBeamformingIQGPU', ...
            gpu_handle, BData, ...
            BData_len, bfdata_ptr);


        rev = bfdata_ptr.Value;
        bfdata_real = reshape(rev(1:2:end),Nz,Nx,[]);
        bfdata_imag = reshape(rev(2:2:end),Nz,Nx,[]);
        img_temp(:,:,j) = bfdata_real + 1i* bfdata_imag;
    end
    bfdata = img_temp;
    save(fullfile(filepath,"IQ"+idx+".mat"),"bfdata",  "-v7.3")
    idx = idx+1;
    clear img_temp;


end



%释放显存和内存
calllib('US_GPU', 'deleteBeamformingGPUHandle', gpu_handle);

%卸载dll
unloadlibrary('US_GPU');
files = sort_files(filepath,'*.mat');
num_files =length (files);
show_flag = 0;
idx = 1;
cla(hfig);
if is_show==1
    for i = 1:num_files
        load(fullfile(files(i).folder ,files(i).name));
        [M,N,P] = size(bfdata);

        for j = 1:P

            img = log_compressed(abs(bfdata(:,:,j)));

            % img = d_tgc+img;
            if show_flag == 0

                show_flag = 1;
                % 获取屏幕尺寸
                % hImg = imagesc(AcqConfig.Rx.rev_line.x*100,AcqConfig.Rx.rev_line.z*100,img,'Parent', hfig);
                hImg = imagesc(img,'Parent', hfig);

                colormap(hfig,gray);
                clim(hfig,[-60, 0]);
                % axis(hfig,'equal', 'tight');
                axis(hfig,'tight');
                axis(hfig,'off');

                title(hfig, sprintf('Frame %d', idx));
                drawnow;
            else
                set(hImg, 'CData', img);
                title(hfig, sprintf('Frame %d', idx));
                drawnow;
                pause(0.02)
            end
            idx = idx+1;

        end

    end


end
end

 function out= GetADC(folder ,channel ,NumsPerFile ,SampleN, start_idx, end_idx)
files =dir (fullfile (folder ,'**' ,'*bin' ));
idx =1 ;
flag =1 ;
out =[];

num_files =length (files );
file_numbers =zeros (num_files ,1 );


for i =1 :num_files

    [~,file_name ]=fileparts (files (i ).name );


    try
        file_numbers (i )=str2double (file_name );
    catch

        file_numbers (i )=inf ;
    end
end


valid_indices =~isinf (file_numbers );
valid_files =files (valid_indices );
valid_numbers =file_numbers (valid_indices );


[~,sort_indices ]=sort (valid_numbers );
sorted_files =valid_files (sort_indices );

% 计算需要读取的文件范围
start_file_idx = floor(start_idx / NumsPerFile);  % 起始索引所在的文件
if(start_file_idx<1)
    start_file_idx = 1;
end
idx = (start_file_idx-1)*NumsPerFile+1;
for i =start_file_idx :length (sorted_files )

    FileName = fullfile (sorted_files (i ).folder ,sorted_files (i ).name );
    fileID =fopen (FileName ,'rb' );
    for j =1 :NumsPerFile
        temp = fread (fileID ,32+SampleN*channel*2,'int8' );
        if(idx < start_idx)
            idx =idx + 1;
            continue;
        elseif(idx > start_idx && idx < end_idx)
            out =[out ; temp ];
        elseif(idx == start_idx)
            out =[out ; temp ];
        elseif(idx == end_idx)
            out =[out ; temp ];
            flag =-1 ;
        end
        idx =idx + 1;

    end

    fclose (fileID );
    if(flag ==-1 )
        break;
    end
end

end
