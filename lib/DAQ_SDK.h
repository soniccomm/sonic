#pragma once
#include"stdint.h"
#pragma pack(push, 1)  // 1�ֽڶ��룬ȷ��MATLAB��C++�ṹ�岼��һ��
    struct DAQParameter
    {
        int     adc_fs;             // ������
        int     sample_num;         // ��������
        int     frame_num_in_callback; // һ�λص�֡��
        int     sensor_num;         // ͨ����
        unsigned short trigger_mode; // ����ģʽ
        unsigned short trigger_fs;  // ����Ƶ��
        unsigned short trigger_delay1; // �����ӳ�1
        unsigned short trigger_delay2; // �����ӳ�2
        unsigned short trigger_delay3; // �����ӳ�3
        unsigned char enable_upload; // ����ģʽʹ�ܼ���ѧ�����ϴ�ʹ��
        unsigned short tgc_gain1;    // tgc����1
        unsigned short tgc_gain2;    // tgc����2
        unsigned short tgc_gain3;    // tgc����3
        unsigned short vca_gain1;    // vca����1
        unsigned short vca_gain2;    // vca����2
        unsigned short vca_gain3;    // vca����3
        unsigned short trigger_shield; // ����ź����ο���
        unsigned char merge_channel_num; // ÿ��udp���İ���ͨ����
        unsigned char enable_2_network; // ���ù������
        unsigned char extra_port_num;  // ����˿�����
    };
#pragma pack(pop)
    // ������������
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
   int getOneFrameData(int8_t* data);//��ȡ��֡����
   int deleteDAQHandle();//�ͷ���Դ
   int SetIsSave(int isSave, const char* directoryName);// ������ģʽ

