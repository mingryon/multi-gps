%% Initialize time structure.
function [time]= TimerInitializing(time, config)
time.recvSOW = -1;    % ���ջ�����ʱ��
time.recvSOW_BDS = -1;    % ������ϵͳʱ�䣩
time.recvSOW_GPS = -1;    % ��GPSϵͳʱ�䣩
time.weeknum = -1;  % ����
time.weeknum_BDS = -1;  % ������
time.weeknum_GPS = -1;  % GPS��
time.year = -1;
time.month = -1;
time.day = -1;
time.hour = -1;
time.min = -1;
time.sec = -1;
time.timeType = config.recvConfig.timeType;   % NULL / GPST / BDST / UTC
time.timeCheck = -1;  % ʱ��ȷ�ϱ�־λ
time.rclkErr2Syst_UpCnt = ones(size(time.rclkErr2Syst_UpCnt)) * time.rclkErr2Syst_Thre;
time.BDT2GPST = [14, 332];  % [SOW, week]
time.tNext = -1;  % ��һ�ζ�λ��ʱ��
time.CL_time = -1;
end
