function [channel] = acq_proc(config, channel, satelliteTable, sis, N)
global GSAR_CONSTANTS;

%% ������������������������������������������������ GPS L1 ͨ������ ������������������������������������������������%  
if strcmp(channel.SYST, 'GPS_L1CA')
    % Acquisition for GPS L1 C/A signal
    [channel.CH_L1CA, channel.CH_L1CA.acq.acqResults] = acquireGPS(channel.CH_L1CA, sis, channel.CH_L1CA.acq.acqResults, channel.bpSampling_OddFold, config.logConfig);
    
    %������������������������������������������������ �źŲ���ɹ� ������������������������������������������������%   
    if (channel.CH_L1CA.acq.acqResults.acqed == 1) % �źŲ���ɹ�
        if channel.CH_L1CA.acq.acqID == 0
            channel.CH_L1CA.LO2_fd = channel.CH_L1CA.LO2_fd + channel.CH_L1CA.acq.acqResults.doppler; % + acq_cfg.oscOffset;
            channel.CH_L1CA.LO_Fcode_fd = channel.bpSampling_OddFold * channel.CH_L1CA.LO2_fd / GSAR_CONSTANTS.STR_L1CA.L0Fc0_R;
            channel.CH_L1CA.LO_CodPhs = 0;
            channel.CH_L1CA.CN0_Estimator.CN0 = 10 * log10(channel.CH_L1CA.acq.acqResults.snr / channel.CH_L1CA.acq.acq_parameters.tcoh);
            channel.CH_L1CA.Samp_Posi = channel.CH_L1CA.Samp_Posi + channel.CH_L1CA.acq.acqResults.codeIdx;
            channel.CH_L1CA.acq.TimeLen = channel.CH_L1CA.acq.TimeLen + channel.CH_L1CA.acq.acqResults.codeIdx;
            channel.CH_L1CA.Samp_Posi = channel.CH_L1CA.Samp_Posi - channel.CH_L1CA.acq.resiN;      % �۳�resiData�е����ݵ���
            channel.CH_L1CA.acq.resiN = 0;
            channel.CH_L1CA.acq.acqID = 1;
            channel.CH_L1CA.acq.resiData = [];
            channel.CH_L1CA.acq.corrtmp = [];
            channel.CH_L1CA.acq.corr = [];
        end
        while (channel.CH_L1CA.Samp_Posi < 0)
            nPerCode = round(1/(GSAR_CONSTANTS.STR_L1CA.Fcode0+channel.CH_L1CA.LO_Fcode_fd)*GSAR_CONSTANTS.STR_L1CA.ChipNum*GSAR_CONSTANTS.STR_RECV.RECV_fs0);%���Ƕ�����Ƶ�ƺ��1��ca���������
            channel.CH_L1CA.Samp_Posi = channel.CH_L1CA.Samp_Posi + nPerCode;
            channel.CH_L1CA.acq.TimeLen = channel.CH_L1CA.acq.TimeLen + nPerCode;
        end
        if channel.CH_L1CA.Samp_Posi >= N
            if strcmp(channel.STATUS, 'COLD_ACQ')
                channel.STATUS = 'COLD_ACQ';
            elseif strcmp(channel.STATUS, 'COLD_ACQ_AGAIN')
                channel.STATUS = 'COLD_ACQ_AGAIN';
            elseif strcmp(channel.STATUS, 'HOT_ACQ')
                channel.STATUS = 'HOT_ACQ'; 
            end
            channel.CH_L1CA.Samp_Posi =  channel.CH_L1CA.Samp_Posi - N;
        else
    %������������������������������������������������ bitͬ������ ������������������������������������������������% 
            if strcmp(channel.STATUS, 'COLD_ACQ') || strcmp(channel.STATUS, 'COLD_ACQ_AGAIN')               % ����������ɹ�
                channel.CH_L1CA.acq.ACQ_STATUS = 1; %������
            
            elseif strcmp(channel.STATUS, 'HOT_ACQ')            % ����������ɹ�
                channel.STATUS = 'HOT_BIT_SYNC';
                channel.CH_L1CA.CH_STATUS = channel.STATUS;
                channel = hotBitSync_init(channel, config); % ʧ���ز������²�������
                timeLen = round(channel.CH_L1CA.acq.TimeLen); % ������ʱ������N������ÿ�ν���channel_scheduler�л���N������
                [verify, channel.CH_L1CA] = hotInfoCheck(channel.CH_L1CA, timeLen, channel.SYST,'ACQ'); % ������������Ԥ��ĸ����������ȷ��
            end
%             fprintf('                    GPS PRN%d AcqResults -- CodeIndx: %d ; Doppler: %.2fHz ; CN0: %.1fdB \n', ...
%                 channel.CH_L1CA.PRNID, channel.CH_L1CA.Samp_Posi, channel.bpSampling_OddFold*channel.CH_L1CA.LO2_fd, channel.CH_L1CA.CN0_Estimator.CN0);
            fprintf('CodeIndx: %d ; Doppler: %.2fHz ; CN0: %.1fdB \n', ...
                channel.CH_L1CA.Samp_Posi, channel.bpSampling_OddFold*channel.CH_L1CA.LO2_fd, channel.CH_L1CA.CN0_Estimator.CN0);
        end
        
    %������������������������������������������������ �źŲ���ʧ�� ������������������������������������������������% 
    elseif (channel.CH_L1CA.acq.acqResults.acqed == -1) % �źŲ���ʧ��
        if strcmp(channel.STATUS, 'COLD_ACQ')           % �䲶��ʧ��
            if satelliteTable(2).satVisible(channel.CH_L1CA.PRNID)==1 % ���ж����ǿɼ��򲶻�����
                channel.STATUS = 'COLD_ACQ_AGAIN';
                channel.CH_L1CA.CH_STATUS = channel.STATUS;
                channel.CH_L1CA.acq.acqResults.acqed = 0;   % �����ʼ��
                channel.CH_L1CA.Samp_Posi = 0; % Ensure reacquisition not exceed index limit
            else
                channel.STATUS = 'ACQ_FAIL';
                channel.CH_L1CA.CH_STATUS = channel.STATUS;
                channel.CH_L1CA.Samp_Posi = 0; % Ensure reacquisition not exceed index limit
            end
        elseif strcmp(channel.STATUS, 'COLD_ACQ_AGAIN')     % �ز���ʧ��
            channel.STATUS = 'ACQ_FAIL';
            channel.CH_L1CA.CH_STATUS = channel.STATUS;
            channel.CH_L1CA.Samp_Posi = 0; % Ensure reacquisition not exceed index limit
      %������������������������������������������������ �Ȳ���ʧ�� ������������������������������������������������% 
        elseif strcmp(channel.STATUS, 'HOT_ACQ')            % �Ȳ���ʧ��
            if channel.CH_L1CA.acq.hotWaitTime==-9999   % �״��Ȳ���ʧ��
                channel.STATUS = 'HOT_ACQ_WAIT';
                channel.CH_L1CA.CH_STATUS = channel.STATUS;
                channel.CH_L1CA.acq.hotWaitTime = config.recvConfig.hotTime;
                channel.CH_L1CA.acq.hotAcqTime = config.recvConfig.hotAcqPeriod;
                channel.CH_L1CA.acq.acqResults.acqed = 0;   % �����ʼ��
            else
                channel.STATUS = 'HOT_ACQ_WAIT';
                channel.CH_L1CA.CH_STATUS = channel.STATUS; 
                channel.CH_L1CA.acq.hotAcqTime = config.recvConfig.hotAcqPeriod;
                channel.CH_L1CA.acq.acqResults.acqed = 0;   % �����ʼ��
            end

        end% EOF: if strcmp(channel.STATUS, 'COLD_ACQ')% �䲶��ʧ��
    end % EOF: if (channel.CH_L1CA.acq.acqResults.acqed == 1)
end  % EOF: if strcmp(channel.SYST, 'GPS_L1CA')
    
%% ������������������������������������������������ GPS L1_L2C ͨ������ ������������������������������������������������%
if strcmp(channel.SYST, 'GPS_L1CA_L2C')

    [channel.CH_L1CA_L2C, channel.CH_L1CA_L2C.acq.acqResults] = acquireGPS(channel.CH_L1CA_L2C, sis, channel.CH_L1CA_L2C.acq.acqResults, channel.bpSampling_OddFold, config.logConfig);
    
    %������������������������������������������������ �źŲ���ɹ� ������������������������������������������������%   
    if (channel.CH_L1CA_L2C.acq.acqResults.acqed == 1) % �źŲ���ɹ�
        if channel.CH_L1CA_L2C.acq.acqID == 0
            channel.CH_L1CA_L2C.LO2_fd = channel.CH_L1CA_L2C.LO2_fd + channel.CH_L1CA_L2C.acq.acqResults.doppler; % + acq_cfg.oscOffset;
            channel.CH_L1CA_L2C.LO_Fcode_fd = channel.bpSampling_OddFold * channel.CH_L1CA_L2C.LO2_fd / GSAR_CONSTANTS.STR_L1CA.L0Fc0_R;
            channel.CH_L1CA_L2C.LO_CodPhs = 0;
            channel.CH_L1CA_L2C.CN0_Estimator.CN0 = 10 * log10(channel.CH_L1CA_L2C.acq.acqResults.snr / channel.CH_L1CA_L2C.acq.acq_parameters.tcoh);
            channel.CH_L1CA_L2C.Samp_Posi = channel.CH_L1CA_L2C.Samp_Posi + channel.CH_L1CA_L2C.acq.acqResults.codeIdx;
            channel.CH_L1CA_L2C.acq.TimeLen = channel.CH_L1CA_L2C.acq.TimeLen + channel.CH_L1CA_L2C.acq.acqResults.codeIdx;
            channel.CH_L1CA_L2C.Samp_Posi = channel.CH_L1CA_L2C.Samp_Posi - channel.CH_L1CA_L2C.acq.resiN;      % �۳�resiData�е����ݵ���
            channel.CH_L1CA_L2C.acq.resiN = 0;
            channel.CH_L1CA_L2C.acq.acqID = 1;
            %�������� 20170409
            channel.CH_L1CA_L2C.acq.resiData = [];
            channel.CH_L1CA_L2C.acq.corrtmp = [];
            channel.CH_L1CA_L2C.acq.corr = [];
        end
        while (channel.CH_L1CA_L2C.Samp_Posi < 0)
            nPerCode = round(1/(GSAR_CONSTANTS.STR_L1CA.Fcode0+channel.CH_L1CA_L2C.LO_Fcode_fd)*GSAR_CONSTANTS.STR_L1CA.ChipNum*GSAR_CONSTANTS.STR_RECV.RECV_fs0);%���Ƕ�����Ƶ�ƺ��1��ca���������
            channel.CH_L1CA_L2C.Samp_Posi = channel.CH_L1CA_L2C.Samp_Posi + nPerCode;
            channel.CH_L1CA_L2C.acq.TimeLen = channel.CH_L1CA_L2C.acq.TimeLen + nPerCode;
        end
        if channel.CH_L1CA_L2C.Samp_Posi >= N
            channel.CH_L1CA_L2C.Samp_Posi =  channel.CH_L1CA_L2C.Samp_Posi - N;
        else
            if strcmp(channel.STATUS, 'COLD_ACQ') || strcmp(channel.STATUS, 'COLD_ACQ_AGAIN')               % ����������ɹ�
                channel.CH_L1CA_L2C.acq.ACQ_STATUS = 1; %������        
            elseif strcmp(channel.STATUS, 'HOT_ACQ')            % ����������ɹ�
                %nothing ��δʵ��
            end
            fprintf('CodeIndx: %d ; Doppler: %.2fHz ; CN0: %.1fdB \n', ...
                channel.CH_L1CA_L2C.Samp_Posi, channel.bpSampling_OddFold*channel.CH_L1CA_L2C.LO2_fd, channel.CH_L1CA_L2C.CN0_Estimator.CN0);
        end
        
    %������������������������������������������������ �źŲ���ʧ�� ������������������������������������������������% 
    elseif (channel.CH_L1CA_L2C.acq.acqResults.acqed == -1) % �źŲ���ʧ��
        if strcmp(channel.STATUS, 'COLD_ACQ')           % �䲶��ʧ��
            if satelliteTable(2).satVisible(channel.CH_L1CA_L2C.PRNID)==1 % ���ж����ǿɼ��򲶻�����
                channel.STATUS = 'COLD_ACQ_AGAIN';
                channel.CH_L1CA_L2C.CH_STATUS = channel.STATUS;
                channel.CH_L1CA_L2C.acq.acqResults.acqed = 0;   % �����ʼ��
                channel.CH_L1CA_L2C.Samp_Posi = 0; % Ensure reacquisition not exceed index limit
            else
                channel.STATUS = 'ACQ_FAIL';
                channel.CH_L1CA_L2C.CH_STATUS = channel.STATUS;
                channel.CH_L1CA_L2C.Samp_Posi = 0; % Ensure reacquisition not exceed index limit
            end
        elseif strcmp(channel.STATUS, 'COLD_ACQ_AGAIN')     % �ز���ʧ��
            channel.STATUS = 'ACQ_FAIL';
            channel.CH_L1CA_L2C.CH_STATUS = channel.STATUS;
            channel.CH_L1CA_L2C.Samp_Posi = 0; % Ensure reacquisition not exceed index limit
      %������������������������������������������������ �Ȳ���ʧ�� ������������������������������������������������% 
        elseif strcmp(channel.STATUS, 'HOT_ACQ')            % �Ȳ���ʧ��
            if channel.CH_L1CA_L2C.acq.hotWaitTime==-9999   % �״��Ȳ���ʧ��
                channel.STATUS = 'HOT_ACQ_WAIT';
                channel.CH_L1CA_L2C.CH_STATUS = channel.STATUS;
                channel.CH_L1CA_L2C.acq.hotWaitTime = config.recvConfig.hotTime;
                channel.CH_L1CA_L2C.acq.hotAcqTime = config.recvConfig.hotAcqPeriod;
                channel.CH_L1CA_L2C.acq.acqResults.acqed = 0;   % �����ʼ��
            else
                channel.STATUS = 'HOT_ACQ_WAIT';
                channel.CH_L1CA_L2C.CH_STATUS = channel.STATUS; 
                channel.CH_L1CA_L2C.acq.hotAcqTime = config.recvConfig.hotAcqPeriod;
                channel.CH_L1CA_L2C.acq.acqResults.acqed = 0;   % �����ʼ��
            end

        end% EOF: if strcmp(channel.STATUS, 'COLD_ACQ')% �䲶��ʧ��
    end % EOF: if (channel.CH_L1CA_L2C.acq.acqResults.acqed == 1)
end % EOF: if strcmp(channel.SYST, 'GPS_L1CA_L2C')

%% ������������������������������������������������ BDS���� ������������������������������������������������% 
if strcmp(channel.SYST, 'BDS_B1I') 
    [channel.CH_B1I, channel.CH_B1I.acq.acqResults] = acquireCompass(channel.CH_B1I, sis, channel.CH_B1I.acq.acqResults, channel.bpSampling_OddFold, config.logConfig);   
 
 %������������������������������������������������ �źŲ���ɹ� ������������������������������������������������%   
    if (channel.CH_B1I.acq.acqResults.acqed==1)
        if channel.CH_B1I.acq.acqID == 0
            channel.CH_B1I.LO2_fd = channel.CH_B1I.LO2_fd + channel.CH_B1I.acq.acqResults.doppler;   % + sv_acq_cfg.oscOffset;          % �ز�������ƫ��
            channel.CH_B1I.LO_Fcode_fd = channel.bpSampling_OddFold * channel.CH_B1I.LO2_fd / GSAR_CONSTANTS.STR_B1I.L0Fc0_R;       % �������ƫ��
            channel.CH_B1I.LO_CodPhs = 0;
            channel.CH_B1I.CN0_Estimator.CN0 = 10*log10(channel.CH_B1I.acq.acqResults.snr / channel.CH_B1I.acq.acq_parameters.tcoh);        % �����
            channel.CH_B1I.Samp_Posi = channel.CH_B1I.Samp_Posi + channel.CH_B1I.acq.acqResults.codeIdx;       % ������ʹ�õĲ���������һ��Ϊ20ms�� + ����λ���������ڲ������е�λ��
            channel.CH_B1I.acq.TimeLen = channel.CH_B1I.acq.TimeLen + channel.CH_B1I.acq.acqResults.codeIdx;
            channel.CH_B1I.Samp_Posi = channel.CH_B1I.Samp_Posi - channel.CH_B1I.acq.resiN;      % �۳�resiData�е����ݵ���
            channel.CH_B1I.acq.resiN = 0;
            channel.CH_B1I.acq.acqID = 1;
        end
        while (channel.CH_B1I.Samp_Posi < 0)
            nPerCode = round(1/(GSAR_CONSTANTS.STR_B1I.Fcode0+channel.CH_B1I.LO_Fcode_fd)*GSAR_CONSTANTS.STR_B1I.ChipNum*GSAR_CONSTANTS.STR_RECV.RECV_fs0);%���Ƕ�����Ƶ�ƺ��1��ca���������
            channel.CH_B1I.Samp_Posi = channel.CH_B1I.Samp_Posi + nPerCode;
            channel.CH_B1I.acq.TimeLen = channel.CH_B1I.acq.TimeLen + nPerCode;
        end
        if channel.CH_B1I.Samp_Posi > N
            if strcmp(channel.STATUS, 'COLD_ACQ')
                channel.STATUS = 'COLD_ACQ';
            elseif strcmp(channel.STATUS, 'COLD_ACQ_AGAIN')
                channel.STATUS = 'COLD_ACQ_AGAIN';
            elseif strcmp(channel.STATUS, 'HOT_ACQ')
                channel.STATUS = 'HOT_ACQ';  
            end
            channel.CH_B1I.Samp_Posi =  channel.CH_B1I.Samp_Posi - N;
        else
    %������������������������������������������������ biteͬ������ ������������������������������������������������% 
            if strcmp(channel.STATUS, 'COLD_ACQ') || strcmp(channel.STATUS, 'COLD_ACQ_AGAIN')
                channel.STATUS = 'BIT_SYNC';
                channel.CH_B1I.CH_STATUS = channel.STATUS;
                % BitSync Initialize
                channel = coldBitSync_init(channel, config);
            elseif strcmp(channel.STATUS, 'HOT_ACQ')
                channel.STATUS = 'HOT_BIT_SYNC';
                channel.CH_B1I.CH_STATUS = channel.STATUS;
                channel = hotBitSync_init(channel, config); % ʧ���ز������²�������
                timeLen = round(channel.CH_B1I.acq.TimeLen); % ������ʱ������N������ÿ�ν���channel_scheduler�л���N������
                [verify, channel.CH_B1I] = hotInfoCheck(channel.CH_B1I, timeLen, channel.SYST,'ACQ'); % ������������Ԥ��ĸ����������ȷ��
            end
                        
            fprintf('CodeIndx: %d ; Doppler: %.2fHz ; CN0: %.1fdB \n', ...
                channel.CH_B1I.Samp_Posi, channel.bpSampling_OddFold*channel.CH_B1I.LO2_fd, channel.CH_B1I.CN0_Estimator.CN0);
        end
    %������������������������������������������������ �źŲ���ʧ�� ������������������������������������������������% 
    elseif (channel.CH_B1I.acq.acqResults.acqed==-1)
         if strcmp(channel.STATUS, 'COLD_ACQ')
            if satelliteTable(1).satVisible(channel.CH_B1I.PRNID)==1 % ���ж����ǿɼ��򲶻�����
                channel.STATUS = 'COLD_ACQ_AGAIN';
                channel.CH_B1I.CH_STATUS = channel.STATUS;
                channel.CH_B1I.Samp_Posi = 0; % Ensure reacquisition not exceed index limit
                channel.CH_B1I.acq.acqResults.acqed = 0;
            else
                channel.STATUS = 'ACQ_FAIL';
                channel.CH_B1I.CH_STATUS = channel.STATUS;
                channel.CH_B1I.Samp_Posi = 0; % Ensure reacquisition not exceed index limit
            end
         elseif strcmp(channel.STATUS, 'COLD_ACQ_AGAIN')
            channel.STATUS = 'ACQ_FAIL';
            channel.CH_B1I.CH_STATUS = channel.STATUS;
            channel.CH_B1I.Samp_Posi = 0; % Ensure reacquisition not exceed index limit
       %������������������������������������������������ �Ȳ���ʧ�� ������������������������������������������������% 
         elseif strcmp(channel.STATUS, 'HOT_ACQ')
             if channel.CH_B1I.acq.hotWaitTime==-9999   % �״��Ȳ���ʧ��
                channel.STATUS = 'HOT_ACQ_WAIT';
                channel.CH_B1I.CH_STATUS = channel.STATUS;
                channel.CH_B1I.acq.hotWaitTime = config.recvConfig.hotTime;
                channel.CH_B1I.acq.hotAcqTime = config.recvConfig.hotAcqPeriod;
                channel.CH_B1I.acq.acqResults.acqed = 0;   % �����ʼ��
            else
                channel.STATUS = 'HOT_ACQ_WAIT';
                channel.CH_B1I.CH_STATUS = channel.STATUS; 
                channel.CH_B1I.acq.hotAcqTime = config.recvConfig.hotAcqPeriod;
                channel.CH_B1I.acq.acqResults.acqed = 0;   % �����ʼ��
            end
%             if isnan(channel.CH_B1I.acq.hotWaitTime)   % �״��Ȳ���ʧ��
%                 channel.STATUS = 'HOT_ACQ';
%                 channel.CH_B1I.CH_STATUS = channel.STATUS;
%                 % ��������λ��Ϣ
%                 [~, channel.CH_B1I] = hotInfoCheck(channel.CH_B1I, N, channel.SYST,'NORM'); 
%                 channel.CH_B1I.Samp_Posi = 0;
%                 channel.CH_B1I.acq.acqResults.acqed = 0;
%                 channel.CH_B1I.acq.hotWaitTime = 15;
%             elseif channel.CH_B1I.acq.hotWaitTime > 0
%                 channel.STATUS = 'HOT_ACQ';
%                 channel.CH_B1I.CH_STATUS = channel.STATUS;
%                 % ��������λ��Ϣ
%                 [~, channel.CH_B1I] = hotInfoCheck(channel.CH_B1I, N, channel.SYST,'NORM'); 
%                 channel.CH_B1I.Samp_Posi = 0;
%                 channel.CH_B1I.acq.acqResults.acqed = 0;
%                 channel.CH_B1I.acq.hotWaitTime = channel.CH_B1I.acq.hotWaitTime - N/GSAR_CONSTANTS.STR_RECV.fs;
%             elseif channel.CH_B1I.acq.hotWaitTime <= 0
%                 channel.STATUS = 'COLD_ACQ';
%                 channel.CH_B1I.CH_STATUS = channel.STATUS;
%                 channel = BdsCH_ColdInitialize...
%                             (channel, channel.SYST, 'COLD_ACQ', channel.CH_B1I.PRNID, config.recvConfig.configPage, GSAR_CONSTANTS); % ����CHANNEL
%             end% EOF: if isnan(channel.CH_L1CA.acq.hotWaitTime)   % �״��Ȳ���ʧ��
         end
    end % EOF: if (channel.CH_L1CA.acq.acqResults.acqed == 1)
end % EOF: if strcmp(channel.SYST, 'BDS_B1I')

