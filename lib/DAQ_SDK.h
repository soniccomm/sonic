#pragma once
#include"stdint.h"
#pragma pack(push, 1)  // 1字节对齐，确保MATLAB和C++结构体布局一致
    struct DAQParameter
    {
        int     adc_fs;             // 采样率
        int     sample_num;         // 采样点数
        int     frame_num_in_callback; // 一次回调帧数
        int     sensor_num;         // 通道数
        unsigned short trigger_mode; // 触发模式
        unsigned short trigger_fs;  // 触发频率
        unsigned short trigger_delay1; // 触发延迟1
        unsigned short trigger_delay2; // 触发延迟2
        unsigned short trigger_delay3; // 触发延迟3
        unsigned char enable_upload; // 计算模式使能及声学数据上传使能
        unsigned short tgc_gain1;    // tgc增益1
        unsigned short tgc_gain2;    // tgc增益2
        unsigned short tgc_gain3;    // tgc增益3
        unsigned short vca_gain1;    // vca增益1
        unsigned short vca_gain2;    // vca增益2
        unsigned short vca_gain3;    // vca增益3
        unsigned short trigger_shield; // 光电信号屏蔽开启
        unsigned char merge_channel_num; // 每个udp报文包含通道数
        unsigned char enable_2_network; // 启用光口数量
        unsigned char extra_port_num;  // 额外端口数量
    };
#pragma pack(pop)
    // 导出函数声明
   void set_afe_reg(int id, int val);
   void set_tvg_arg(int tvg_serial_num, int tvg_serial_id, int tvg_val, int tvg_attenuation_time);
   void set_prt_arg(int scanlenth, int triggerdelay, int scantime, int repeatNum);
   void set_tx_arg(int tx_ind, int serial_num, int duty_ratio, int pulse_num, unsigned short tx_delay, int tx_fs_decimator, int tx_mode, int command_code, int command_val);
   void set_afe_mode(int mode_num, int mode_id, int profile_id, int line_num, int line_start_id);
   void set_afe_profile(int profile_num, int profile_id, int val[],int vallen);
   void set_afe_filter(int filter_num, int filter_id, int val0, int val1, int val2, int val3, int val4, int val5, int val6, int val7);
   void set_scanHead(int frame, int sln, int mode_type, int pack_size, int beam, int pulse_type, int frame_end, int frame_start, int scan_len);
   int setDAQ(struct DAQParameter param, int opticalPort);
   int start_saveFile(int onceSampleLen, int onceReceiveLen,const char* directoryName,int packageCount);
   int start_sample(int onceSampleLen, int onceReceiveLen);
   void set_Debug(int isOut);
   int stop_sample();
   int close_sample();
   int RunRealTime(int SteeringNum, int oneframeSize);
   int getOneFrameData(int8_t* data);//获取单帧数据
   int deleteDAQHandle();//释放资源
   int SetIsSave(int isSave, const char* directoryName);// 存数据模式

