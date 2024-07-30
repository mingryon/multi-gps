%% Acquire GPS satllites
function [channel_spc, acqResults] = acquireGPS(channel_spc, sis, acqResults, bpSampling_OddFold, logConfig)
% Computation complexity could be optimized
% Using coherent integration 1 ms and M non-coherent integrations
% channel_spc:   the specific GPS_L1CA channel

global GSAR_CONSTANTS;

if channel_spc.acq.processing==0 && acqResults.acqed==0
%     fprintf('/----------------------------------------------------------------------------------------------/\n');
    fprintf('     %s GPS PRN%d:  Coherent accumulation: %1.3fs ; FreqBin: %dHz ; FreqRange: -%d~+%dHz\n', ...
            channel_spc.CH_STATUS, channel_spc.PRNID, channel_spc.acq.acq_parameters.tcoh, channel_spc.acq.acq_parameters.freqBin, channel_spc.acq.acq_parameters.freqRange/2, channel_spc.acq.acq_parameters.freqRange/2); %sv_acq_cfg.tcoh, sv_acq_cfg.freqBin, sv_acq_cfg.freqRange/2, sv_acq_cfg.freqRange/2);
    
    if (bpSampling_OddFold~=1)&&((bpSampling_OddFold~=-1))
        error('bpSampling_OddFold input error!');
    end
    
    acqResults.sv = channel_spc.PRNID;
    % PRN code
    channel_spc.codeTable = GSAR_CONSTANTS.PRN_CODE.CA_code(channel_spc.PRNID,:);
    % search central frequency first, and then enlarge the shift
    channel_spc.acq.freqOrder = (-(channel_spc.acq.freqSearch - 1)/2 : 1 : (channel_spc.acq.freqSearch - 1)/2);
    % allocate the space for storing the samples length per TC for each frequency cell
    channel_spc.acq.corr = zeros(channel_spc.acq.freqSearch, channel_spc.acq.sampPerTC_s); %non-coherent results
    channel_spc.acq.corrtmp = zeros(channel_spc.acq.freqSearch, channel_spc.acq.sampPerTC_s);
    channel_spc.acq.accum = 0;
    % compensation of the phase of the code
    channel_spc.acq.skipNumberOfCodes = zeros(1, channel_spc.acq.freqSearch);
    
    % ��ʼ���Ȳ������
    channel_spc.acq.skipNumberOfSamples = 0;
    channel_spc.acq.carriPhase = 0;
    channel_spc.acq.Samp_Posi_dot = 0;
    channel_spc.acq.processing = 1;
    % ��ʼ����������ʱ��
    channel_spc.acq.TimeLen = channel_spc.Samp_Posi;
end

Samp_Posi = channel_spc.Samp_Posi;
Samp_Posi_dot = channel_spc.Samp_Posi + channel_spc.acq.Samp_Posi_dot;  % ���Ƕ�����Ƶ��
sis = [channel_spc.acq.resiData, sis];
N = length(sis);                            % �����ݵĳ���
channel_spc.acq.resiData = [];


while(1)
    if (acqResults.acqed == 1) || (acqResults.acqed == -1)
        channel_spc.Samp_Posi = Samp_Posi;
        channel_spc.acq.processing = 0; % ����������н���
        if acqResults.acqed == -1
            channel_spc.acq.TimeLen = N;
        end
        break;
    elseif (acqResults.acqed == 0) && (channel_spc.acq.sampPer2TC_s+Samp_Posi<N)
        
        sis_index = (1:channel_spc.acq.sampPer2TC_s)+Samp_Posi;
        
        channel_spc.acq.TimeLen = channel_spc.acq.TimeLen + channel_spc.acq.sampPerTC_s - channel_spc.acq.skipNperCode; % ��¼�����ܹ�����Ҫ�Ĳ�������
        
        [channel_spc, acqResults] = acquireGPS_1ms(logConfig, channel_spc, sis(sis_index), acqResults, bpSampling_OddFold);       
        
        Samp_Posi_dot = Samp_Posi_dot + channel_spc.acq.sampPerTC_s - channel_spc.acq.skipNperCode;
        
         % �����Ĳ�������
        channel_spc.acq.skipNumberOfSamples = round(Samp_Posi_dot) - (Samp_Posi+channel_spc.acq.sampPerTC_s);
        
        Samp_Posi = round(Samp_Posi_dot);
        
        channel_spc.acq.Samp_Posi_dot = Samp_Posi_dot - Samp_Posi;
        
        
    elseif channel_spc.acq.sampPer2TC_s+Samp_Posi >= N   % Ϊ�˷�ֹ�������ݱ�Ե��������������Ծ���³����˴��ж�������Ϊ���ڵ���
        channel_spc.acq.resiData = sis(Samp_Posi+(1:(N-Samp_Posi)));       % ����δ���������
        channel_spc.Samp_Posi = 0;
        channel_spc.acq.resiN = length(channel_spc.acq.resiData);
        break;
    end
end