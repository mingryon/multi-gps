% This function load or create the confige page struct. This struct will be
% used for receiver initialization.
function [configPage]=ConfigLoad(configOpt, GSAR_CONSTANTS, configFile)

if strcmp(configOpt, 'EXTERN')
    disp(['Using ''', configFile, ''' to configure GSARx!']);
    % TO DO: loading configs from the configFile
%     [GSAR_CONSTANTS, receiver] = ReadConfig(configFile, GSAR_CONSTANTS, receiver);
else
    % Construct config struct
    configPage = struct( ...
        'systConfig',      [], ...
        'acqConfig',       [], ...
        'hotAcqConfig',    [], ...
        'bitSyncConfig',   [], ...    
        'trackConfig',     [], ...
        'cadConfig',       [], ...
        'Pvt',             [] ...
    );
    %% SystConfig
    systConfig.BDS_B1I.maxPrnNo = 32;
    systConfig.BDS_B1I.satsInOperation = [1:15];
    
    systConfig.GPS_L1CA.maxPrnNo = 32;
    systConfig.GPS_L1CA.satsInOperation = [1:32];
    
    systConfig.GPS_L2C.maxPrnNo = 32;
    systConfig.GPS_L2C.satsInOperation = [1 3 5:10 12 15 17 24:27 29:32]; %available L2C sattellites after 2016/02/05
    
    configPage.systConfig = systConfig;
    %% Acq configs
    % Settings for BDS B1I GEO satellites
    % GEO Standard Settings: tcoh=1e-3, nnchList=[0 20 100], freqBin=250,
    %                        freqRange=2e3, coldFreqRange=2e3,
    %                        warmFreqRange=1e3, threhold=8(needs checked)
    acqConfig.BDS_B1I.GEO.tcoh           = 1e-3;       % Coherent integration time,[s]
    acqConfig.BDS_B1I.GEO.tcoh_hot       = 2e-3;       % Coherent integration time,[s]
    acqConfig.BDS_B1I.GEO.tcoh_fine      = 1e-3;   % Coherent integration time for fine acq
    acqConfig.BDS_B1I.GEO.ncoh_fine      = 20;
    acqConfig.BDS_B1I.GEO.nnchList       = [20 40]; % 0 is redundant; since the GEO's bit duration is 2ms, the pull
    acqConfig.BDS_B1I.GEO.freqBin        = 250;        %
    acqConfig.BDS_B1I.GEO.hotFreqBin     = 100;         % �ź�ʧ���ز����ò���
    acqConfig.BDS_B1I.GEO.fineFreqBin    = 50;         % ��������������
    acqConfig.BDS_B1I.GEO.freqRange      = 2e3;        % Frequency range for acquisition process
    acqConfig.BDS_B1I.GEO.coldFreqRange  = 2e3;        % Frequency range for cold acquisition
    acqConfig.BDS_B1I.GEO.warmFreqRange  = 1e3;        % Frequency range for warm acquisition, commonly half of cold one
    acqConfig.BDS_B1I.GEO.hotFreqRange   = 1e3;
    acqConfig.BDS_B1I.GEO.fineFreqRange  = 300;         % ���䲶�����ؽ��Ϊ���ģ��������������Χ
    acqConfig.BDS_B1I.GEO.thre_stronmode = 10.6;       % Acquisition detection threshold in strong mode
    acqConfig.BDS_B1I.GEO.thre_weakmode  = 13.0;       % Acquisition detection threshold in weak mode
    acqConfig.BDS_B1I.GEO.thre_fine      = 0.6;         % ���������޶���Ϊ����������䲶��ķ�ֵ����
    acqConfig.BDS_B1I.GEO.oscOffset      = 0;          % Freq offset from IF to all channels, simulating to the offset effect caused by oscillator
    
    % Settings for BDS B1I NGEO satellites
    % NGEO Standard Settings: tcoh=1e-3, nnchList=[0 20 100], freqBin=500,
    %                        freqRange=10e3, coldFreqRange=10e3,
    %                        warmFreqRange=1e3, threhold=8(needs checked)
    acqConfig.BDS_B1I.NGEO.tcoh          = 1e-3;      % Since the effects of NH codes, the longest coherent integration time is 1ms.
    acqConfig.BDS_B1I.NGEO.tcoh_hot      = 5e-3;
    acqConfig.BDS_B1I.NGEO.tcoh_fine     = 1e-3;   % Coherent integration time for fine acq
    acqConfig.BDS_B1I.NGEO.ncoh_fine     = 20;
    acqConfig.BDS_B1I.NGEO.nnchList      = [20 40];   % 0 is redundant; 20 corresponding to strong singal; 100 corresponding to weak signal.
    acqConfig.BDS_B1I.NGEO.freqBin       = 500;       % frequency search step [Hz], relative to the parameter 'tcoh'
    acqConfig.BDS_B1I.NGEO.hotFreqBin    = 100;       %
    acqConfig.BDS_B1I.NGEO.fineFreqBin   = 50;        % ��������������
    acqConfig.BDS_B1I.NGEO.freqRange     = 12e3;      % frequency search range, -5KHz ~ +5KHz
    acqConfig.BDS_B1I.NGEO.coldFreqRange = 12e3;      % Frequency range for cold acquisition
    acqConfig.BDS_B1I.NGEO.warmFreqRange = 1e3;       % Frequency range for warm acquisition, commonly half of cold one
    acqConfig.BDS_B1I.NGEO.hotFreqRange  = 1e3;
    acqConfig.BDS_B1I.NGEO.fineFreqRange = 600;       % ���䲶�����ؽ��Ϊ���ģ��������������Χ
    acqConfig.BDS_B1I.NGEO.thre_stronmode= 10.6;      % Acquisition detection threshold in strong mode
    acqConfig.BDS_B1I.NGEO.thre_weakmode = 13.0;      % Acquisition detection threshold in weak mode
    acqConfig.BDS_B1I.NGEO.thre_fine     = 0.6;       % ���������޶���Ϊ����������䲶��ķ�ֵ����
    acqConfig.BDS_B1I.NGEO.oscOffset     = 0;         % Freq offset from IF to all channels, simulating to the offset effect caused by oscillator
    
    % Settings for GPS L1CA satellites
    % MEO Standard Settings: tcoh=1e-3, nnchList=[0 20 100], freqBin=500,
    %                        freqRange=10e3, coldFreqRange=10e3,
    %                        warmFreqRange=1e3, threhold=8(needs checked)
    acqConfig.GPS_L1CA.tcoh               = 1e-3;       % Coherent integration time 
    acqConfig.GPS_L1CA.tcoh_hot           = 5e-3;
    acqConfig.GPS_L1CA.tcoh_fine          = 10e-3;   % Coherent integration time for fine acq
    acqConfig.GPS_L1CA.ncoh_fine          = 4;       % 1ms*20 or 2ms*10 or 10ms*4 recommended
    acqConfig.GPS_L1CA.nnchList           = [20 40];  % 0 is redundant
    acqConfig.GPS_L1CA.freqBin            = 500;
    acqConfig.GPS_L1CA.hotFreqBin         = 100;
    acqConfig.GPS_L1CA.fineFreqBin        = 50;       %��������������
    acqConfig.GPS_L1CA.freqRange          = 12e3;        % Frequency range for acquisition process
    acqConfig.GPS_L1CA.coldFreqRange      = 12e3;        % Frequency range for cold acquisition
    acqConfig.GPS_L1CA.warmFreqRange      = 1e3;        % Frequency range for warm acquisition, commonly half of cold one
    acqConfig.GPS_L1CA.hotFreqRange       = 600;
    acqConfig.GPS_L1CA.fineFreqRange      = 600;      %���䲶�����ؽ��Ϊ���ģ��������������Χ
    acqConfig.GPS_L1CA.thre_stronmode     = 10.6;
    acqConfig.GPS_L1CA.thre_weakmode      = 13.0;
    acqConfig.GPS_L1CA.oscOffset          = 0;          % Freq offset from IF to all channels, simulating to the offset effect caused by oscillator

    %L1CA����L2C�������
    acqConfig.GPS_L2C_aid.tcoh               = 20e-3;       % �̶�20ms,��� 
    %acqConfig.GPS_L2C_aid.tcoh_hot           = 20e-3;
    acqConfig.GPS_L2C_aid.ncoh               = 1;          %����ɻ��ִ���
    acqConfig.GPS_L2C_aid.freqBin            = 35;       %CM�䲶ʱ����������
    %acqConfig.GPS_L2C_aid.warmFreqBin        = 35;
    %acqConfig.GPS_L2C_aid.hotFreqBin         = 35;
    acqConfig.GPS_L2C_aid.freqRange      = 70;        % Frequency range for cold acquisition
    %acqConfig.GPS_L2C_aid.warmFreqRange      = 70;
    %acqConfig.GPS_L2C_aid.hotFreqRange       = 70;
    acqConfig.GPS_L2C_aid.thre_CM            = 5;      %����Ϊ��CM�����ֵ������19����λ�ľ�ֵ��
    acqConfig.GPS_L2C_aid.thre_CL            = 0.6;    %����Ϊ��CL�����ֵ��CM�����ֵ��
    acqConfig.GPS_L2C_aid.oscOffset          = 0;      %L2Ƶ��Ľ��ջ���Ƶ���У����
    

    
    configPage.acqConfig = acqConfig;
    
    %% BitSync config
    % ******************* Beidou System ***********************
    % Settings for BDS B1I GEO satellites
    % GEO Standard Settings: tcoh=2e-3(T_D2), nnchList=[50 100], freqBin=50,
    %                        freqRange=500, threhold=5/4(needs checked)
    bitSyncConfig.BDS_B1I.GEO.tcoh           = GSAR_CONSTANTS.STR_B1I.T_D2; % coherent integration time,[s]
    bitSyncConfig.BDS_B1I.GEO.nnchList       = [100,120];   % 25 non-coherent of T_D2 coherent is equivalent 100ms at all
    bitSyncConfig.BDS_B1I.GEO.freqBin        = 50;   % Hz
    bitSyncConfig.BDS_B1I.GEO.hotFreqBin     = 20;
    bitSyncConfig.BDS_B1I.GEO.freqRange      = 500;  % -250Hz ~ 250Hz
    bitSyncConfig.BDS_B1I.GEO.hotFreqRange   = 120;
    bitSyncConfig.BDS_B1I.GEO.threshold      = 5/4;
    bitSyncConfig.BDS_B1I.GEO.fcorrect       = 1;
    bitSyncConfig.BDS_B1I.GEO.waitSec        = 2;   % ����ͬ�����ɹ���ĵȴ�ʱ�� (��)
    bitSyncConfig.BDS_B1I.GEO.waitTimes      = 1;
    % Settings for BDS B1I NGEO satellites
    % NGEO Standard Settings: tcoh=10e-3, nnchList=[10 20], freqBin=50,
    %                        freqRange=600, threhold=5/4(needs checked)
    bitSyncConfig.BDS_B1I.NGEO.tcoh           = 10e-3; % coherent integration time,[s]. 0.01s is expected.
    bitSyncConfig.BDS_B1I.NGEO.nnchList       = [30,50];   % 10 non-coherent of 10ms coherent is equivalent 100ms at all.
    bitSyncConfig.BDS_B1I.NGEO.freqBin        = 50;   % Hz, 50Hz is fit for coherent integration time of 0.01s.
    bitSyncConfig.BDS_B1I.NGEO.hotFreqBin     = 20;
    bitSyncConfig.BDS_B1I.NGEO.freqRange      = 600;  % -250Hz ~ 250Hz
    bitSyncConfig.BDS_B1I.NGEO.hotFreqRange   = 120;
    bitSyncConfig.BDS_B1I.NGEO.threshold      = 5/4;
    bitSyncConfig.BDS_B1I.NGEO.fcorrect       = 1;
    bitSyncConfig.BDS_B1I.NGEO.waitSec        = 2;   % ����ͬ�����ɹ���ĵȴ�ʱ�� (��)
    bitSyncConfig.BDS_B1I.NGEO.waitTimes      = 1;
    % ******************* GPS System ***********************
    % Settings for GPS L1CA MEO satellites
    % MEO Standard Settings: tcoh=10e-3, nnchList=[10 20], freqBin=50,
    %                        freqRange=600, threhold=5/4(needs checked)
    bitSyncConfig.GPS_L1CA.tcoh                = 20e-3; % coherent integration time,[s].
    bitSyncConfig.GPS_L1CA.nnchList            = [50, 60];   % 10 non-coherent of 10ms coherent is equivalent 100ms at all.
    bitSyncConfig.GPS_L1CA.freqBin             = 50;   % Hz
    bitSyncConfig.GPS_L1CA.hotFreqBin          = 20;
    bitSyncConfig.GPS_L1CA.freqRange           = 100;  % -250Hz ~ 250Hz
    bitSyncConfig.GPS_L1CA.hotFreqRange        = 120;
    bitSyncConfig.GPS_L1CA.threshold           = 1;
    bitSyncConfig.GPS_L1CA.fcorrect            = 1;    %
    bitSyncConfig.GPS_L1CA.waitSec             = 2;   % ����ͬ�����ɹ���ĵȴ�ʱ�� (��)
    bitSyncConfig.GPS_L1CA.waitTimes           = 1;
    configPage.bitSyncConfig = bitSyncConfig;
    
    %% Track config
    % Common config parameters
    trackConfig.pll.Bn = 10;       % Standard config: Bn=10
    trackConfig.pll.Ord = 3;      % Standard config: Ord=3
    trackConfig.pll.Fn = 3;       % Standard config: Fn=3
    trackConfig.pll.LoopType = 'KALMAN';% PLL_FEEDBACK / FLL_OPEN(unused) / KALMAN
    
    trackConfig.dll.Dn = 1;       % Standard config: Dn=1
    trackConfig.dll.Ord = 1;      % Standard config: Ord=1
    trackConfig.dll.SPACING = 0.1;% Standard config: SPACING=0.1
    trackConfig.dll.SPACING_MP=0.2; %  Standard config: SPACING=0.2
    
    trackConfig.kalmanFilt.P0 = [0.25, 20, 500, 10]';% diagnal values
    trackConfig.kalmanFilt.Q  = [1e-2, 1e-3, 1e-2, 10]';% state process variance
    trackConfig.kalmanFilt.R  = [0.1, 0.1]';% measurement error variance
    
    %L1CA-L2C����ģʽ��KALMAN_JOINT / KALMAN_APART / KALMAN_PILOT / PLL_APART / PLL_PILOT
    trackConfig.L2C_trk_mode = 'KALMAN_JOINT';
    %��ʼԤ��Э�������Ϊ��...
    ...L1����λ(chip^2), L1�ز���λ(rad^2),L1������(Hz^2),...
    ...L1���ٶ�(Hz^2/s^2),L1�ز����۲������ӳ�(cycle^2),L1�뻷�۲������ӳ�(cycle^2)
    trackConfig.kalmanFilt_L1L2.P0 = [0.1, 1, 500, 10, 1, 600]';
    %Q0��������ģ�͵Ĺ���������������Ϊ��...
    ...����λ����(chip^2/s)��L1�ز���λ����(cycle^2/s),L1Ƶ������(Hz^2/s), ...
    ...��̬����(Hz^2/s^3), �ز������������(cycle^2/s), �뻷���������(cycle^2/s)
    trackConfig.kalmanFilt_L1L2.Q  = [5e-12, 1.2e-3, 0.98, 10, 1e-5, 1e-5]';
    %���������������ΪCA,CM,CL�뻷���(chip^2),CA,CM,CL�������(rad^2)
    trackConfig.kalmanFilt_L1L2.R  = [0.01, 0.01, 0.01, 0.01, 0.01, 0.01]';
    
    trackConfig.all.An  = 5;       % Standard config: An=5
    trackConfig.all.AFn = 0.5;      % Standard config: AFn=0.5
    trackConfig.all.a_kalfilt_P0 = [1, 0.1]';
    trackConfig.all.a_kalfilt_Q  = [0.01, 0.01]';
    trackConfig.all.a_kalfilt_R  = 0.01;
    
    trackConfig.lockDect.sigma_checkT = 1;
    trackConfig.lockDect.sigmaThrelol = 0.0035; % 0.015;(previsouly)
    trackConfig.lockDect.snrThrelol = 20;  % 15 (previsouly)
    
    configPage.trackConfig = trackConfig;
    
    %% CADLL config
    cadConfig.CadUnitMax = 1;
    cadConfig.MonitoringTime = 1; % monitoring time before making a decision;
    % settings for BDS B1I
    cadConfig.BDS_B1I.CadU2_CodeIni  = 0.1;%Initial code phase delay in chips with respect to the first unit when inserting the second unit;
    cadConfig.BDS_B1I.CadUin_CodeIni = 0.1;% The initial code phase delay in chips with respect the unit before when inserting the third and more units
    cadConfig.BDS_B1I.CadUin_AIni    = 0;  % The initial amplitude of the inserted unit with repsect to the unit before;
    cadConfig.BDS_B1I.CadUin_ThetaIni= 0.5;% The initial carrier phase of the inserted unit with repsect to the unit before, [cycles];
    
    cadConfig.BDS_B1I.CodPhsLagThre1 = 0.05;%The mandatory code phase lag by force between two adjacent units,[chips]
    cadConfig.BDS_B1I.CodPhsLagThre2 = 0.09;%The code phase lag threshold of two adjacent units; the latter unit will be shut down if its code phase delay is less than the threshold
    cadConfig.BDS_B1I.CodPhsLag_Insrt_Thre3 = 0.2;% The least code phase lag between two adjacent units between that a trial unit can be inserted;
    
    cadConfig.BDS_B1I.SNRThre1       = 0; % permitted minimum SNR1 (estimated)
    cadConfig.BDS_B1I.SNRThre2       = -2;
    cadConfig.BDS_B1I.SNRThre3       = -4;
    cadConfig.BDS_B1I.SNRThre4       = -6;
    
    cadConfig.BDS_B1I.AThreLow1      = 0.13;
    cadConfig.BDS_B1I.AThreLow2      = 0.11;
    cadConfig.BDS_B1I.AThreLow3      = 0.09;
    cadConfig.BDS_B1I.ADevThre       = 3; % permitted maximum std deviation ratio of estimated amplitude to noise's;
    
    % settings for GPS L1CA
    cadConfig.GPS_L1CA.CadU2_CodeIni  = 0.1;%Initial code phase delay in chips with respect to the first unit when inserting the second unit;
    cadConfig.GPS_L1CA.CadUin_CodeIni = 0.1;% The initial code phase delay in chips with respect the unit before when inserting the third and more units
    cadConfig.GPS_L1CA.CadUin_AIni    = 0;  % The initial amplitude of the inserted unit with repsect to the unit before;
    cadConfig.GPS_L1CA.CadUin_ThetaIni= 0.5;% The initial carrier phase of the inserted unit with repsect to the unit before, [cycles];
    
    cadConfig.GPS_L1CA.CodPhsLagThre1 = 0.05;%The mandatory code phase lag by force between two adjacent units,[chips]
    cadConfig.GPS_L1CA.CodPhsLagThre2 = 0.09;%The code phase lag threshold of two adjacent units; the latter unit will be shut down if its code phase delay is less than the threshold
    cadConfig.GPS_L1CA.CodPhsLag_Insrt_Thre3 = 0.2;% The least code phase lag between two adjacent units between that a trial unit can be inserted;
    
    cadConfig.GPS_L1CA.SNRThre1       = 2; % permitted minimum SNR1 (estimated)
    cadConfig.GPS_L1CA.SNRThre2       = 0;
    cadConfig.GPS_L1CA.SNRThre3       = -2;
    cadConfig.GPS_L1CA.SNRThre4       = -4;
    
    cadConfig.GPS_L1CA.AThreLow1      = 0.13;
    cadConfig.GPS_L1CA.AThreLow2      = 0.11;
    cadConfig.GPS_L1CA.AThreLow3      = 0.09;
    cadConfig.GPS_L1CA.ADevThre       = 5; % permitted maximum std deviation ratio of estimated amplitude to noise's;
    
    configPage.cadConfig = cadConfig;
    
    %% PVT config
    Pvt.pseudorangePreErrThre = 50;
    configPage.Pvt = Pvt;
end