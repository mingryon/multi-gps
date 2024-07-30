function [channel, bitSyncResults, sis,N] = bitSyncCOMPASS_N(config, sv_bitSync_cfg, channel, sis, N, bitSyncResults)

global GSAR_CONSTANTS;
Nms = 4;                    % ÿ�δ���ĺ�����
if ~size(channel.bitSync.offCarri)
    if strcmp(channel.navType, 'B1I_D2')
        fprintf('BitSyncing BD GEO PRN%d ; Coherent accumulation: %1.3fs ; Non-coherent: %d ; FreqBin: %dHz ; FreqRange: -%d~+%dHz\n', ...
            channel.PRNID, sv_bitSync_cfg.tcoh, sv_bitSync_cfg.nnchList, sv_bitSync_cfg.freqBin, sv_bitSync_cfg.freqRange/2, sv_bitSync_cfg.freqRange/2);
    else
        fprintf('BitSyncing BD NGEO PRN%d ; Coherent accumulation: %1.3fs ; Non-coherent: %d ; FreqBin: %dHz ; FreqRange: -%d~+%dHz\n', ...
            channel.PRNID, sv_bitSync_cfg.tcoh, sv_bitSync_cfg.nnchList, sv_bitSync_cfg.freqBin, sv_bitSync_cfg.freqRange/2, sv_bitSync_cfg.freqRange/2);
    end
    
    bitSyncResults.sv = channel.PRNID;
    
    % TC: coherent time length at nominal code frequency
    channel.bitSync.TC = round(sv_bitSync_cfg.tcoh*1e3);
    
    % finer dopplar search
    channel.bitSync.frange = sv_bitSync_cfg.freqRange;
    channel.bitSync.fbin = sv_bitSync_cfg.freqBin;
    channel.bitSync.fnum = channel.bitSync.frange/channel.bitSync.fbin + 1;
    
    % NH code for each channel
    % Get the NH code and its samplings; by default NH code frequency is 1000Hz
    if channel.PRNID > 5
        channel.bitSync.nhCode = [0 0 0 0 0 1 0 0 1 1 0 1 0 1 0 0 1 1 1 0];
        channel.bitSync.nhLength = 20;
    else
        channel.bitSync.nhCode = [1 1];
        channel.bitSync.nhLength = 2;
    end
    channel.bitSync.nhCode(channel.bitSync.nhCode == 0) = -1;       % ��NH��תΪ˫������
    
    %the code frequency
    % ����������ս�����CA�����Ƶ��
    channel.bitSync.Fcodesearch = channel.LO_Fcode0 + channel.LO_Fcode_fd; 
    % һ����׼CA�������ڵĲ�������
    channel.bitSync.sampPerCode = round(GSAR_CONSTANTS.STR_B1I.ChipNum / channel.bitSync.Fcodesearch *  GSAR_CONSTANTS.STR_RECV.fs);       
    channel.bitSync.skipNumberOfSamples = 0;
    % ÿ��CA��������(��62000��������)�������������ٵĵĲ�����ı仯
    channel.bitSync.skipNperCode = channel.bitSync.sampPerCode * (1 - GSAR_CONSTANTS.STR_B1I.Fcode0/channel.bitSync.Fcodesearch);       
    
    channel.bitSync.accum = 0;
    channel.bitSync.corr = [];
    channel.bitSync.corrtmp = [];
    channel.bitSync.carriPhase = channel.Samp_Posi - channel.bitSync.sampPerCode*Nms;     % ���������ز�����ʼʱ���Ӧ�Ĳ�����
end    

% Num_Code = floor((N+1-channel.Samp_Posi)/channel.bitSync.sampPerCode);      % ��ȥ����׶����õ�20ms���ݺ�����λ����������ݻ�ʣ���ٸ�CA������
%  Num_Processed = 0;
Samp_Posi = channel.Samp_Posi + round(channel.bitSync.Samp_Posi_dot);              % ȡ����Ĳ�����λ��
Samp_Posi_dot = channel.Samp_Posi + channel.bitSync.Samp_Posi_dot;          % ����������յĲ�����λ��
sis = [sis(1:62000) channel.bitSync.resiData sis(62001:end)];       % ����ǰ������������
N = length(sis);                            % �����ݵĳ���

while 1
    if(bitSyncResults.synced==1)||(bitSyncResults.synced==-1)
        channel.Samp_Posi = Samp_Posi;
        break;
    elseif(bitSyncResults.synced==0)&&(Samp_Posi+channel.bitSync.sampPerCode*Nms<=N)
        % 1 code of sis data(2046 chips)
        sis_index = (1:channel.bitSync.sampPerCode*Nms)+Samp_Posi;
        % 1ms bitSync
        [channel, bitSyncResults] = bitSyncCOMPASS_Nms(config, sv_bitSync_cfg, channel, sis(sis_index), bitSyncResults,Nms);
%         % compensation of code phase
%         channel.bitSync.skipNumberOfSamples = channel.bitSync.skipNumberOfSamples + channel.bitSync.skipNperCode;
%         skipNumberOfSamples = floor(channel.bitSync.skipNumberOfSamples);
%         channel.bitSync.skipNumberOfSamples = channel.bitSync.skipNumberOfSamples - skipNumberOfSamples;
        
        % This statement seems to be wrong, compensation may lead to a doppler frequency bias, delete 'skipNumberOfSamples' results correct value.
%         Samp_Posi = Samp_Posi + channel.bitSync.sampPerCode - skipNumberOfSamples;
        % ��������Ŀ��һ��NH��Ƭ������������յ�Ӱ��
        Samp_Posi_dot = Samp_Posi_dot + channel.bitSync.sampPerCode*Nms - channel.bitSync.skipNperCode*Nms;
        channel.bitSync.Samp_Posi_dot = Samp_Posi_dot - (Samp_Posi+channel.bitSync.sampPerCode*Nms);
        % �����Ĳ�������
        channel.bitSync.skipNumberOfSamples = round(Samp_Posi_dot) - (Samp_Posi+channel.bitSync.sampPerCode*Nms);
        Samp_Posi = round(Samp_Posi_dot);   % ������ȡ��
%         channel.bitSync.accum = Num_Processed + 1;
    elseif (Samp_Posi+channel.bitSync.sampPerCode*Nms>N)
        channel.bitSync.resiData = sis(Samp_Posi+(0:(N-Samp_Posi)));        % �ഫ��һ�������㣬�Է��´�ѭ����Ҫ��һ��������
        channel.Samp_Posi = 1;      
        break; 
%     elseif 
    end
end






