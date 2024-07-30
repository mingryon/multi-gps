function receiver = channel_scheduler(receiver, N)
global GSAR_CONSTANTS;
channels       = receiver.channels;
satelliteTable = receiver.satelliteTable;
config = receiver.config;
recorder = receiver.recorder;
pvtCalculator = receiver.pvtCalculator;

% ����������
if strcmp(receiver.syst, 'BDS_B1I') || strcmp(receiver.syst, 'B1I_L1CA')
    bds_maxprnNo = config.recvConfig.configPage.systConfig.BDS_B1I.maxPrnNo;
    for n = 1 : bds_maxprnNo % loop around the satllite table
        if ~ismember(n, satelliteTable(1).satCandiPrio) && ~ismember(n, satelliteTable(1).satCandi) % ���ڵ�ǰ�Ⱥ��������б���
            if strcmp(satelliteTable(1).processState(n), 'WAIT_FOR_PROCESS') % ���ڵȺ���״̬
                if satelliteTable(1).satVisible(n) == 1
                    if satelliteTable(1).satBlock(n)==1 && satelliteTable(1).satBlockAge(n)<=0
                        satelliteTable(1).satCandiPrio = [satelliteTable(1).satCandiPrio, n];
                        satelliteTable(1).nCandiPrio = satelliteTable(1).nCandiPrio + 1;
                        satelliteTable(1).satBlock(n) = 0;
                    end
                elseif satelliteTable(1).satVisible(n) == -1
                    if satelliteTable(1).satBlock(n)==1 && satelliteTable(1).satBlockAge(n)<=0
                        satelliteTable(1).satCandi = [satelliteTable(1).satCandi, n];
                        satelliteTable(1).nCandi = satelliteTable(1).nCandi + 1;
                        satelliteTable(1).satBlock(n) = 0;
                    end
                end
            end
        end
    end
end

% ����GPS����
if strcmp(receiver.syst, 'GPS_L1CA') || strcmp(receiver.syst, 'B1I_L1CA') || strcmp(receiver.syst, 'L1CA_L2C')
    gps_maxprnNo = config.recvConfig.configPage.systConfig.GPS_L1CA.maxPrnNo;
    for n = 1 : gps_maxprnNo % loop around the satllite table
        if ~ismember(n, satelliteTable(2).satCandiPrio) && ~ismember(n, satelliteTable(2).satCandi) % ���ڵ�ǰ�Ⱥ��������б���
            if strcmp(satelliteTable(2).processState(n), 'WAIT_FOR_PROCESS') % ���ڵȺ���״̬
                if satelliteTable(2).satVisible(n) == 1
                    if satelliteTable(2).satBlock(n)==1 && satelliteTable(2).satBlockAge(n)<=0
                        satelliteTable(2).satCandiPrio = [satelliteTable(2).satCandiPrio, n];
                        satelliteTable(2).nCandiPrio = satelliteTable(2).nCandiPrio + 1;
                        satelliteTable(2).satBlock(n) = 0;
                    end
                elseif satelliteTable(2).satVisible(n) == -1
                    if satelliteTable(2).satBlock(n)==1 && satelliteTable(2).satBlockAge(n)<=0
                        satelliteTable(2).satCandi = [satelliteTable(2).satCandi, n];
                        satelliteTable(2).nCandi = satelliteTable(2).nCandi + 1;
                        satelliteTable(2).satBlock(n) = 0;
                    end
                end
            end
        end
    end
end
%-------------  status update of all channels  --------------------%
for i = 1 : config.recvConfig.numberOfChannels(1).channelNumAll
    switch channels(i).SYST
       %% ����B1Iͨ��
        case 'BDS_B1I'
            prn = channels(i).CH_B1I(1).PRNID;
            switch channels(i).STATUS
                case 'COLD_ACQ'
                    satelliteTable(1).processState(prn) = {'COLD_ACQ'};
                case 'COLD_ACQ_AGAIN'
                    satelliteTable(1).processState(prn) = {'COLD_ACQ_AGAIN'};
                case 'WARM_ACQ'
                    satelliteTable(1).processState(prn) = {'WARM_ACQ'};
                case 'WARM_ACQ_AGAIN'
                    satelliteTable(1).processState(prn) = {'WARM_ACQ_AGAIN'};
                case 'HOT_ACQ'
                    satelliteTable(2).processState(prn) = {'HOT_ACQ'};
                    % ��������λ��Ϣ   
                    timeLen = round(channels(i).CH_B1I(1).acq.TimeLen);
                    [~, channels(i).CH_B1I(1)] = hotInfoCheck(channels(i).CH_B1I(1), timeLen, channels(i).SYST,'NORM');
                    channels(i).CH_B1I(1).acq.TimeLen = channels(i).CH_B1I(1).acq.TimeLen - timeLen;
                case 'HOT_ACQ_AGAIN'
                    satelliteTable(1).processState(prn) = {'HOT_ACQ_AGAIN'};
                case 'BIT_SYNC'
                    satelliteTable(1).processState(prn) = {'BIT_SYNC'};
                case 'PULLIN'
                    satelliteTable(1).processState(prn) = {'PULLIN'};
                case 'TRACK'
                    satelliteTable(1).processState(prn) = {'TRACK'};
                case 'SUBFRAME_SYNCED'
                    satelliteTable(1).processState(prn) = {'SUBFRAME_SYNCED'};
                case 'LOSS_OF_LOCK'
                    lockDect = channels(i).CH_B1I(1).lockDect;
                    predictInfo = framePredict(lockDect, lockDect.lockTime, lockDect.codeDopp, lockDect.carriDopp, channels(i).SYST, prn , 'NORM');% ������֡��Ϣ
                    channels(i) = BdsCH_HotInitialize...
                            (channels(i), receiver.syst, 'HOT_ACQ', prn, config.recvConfig.configPage, GSAR_CONSTANTS, predictInfo, receiver.device); % ����CHANNEL
                    satelliteTable(1).processState(prn) = {'HOT_ACQ'};
                    pvtCalculator.BDS.doppSmooth(prn,:) = zeros(1,4);
                case 'ACQ_FAIL'
                    satelliteTable(1).processState(prn) = {'WAIT_FOR_PROCESS'};
                    if ~isempty(satelliteTable(1).satCandiPrio)
                        newPrn = satelliteTable(1).satCandiPrio(1); % ��Ҫ�����PRN���Ǻ�
                        satelliteTable(1).satCandiPrio(1) = []; % ���˺�����ȥ��
                        satelliteTable(1).nCandiPrio = length(satelliteTable(1).satCandiPrio);
                        channels(i) = BdsCH_ColdInitialize...
                            (channels(i), receiver.syst, 'COLD_ACQ', newPrn, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device); % ����CHANNEL
                        recorder = UpdateRecorder(newPrn, i, recorder, receiver); % ����recorder
                        satelliteTable(1).processState(newPrn) = {'COLD_ACQ'};
                    elseif ~isempty(satelliteTable(1).satCandi)
                        newPrn = satelliteTable(1).satCandi(1); % ��Ҫ�����PRN���Ǻ�
                        satelliteTable(1).satCandi(1) = []; % ���˺�����ȥ��
                        satelliteTable(1).nCandi = length(satelliteTable(1).satCandi);
                        channels(i) = BdsCH_ColdInitialize...
                            (channels(i), receiver.syst, 'COLD_ACQ', newPrn, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device);
                        recorder = UpdateRecorder(newPrn, i, recorder, receiver); % ����recorder
                        satelliteTable(1).processState(newPrn) = {'COLD_ACQ'};
                    else
                        channels(i).STATUS = 'IDLE';
                        channels(i).CH_B1I(1).PRNID = 0;
                    end
                    
                case 'HOT_ACQ_WAIT'
                    satelliteTable(1).processState(prn) = {'HOT_ACQ_WAIT'};
                    if channels(i).CH_B1I(1).acq.hotWaitTime > 0
                        % ��������λ��Ϣ     
                        timeLen = round(channels(i).CH_B1I(1).acq.TimeLen);
                        [~, channels(i).CH_B1I(1)] = hotInfoCheck(channels(i).CH_B1I(1), timeLen, channels(i).SYST,'NORM');
                        channels(i).CH_B1I(1).Samp_Posi = 0;
                        if channels(i).CH_B1I.acq.hotAcqTime <= 0
                            channels(i).STATUS = 'HOT_ACQ';
                            channels(i).CH_B1I(1).CH_STATUS = channels(i).STATUS;
                            satelliteTable(1).processState(prn) = {'HOT_ACQ'};
                        end
                        channels(i).CH_B1I(1).acq.hotAcqTime = channels(i).CH_B1I(1).acq.hotAcqTime - N/GSAR_CONSTANTS.STR_RECV.fs;
                        channels(i).CH_B1I(1).acq.hotWaitTime = channels(i).CH_B1I(1).acq.hotWaitTime - N/GSAR_CONSTANTS.STR_RECV.fs;
                    else
                        channels(i).STATUS = 'COLD_ACQ';
                        channels(i).CH_B1I(1).CH_STATUS = channels(i).STATUS;
                        channels(i) = BdsCH_ColdInitialize...
                              (channels(i), channels(i).SYST, 'COLD_ACQ', channels(i).CH_B1I.PRNID, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device); % ����CHANNEL  
                        satelliteTable(1).processState(prn) = {'COLD_ACQ'};
                    end       
                    
                case 'BIT_SYNC_FAIL'
                    channels(i) = BdsCH_ColdInitialize...
                        (channels(i), receiver.syst, 'COLD_ACQ', prn, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device);
                case 'IDLE'
                    if ~isempty(satelliteTable(1).satCandiPrio)
                        newPrn = satelliteTable(1).satCandiPrio(1); % ��Ҫ�����PRN���Ǻ�
                        satelliteTable(1).satCandiPrio(1) = []; % ���˺�����ȥ��
                        satelliteTable(1).nCandiPrio = length(satelliteTable(1).satCandiPrio);
                        channels(i) = BdsCH_ColdInitialize...
                            (channels(i), receiver.syst, 'COLD_ACQ', newPrn, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device);
                        recorder = UpdateRecorder(newPrn, i, recorder, receiver); % ����recorder
                        satelliteTable(1).processState(newPrn) = {'COLD_ACQ'};
                    elseif ~isempty(satelliteTable(1).satCandi)
                        newPrn = satelliteTable(1).satCandi(1); % ��Ҫ�����PRN���Ǻ�
                        satelliteTable(1).satCandi(1) = []; % ���˺�����ȥ��
                        satelliteTable(1).nCandi = length(satelliteTable(1).satCandi);
                        channels(i) = BdsCH_ColdInitialize...
                            (channels(i), receiver.syst, 'COLD_ACQ', newPrn, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device);
                        recorder = UpdateRecorder(newPrn, i, recorder, receiver); % ����recorder
                        satelliteTable(1).processState(newPrn) = {'COLD_ACQ'};
                    else
                        channels(i).STATUS = 'IDLE';
                    end
                    
                case 'POSI_FAIL'
                    channels(i) = BdsCH_ColdInitialize...
                            (channels(i), receiver.syst, 'COLD_ACQ', prn, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device);
                    satelliteTable(1).processState(prn) = {'COLD_ACQ'};
            end %EOF : switch channels(i).STATUS
            
       %% GPS L1CAͨ��
        case 'GPS_L1CA'           
            prn = channels(i).CH_L1CA(1).PRNID;
            switch channels(i).STATUS
                case 'COLD_ACQ'
                    satelliteTable(2).processState(prn) = {'COLD_ACQ'};
                case 'COLD_ACQ_AGAIN'
                    satelliteTable(2).processState(prn) = {'COLD_ACQ_AGAIN'};
                case 'WARM_ACQ'
                    satelliteTable(2).processState(prn) = {'WARM_ACQ'};
                case 'WARM_ACQ_AGAIN'
                    satelliteTable(2).processState(prn) = {'WARM_ACQ_AGAIN'};
                case 'HOT_ACQ'
                    satelliteTable(2).processState(prn) = {'HOT_ACQ'};
                    % ��������λ��Ϣ       
                    timeLen = round(channels(i).CH_L1CA.acq.TimeLen);
                    [~, channels(i).CH_L1CA] = hotInfoCheck(channels(i).CH_L1CA, timeLen, channels(i).SYST,'NORM');
                    channels(i).CH_L1CA.acq.TimeLen = channels(i).CH_L1CA.acq.TimeLen - timeLen;
                case 'HOT_ACQ_AGAIN'
                    satelliteTable(2).processState(prn) = {'HOT_ACQ_AGAIN'};
                case 'BIT_SYNC'
                    satelliteTable(2).processState(prn) = {'BIT_SYNC'};
                case 'PULLIN'
                    satelliteTable(2).processState(prn) = {'PULLIN'};
                case 'TRACK'
                    satelliteTable(2).processState(prn) = {'TRACK'};
                case 'SUBFRAME_SYNCED'
                    satelliteTable(2).processState(prn) = {'SUBFRAME_SYNCED'};
                case 'LOSS_OF_LOCK'
                    lockDect = channels(i).CH_L1CA(1).lockDect;
                    predictInfo = framePredict(lockDect, lockDect.lockTime, lockDect.codeDopp, lockDect.carriDopp, channels(i).SYST, prn, 'NORM');% ������֡��Ϣ
                    channels(i) = GpsCH_HotInitialize...
                            (channels(i), receiver.syst, 'HOT_ACQ', prn, config.recvConfig.configPage, GSAR_CONSTANTS, predictInfo, receiver.device); % ����CHANNEL
                    satelliteTable(1).processState(prn) = {'HOT_ACQ'};
                    pvtCalculator.GPS.doppSmooth(prn,:) = zeros(1,4);
                    
                case 'ACQ_FAIL'
                    satelliteTable(2).processState(prn) = {'WAIT_FOR_PROCESS'};
                    if ~isempty(satelliteTable(2).satCandiPrio)
                        newPrn = satelliteTable(2).satCandiPrio(1); % ��Ҫ�����PRN���Ǻ�
                        satelliteTable(2).satCandiPrio(1) = []; % ���˺�����ȥ��
                        satelliteTable(2).nCandiPrio = length(satelliteTable(2).satCandiPrio);
                        channels(i) = GpsCH_ColdInitialize...
                            (channels(i), receiver.syst, 'COLD_ACQ', newPrn, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device);
                        recorder = UpdateRecorder(newPrn, i, recorder, receiver); % ����recorder
                        satelliteTable(2).processState(newPrn) = {'COLD_ACQ'};
                    elseif ~isempty(satelliteTable(2).satCandi)
                        newPrn = satelliteTable(2).satCandi(1); % ��Ҫ�����PRN���Ǻ�
                        satelliteTable(2).satCandi(1) = []; % ���˺�����ȥ��
                        satelliteTable(2).nCandi = length(satelliteTable(2).satCandi);
                        channels(i) = GpsCH_ColdInitialize...
                            (channels(i), receiver.syst, 'COLD_ACQ', newPrn, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device);
                        recorder = UpdateRecorder(newPrn, i, recorder, receiver); % ����recorder
                        satelliteTable(2).processState(newPrn) = {'COLD_ACQ'};
                    else
                        channels(i).STATUS = 'IDLE';
                        channels(i).CH_L1CA(1).PRNID = 0;
                    end
                    
                case 'HOT_ACQ_WAIT'
                    satelliteTable(2).processState(prn) = {'HOT_ACQ_WAIT'};
                    if channels(i).CH_L1CA.acq.hotWaitTime > 0
                        % ��������λ��Ϣ   
                        timeLen = round(channels(i).CH_L1CA.acq.TimeLen);
                        [~, channels(i).CH_L1CA] = hotInfoCheck(channels(i).CH_L1CA, timeLen, channels(i).SYST,'NORM');
                        channels(i).CH_L1CA.Samp_Posi = 0;
                        if channels(i).CH_L1CA.acq.hotAcqTime <= 0
                            channels(i).STATUS = 'HOT_ACQ';
                            channels(i).CH_L1CA.CH_STATUS = channels(i).STATUS;
                            satelliteTable(2).processState(prn) = {'HOT_ACQ'};
                        end
                        channels(i).CH_L1CA.acq.hotAcqTime = channels(i).CH_L1CA.acq.hotAcqTime - N/GSAR_CONSTANTS.STR_RECV.fs;
                        channels(i).CH_L1CA.acq.hotWaitTime = channels(i).CH_L1CA.acq.hotWaitTime - N/GSAR_CONSTANTS.STR_RECV.fs;
                    else
                        channels(i).STATUS = 'COLD_ACQ';
                        channels(i).CH_L1CA.CH_STATUS = channels(i).STATUS;
                        channels(i) = GpsCH_ColdInitialize...
                              (channels(i), channels(i).SYST, 'COLD_ACQ', channels(i).CH_L1CA.PRNID, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device); % ����CHANNEL  
                        satelliteTable(2).processState(prn) = {'COLD_ACQ'};
                    end       
                        
                case 'BIT_SYNC_FAIL'
                    channels(i) = GpsCH_ColdInitialize...
                        (channels(i), receiver.syst, 'COLD_ACQ', prn, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device);
                case 'IDLE'
                    if ~isempty(satelliteTable(2).satCandiPrio)
                        newPrn = satelliteTable(2).satCandiPrio(1); % ��Ҫ�����PRN���Ǻ�
                        satelliteTable(2).satCandiPrio(1) = []; % ���˺�����ȥ��
                        satelliteTable(2).nCandiPrio = length(satelliteTable(2).satCandiPrio);
                        channels(i) = GpsCH_ColdInitialize...
                            (channels(i), receiver.syst, 'COLD_ACQ', newPrn, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device);
                        recorder = UpdateRecorder(newPrn, i, recorder, receiver); % ����recorder
                        satelliteTable(2).processState(newPrn) = {'COLD_ACQ'};
                    elseif ~isempty(satelliteTable(2).satCandi)
                        newPrn = satelliteTable(2).satCandi(1); % ��Ҫ�����PRN���Ǻ�
                        satelliteTable(2).satCandi(1) = []; % ���˺�����ȥ��
                        satelliteTable(2).nCandi = length(satelliteTable(2).satCandi);
                        channels(i) = GpsCH_ColdInitialize...
                            (channels(i), receiver.syst, 'COLD_ACQ', newPrn, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device);
                        recorder = UpdateRecorder(newPrn, i, recorder, receiver); % ����recorder
                        satelliteTable(2).processState(newPrn) = {'COLD_ACQ'};
                    else
                        channels(i).STATUS = 'IDLE';
                    end
                case 'POSI_FAIL'
                    channels(i) = GpsCH_ColdInitialize...
                            (channels(i), receiver.syst, 'COLD_ACQ', prn, config.recvConfig.configPage, GSAR_CONSTANTS, receiver.device);
                    satelliteTable(2).processState(prn) = {'COLD_ACQ'};
            end %EOF : switch channels(i).STATUS
       %% GPS L1CA L2C ͨ��   
        case 'GPS_L1CA_L2C'
            prn = channels(i).CH_L1CA_L2C(1).PRNID;
            switch channels(i).STATUS
                case 'COLD_ACQ'
                    satelliteTable(2).processState(prn) = {'COLD_ACQ'};
                case 'COLD_ACQ_AGAIN'
                    satelliteTable(2).processState(prn) = {'COLD_ACQ_AGAIN'};
                case 'WARM_ACQ'
                    satelliteTable(2).processState(prn) = {'WARM_ACQ'};
                case 'WARM_ACQ_AGAIN'
                    satelliteTable(2).processState(prn) = {'WARM_ACQ_AGAIN'};
                case 'HOT_ACQ'
                    satelliteTable(2).processState(prn) = {'HOT_ACQ'};
                    channels(i).CH_L1CA_L2C = hotTimeInc_L1L2(channels(i).CH_L1CA_L2C, channels(i).CH_L1CA_L2C.acq.TimeLen);
                    channels(i).CH_L1CA_L2C.acq.TimeLen = 0;
                case 'HOT_ACQ_AGAIN'  % unused now
                    satelliteTable(2).processState(prn) = {'HOT_ACQ_AGAIN'};
                case 'PULLIN'
                    satelliteTable(2).processState(prn) = {'PULLIN'};
                case 'TRACK'
                    satelliteTable(2).processState(prn) = {'TRACK'};
                case 'SUBFRAME_SYNCED'
                    satelliteTable(2).processState(prn) = {'SUBFRAME_SYNCED'};
                case 'LOSS_OF_LOCK'
                    lockDect = channels(i).CH_L1CA_L2C(1).lockDect;
                    predictInfo = framePredict(lockDect, lockDect.lockTime, lockDect.codeDopp, lockDect.carriDopp, channels(i).SYST, prn, 'NORM');% ������֡��Ϣ
                    channels(i) = GpsCH_L1L2_HotInitialize...
                        (channels(i), prn, config.recvConfig.configPage, predictInfo); % ����CHANNEL
                    channels(i).STATUS = 'HOT_ACQ';
                    satelliteTable(1).processState(prn) = {'HOT_ACQ'};
                    pvtCalculator.GPS.doppSmooth(prn,:) = zeros(1,4);
                    
                case 'ACQ_FAIL'
                    satelliteTable(2).processState(prn) = {'WAIT_FOR_PROCESS'};
                    if ~isempty(satelliteTable(2).satCandiPrio)
                        newPrn = satelliteTable(2).satCandiPrio(1); % ��Ҫ�����PRN���Ǻ�
                        satelliteTable(2).satCandiPrio(1) = []; % ���˺�����ȥ��
                        satelliteTable(2).nCandiPrio = length(satelliteTable(2).satCandiPrio);
                        channels(i) = GpsCH_L1L2_ColdInitialize...
                            (channels(i), channels(i).CH_L1CA_L2C.PRNID, config.recvConfig.configPage);
                        % ------------------ �����
                        %recorder = UpdateRecorder(newPrn, i, recorder, receiver); % ����recorder
                        satelliteTable(2).processState(newPrn) = {'COLD_ACQ'};
                    elseif ~isempty(satelliteTable(2).satCandi)
                        newPrn = satelliteTable(2).satCandi(1); % ��Ҫ�����PRN���Ǻ�
                        satelliteTable(2).satCandi(1) = []; % ���˺�����ȥ��
                        satelliteTable(2).nCandi = length(satelliteTable(2).satCandi);
                        channels(i) = GpsCH_L1L2_ColdInitialize...
                            (channels(i), channels(i).CH_L1CA_L2C.PRNID, config.recvConfig.configPage);
                        % ------------------ �����
                        %recorder = UpdateRecorder(newPrn, i, recorder, receiver); % ����recorder
                        satelliteTable(2).processState(newPrn) = {'COLD_ACQ'};
                    else
                        channels(i).STATUS = 'IDLE';
                        channels(i).CH_L1CA_L2C(1).PRNID = 0;
                    end
                    
                case 'HOT_ACQ_WAIT'
                    satelliteTable(2).processState(prn) = {'HOT_ACQ_WAIT'};
                    if channels(i).CH_L1CA_L2C.acq.hotWaitTime > 0
                        % ��������λ��Ϣ
                        channels(i).CH_L1CA_L2C = hotTimeInc_L1L2(channels(i).CH_L1CA_L2C, channels(i).CH_L1CA_L2C.acq.TimeLen);
                        channels(i).CH_L1CA_L2C.Samp_Posi = 0;
                        if channels(i).CH_L1CA_L2C.acq.hotAcqTime <= 0
                            channels(i).STATUS = 'HOT_ACQ';
                            channels(i).CH_L1CA_L2C.CH_STATUS = channels(i).STATUS;
                            satelliteTable(2).processState(prn) = {'HOT_ACQ'};
                        end
                        channels(i).CH_L1CA_L2C.acq.hotAcqTime = channels(i).CH_L1CA_L2C.acq.hotAcqTime - N/GSAR_CONSTANTS.STR_RECV.fs;
                        channels(i).CH_L1CA_L2C.acq.hotWaitTime = channels(i).CH_L1CA_L2C.acq.hotWaitTime - N/GSAR_CONSTANTS.STR_RECV.fs;
                    else
                        channels(i).STATUS = 'COLD_ACQ';
                        channels(i).CH_L1CA_L2C.CH_STATUS = channels(i).STATUS;
                        channels(i) = GpsCH_L1L2_ColdInitialize...
                            (channels(i), channels(i).CH_L1CA_L2C.PRNID, config.recvConfig.configPage);
                        satelliteTable(2).processState(prn) = {'COLD_ACQ'};
                    end
                    
                case 'IDLE'
                    if ~isempty(satelliteTable(2).satCandiPrio)
                        newPrn = satelliteTable(2).satCandiPrio(1); % ��Ҫ�����PRN���Ǻ�
                        satelliteTable(2).satCandiPrio(1) = []; % ���˺�����ȥ��
                        satelliteTable(2).nCandiPrio = length(satelliteTable(2).satCandiPrio);
                        channels(i) = GpsCH_L1L2_ColdInitialize...
                            (channels(i), channels(i).CH_L1CA_L2C.PRNID, config.recvConfig.configPage);
                        % ------------------ �����
                        %recorder = UpdateRecorder(newPrn, i, recorder, receiver); % ����recorder
                        satelliteTable(2).processState(newPrn) = {'COLD_ACQ'};
                    elseif ~isempty(satelliteTable(2).satCandi)
                        newPrn = satelliteTable(2).satCandi(1); % ��Ҫ�����PRN���Ǻ�
                        satelliteTable(2).satCandi(1) = []; % ���˺�����ȥ��
                        satelliteTable(2).nCandi = length(satelliteTable(2).satCandi);
                        channels(i) = GpsCH_L1L2_ColdInitialize...
                            (channels(i), channels(i).CH_L1CA_L2C.PRNID, config.recvConfig.configPage);
                        % ------------------ �����
                        %recorder = UpdateRecorder(newPrn, i, recorder, receiver); % ����recorder
                        satelliteTable(2).processState(newPrn) = {'COLD_ACQ'};
                    else
                        channels(i).STATUS = 'IDLE';
                    end
                case 'POSI_FAIL'
                    channels(i) = GpsCH_L1L2_ColdInitialize...
                            (channels(i), channels(i).CH_L1CA_L2C.PRNID, config.recvConfig.configPage);
                    satelliteTable(2).processState(prn) = {'COLD_ACQ'};
            end %EOF : switch channels(i).STATUS
      %%      
    end %EOF : switch channels(i).SYST
end %EOF : for i = 1 : config.recvConfig.numberOfChannels(1).channelNumAll

receiver.channels       = channels;
receiver.satelliteTable = satelliteTable;
receiver.recorder       = recorder;
receiver.pvtCalculator  = pvtCalculator;

end % EOF: function