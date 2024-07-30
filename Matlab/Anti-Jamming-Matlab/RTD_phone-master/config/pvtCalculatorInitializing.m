function [pvtCalculator]= pvtCalculatorInitializing(pvtCalculator, config)

%���¼��������ĳ�ʼ��-1����pvtCalculator���״�ִ�е�״̬
pvtCalculator.positionValid = -1;
pvtCalculator.posiTag       = -1;
pvtCalculator.posiCheck     = -1;
pvtCalculator.timeLast      = -1;

pvtCalculator.pvtSats(1).pvtS_prnList = zeros(1, config.recvConfig.numberOfChannels(1).channelNum); % For BDS channels
pvtCalculator.pvtSats(2).pvtS_prnList = zeros(1, config.recvConfig.numberOfChannels(2).channelNum); % For BDS channels

pvtCalculator.VTEC_L1 = 0;  %L1Ƶ�㴹ֱ�������ʱ��m)
pvtCalculator.L2toL1_devDelay = 0; %L2Ƶ�������L1Ƶ��Ľ��ջ��豸ʱ�ӣ�m)

%% ---- Initialize pvtCalculator Accumulated Doppler measurements -------
BDS_maxPrnNo = config.recvConfig.configPage.systConfig.BDS_B1I.maxPrnNo;      % ���������Ŀ
GPS_maxPrnNo = config.recvConfig.configPage.systConfig.GPS_L1CA.maxPrnNo;     % ���������Ŀ

pvtCalculator.BDS.hatchValue = zeros(BDS_maxPrnNo, 3);
pvtCalculator.BDS.sateStatus = 2e10*ones(3,BDS_maxPrnNo);
% BDS.doppSmooth: matrix [BDS_maxPrnNo x 4]
% col1 - ��ǰʱ�̵Ļ��ֶ�����ֵ
% col2 - ǰһʱ�̵Ļ��ֶ�����ֵ
% col3 - ��ǰʱ�̵Ķ�����ֵ
% col4 - flag for valid continuous two smothDoppler values
pvtCalculator.BDS.doppSmooth = zeros(BDS_maxPrnNo,4);
pvtCalculator.BDS.SNR = zeros(1, BDS_maxPrnNo);
pvtCalculator.BDS.CNR = zeros(1, BDS_maxPrnNo);
pvtCalculator.BDS.carriVar = zeros(1, BDS_maxPrnNo);
pvtCalculator.BDS.SOW = -1 * ones(1, BDS_maxPrnNo);   % ��һλΪ��ֵ
pvtCalculator.BDS.subFrameID = -1 * ones(1, BDS_maxPrnNo);   % ��һλΪ��ֵ

pvtCalculator.GPS.hatchValue = zeros(GPS_maxPrnNo, 3);
pvtCalculator.GPS.sateStatus = 2e10*ones(3,GPS_maxPrnNo);
% GPS.doppSmooth: matrix [GPS_maxPrnNo x 4] (same definition as BDS.doppSmooth)
pvtCalculator.GPS.doppSmooth = zeros(GPS_maxPrnNo,4);
pvtCalculator.GPS.SNR = zeros(1, GPS_maxPrnNo);
pvtCalculator.GPS.CNR = zeros(1, GPS_maxPrnNo);
pvtCalculator.GPS.carriVar = zeros(1, GPS_maxPrnNo);
pvtCalculator.GPS.SOW = -1 * ones(1, GPS_maxPrnNo);   % ��һλΪ��ֵ
pvtCalculator.GPS.subFrameID = -1 * ones(1, GPS_maxPrnNo);   % ��һλΪ��ֵ
% log ini
pvtCalculator.logOutput.GPSephUpdate = zeros(1,GPS_maxPrnNo);
pvtCalculator.logOutput.BDSephUpdate = zeros(1,BDS_maxPrnNo);
pvtCalculator.logOutput.GPSionoUpdate = zeros(1,GPS_maxPrnNo);
pvtCalculator.logOutput.rawP = [];
pvtCalculator.logOutput.satClkErr = [];
pvtCalculator.logOutput.satPos = [];
pvtCalculator.logOutput.transmitTime = [];
pvtCalculator.logOutput.logReady = 0;
pvtCalculator.logOutput.logTimes = 0;

%% ----------- Initialize Kalman filter --------------
pvtCalculator.kalman.preTag = 0;% Kalman filter initialization flag: 1 - initialized
%pvtCalculator.kalman.state  = zeros(8,1);%[x,y,z,vx,vy,vz,dt,dtf]
pvtCalculator.kalman.stt_x  = zeros(3,1); %[x,vx], x-component position-velocity state vector
pvtCalculator.kalman.stt_y  = zeros(3,1); %[y,vy], y-component position-velocity state vector
pvtCalculator.kalman.stt_z  = zeros(3,1); %[z,vz], z-component position-velocity state vector
pvtCalculator.kalman.stt_dtf= zeros(3,2); %acc������bias
pvtCalculator.kalman.T      = pvtCalculator.pvtT;

pvtCalculator.kalman.Ac     = [1, pvtCalculator.kalman.T,(pvtCalculator.kalman.T)^2/2; 0, 1,pvtCalculator.kalman.T;0,0,1];
% pvtCalculator.kalman.Ac     = [1, pvtCalculator.kalman.T,0; 0, 1,0;0,0,1];
Sp =1;
Sv =0.1; % [(m/s)^2], the noise spectrum of one-axis velocity component, which is applicable to x,y,or z component
Sa = 0.01;
Qa = 0.0001;
% pvtCalculator.kalman.Qp     = Sp*[pvtCalculator.kalman.T, 0; 0, 0] + Sv*[(pvtCalculator.kalman.T)^3/3, (pvtCalculator.kalman.T)^2/2; (pvtCalculator.kalman.T)^2/2, pvtCalculator.kalman.T];
Qp = Sp*[pvtCalculator.kalman.T, 0, 0; 0, 0, 0; 0, 0, 0] + Sv*[(pvtCalculator.kalman.T)^3/3, (pvtCalculator.kalman.T)^2/2, 0; (pvtCalculator.kalman.T)^2/2, pvtCalculator.kalman.T, 0; 0, 0, 0]+Sa*[(pvtCalculator.kalman.T)^5/20, (pvtCalculator.kalman.T)^4/8, (pvtCalculator.kalman.T)^3/6;(pvtCalculator.kalman.T)^4/8,(pvtCalculator.kalman.T)^3/3,(pvtCalculator.kalman.T)^2/2; (pvtCalculator.kalman.T)^3/6,(pvtCalculator.kalman.T)^2/2,(pvtCalculator.kalman.T)];
pvtCalculator.kalman.Qp =blkdiag(Qp,Qa);

pvtCalculator.kalman.Rv      = [0;0]; %��������R����Ĳ���
pvtCalculator.kalman.Pxyz0  = [30; 3;1;1];%��������P�ĳ�ֵ
Ra = 0.01;
pvtCalculator.kalman.Ra=[Ra;Ra;Ra];
%��������Qb�����������õ�
St = 2; % [m], the noise spectrum of the clk error dt, which is applicable to any system clk error
Sf =0.1; % [m/s], the noise spectrum of the clk drift, which is applicable to any system
Saf =0.01;%������ֵ��˫�����Ӱ�죬���۾޴��Ǿ�С
% pvtCalculator.kalman.Qb     = St*[pvtCalculator.kalman.T, 0; 0, 0] + Sf*[(pvtCalculator.kalman.T)^3/3, (pvtCalculator.kalman.T)^2/2; (pvtCalculator.kalman.T)^2/2, pvtCalculator.kalman.T];
pvtCalculator.kalman.Qb     = St*[pvtCalculator.kalman.T, 0, 0; 0, 0, 0; 0, 0, 0] + Sf*[(pvtCalculator.kalman.T)^3/3, (pvtCalculator.kalman.T)^2/2, 0; (pvtCalculator.kalman.T)^2/2, pvtCalculator.kalman.T, 0; 0, 0, 0]+Saf*[(pvtCalculator.kalman.T)^5/20, (pvtCalculator.kalman.T)^4/8, (pvtCalculator.kalman.T)^3/6;(pvtCalculator.kalman.T)^4/8,(pvtCalculator.kalman.T)^3/3,(pvtCalculator.kalman.T)^2/2; (pvtCalculator.kalman.T)^3/6,(pvtCalculator.kalman.T)^2/2,(pvtCalculator.kalman.T)];
% Observation noise variance: sigma2 for pseudorange; sigma2 for Doppler pseudorange
% This variance is only the floor value, it should be added an additional
% value from the computed SNR or CNR of the satellite.

% pvtCalculator.kalman.Pb0    = [10; 2;5];%���һ��������Ϲ�ɵ�

% pvtCalculator.kalman.Pxyz.Psub = zeros(2,2);
% pvtCalculator.kalman.Pxyz(1:3) = pvtCalculator.kalman.Pxyz;
% pvtCalculator.kalman.Pb(1:2) = pvtCalculator.kalman.Pb;

% pvtCalculator.kalman.PHI    = [eye(3), pvtCalculator.kalman.T*eye(3), zeros(3,2);
%                                zeros(3), eye(3), zeros(3,2);
%                                zeros(2,3), zeros(2,3), [1, pvtCalculator.kalman.T; 0, 1]];
% % Q:system transimtion noise vector, [px; py; pz; vx; vy; vz; cdt(Sf); cdf(Sg)];
% pvtCalculator.kalman.Q      = [0.1; 0.1; 0.1; 25; 25; 25; 20; 0.01];
% Qpx   = pvtCalculator.kalman.Q(1)*pvtCalculator.kalman.T + pvtCalculator.kalman.Q(4)*(pvtCalculator.kalman.T)^3/3;
% Qpy   = pvtCalculator.kalman.Q(2)*pvtCalculator.kalman.T + pvtCalculator.kalman.Q(5)*(pvtCalculator.kalman.T)^3/3;
% Qpz   = pvtCalculator.kalman.Q(3)*pvtCalculator.kalman.T + pvtCalculator.kalman.Q(6)*(pvtCalculator.kalman.T)^3/3;
% Qpv_x = pvtCalculator.kalman.Q(4)*(pvtCalculator.kalman.T)^2/2;
% Qpv_y = pvtCalculator.kalman.Q(5)*(pvtCalculator.kalman.T)^2/2;
% Qpv_z = pvtCalculator.kalman.Q(6)*(pvtCalculator.kalman.T)^2/2;
% Qvx   = pvtCalculator.kalman.Q(4)*pvtCalculator.kalman.T;
% Qvy   = pvtCalculator.kalman.Q(5)*pvtCalculator.kalman.T;
% Qvz   = pvtCalculator.kalman.Q(6)*pvtCalculator.kalman.T;
% Qb    = pvtCalculator.kalman.Q(7)*pvtCalculator.kalman.T + pvtCalculator.kalman.Q(8)*(pvtCalculator.kalman.T)^3/3;
% Qbd   = pvtCalculator.kalman.Q(8)*(pvtCalculator.kalman.T)^2/2;
% Qd    = pvtCalculator.kalman.Q(8)*pvtCalculator.kalman.T;
% % Qw: system transimtion covirance matrix in digitial system, [8x8]
% pvtCalculator.kalman.Qw     = [Qpx, 0, 0, Qpv_x, 0, 0, 0, 0;
%                                0, Qpy, 0, 0, Qpv_y, 0, 0, 0;
%                                0, 0, Qpz, 0, 0, Qpv_z, 0, 0;
%                                Qpv_x, 0, 0, Qvx, 0, 0, 0, 0;
%                                0, Qpv_y, 0, 0, Qvy, 0, 0, 0;
%                                0, 0, Qpv_z, 0, 0, Qvz, 0, 0;
%                                0, 0, 0, 0, 0, 0, Qb, Qbd;
%                                0, 0, 0, 0, 0, 0, Qbd, Qd];
% % Observation noise variance: sigma2 for pseudorange; sigma2 for Doppler pseudorange
% % This variance is only the floor value, it should be added an additional
% % value from the computed SNR or CNR of the satellite.
% pvtCalculator.kalman.Rv     = [0.5; 0.1]; 
% pvtCalculator.kalman.P0     = [30; 30; 30; 3; 3; 3; 10; 10];
% pvtCalculator.kalman.P      = diag(pvtCalculator.kalman.P0);
% 
end