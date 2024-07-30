function [channel_spec, bitSyncResults] = bitSyncGPS(logConfig, channel_spec, sis, bitSyncResults)

if ~size(channel_spec.bitSync.corr)
%     fprintf('/----------------------------------------------------------------------------------------------/\n');
    fprintf('     BitSyncing GPS PRN%d:  Coherent accumulation: %1.3fs ; Non-coherent: %d ; FreqBin: %dHz ; FreqRange: -%d~+%dHz\n', ...
        channel_spec.PRNID, channel_spec.bitSync.TC/1000, channel_spec.bitSync.noncoh(1), channel_spec.bitSync.fbin, channel_spec.bitSync.frange/2, channel_spec.bitSync.frange/2);
    
    bitSyncResults.sv = channel_spec.PRNID;
    channel_spec.bitSync.corr = zeros(channel_spec.bitSync.fnum, channel_spec.bitSync.nhLength);
    channel_spec.bitSync.corrtmp = zeros(channel_spec.bitSync.fnum, channel_spec.bitSync.nhLength);
    channel_spec.bitSync.TimeLen = 0;
end    

Samp_Posi = channel_spec.Samp_Posi;              % �����㴫��
Samp_Posi_dot = channel_spec.Samp_Posi + channel_spec.bitSync.Samp_Posi_dot;          % ����������յĲ�����λ��
sis = [channel_spec.bitSync.resiData sis];       % ����ǰ������������
N = length(sis);                            % �����ݵĳ���
channel_spec.bitSync.resiData = [];

while 1
    if (bitSyncResults.synced==1)||(bitSyncResults.synced==-1)
        channel_spec.Samp_Posi = Samp_Posi;
        break;
    elseif (bitSyncResults.synced==0)&&(Samp_Posi+channel_spec.bitSync.sampPerCode<N)
        % 1 code of sis data(2046 chips)
        sis_index = (1:channel_spec.bitSync.sampPerCode)+Samp_Posi;
        % add time
        channel_spec.bitSync.TimeLen = channel_spec.bitSync.TimeLen + channel_spec.bitSync.sampPerCode - channel_spec.bitSync.skipNperCode;
        % 1ms bitSync
        if channel_spec.bitSync.waitNum <= 0
            [channel_spec, bitSyncResults] = bitSyncGPS_1ms(logConfig, channel_spec, sis(sis_index), bitSyncResults);
        else
            channel_spec.bitSync.waitNum = channel_spec.bitSync.waitNum - length(sis_index);
        end
        % ��������Ŀ��һ��NH��Ƭ������������յ�Ӱ��
        Samp_Posi_dot = Samp_Posi_dot + channel_spec.bitSync.sampPerCode - channel_spec.bitSync.skipNperCode;
        % �����Ĳ�������
        channel_spec.bitSync.skipNumberOfSamples = round(Samp_Posi_dot) - (Samp_Posi+channel_spec.bitSync.sampPerCode);
        Samp_Posi = round(Samp_Posi_dot);   % ������ȡ�����ڵ�ǰѭ���и�����һѭ����������ʼλ��������ֻ�ڴ˴���������  
        channel_spec.bitSync.Samp_Posi_dot = Samp_Posi_dot - Samp_Posi; % ��һѭ����ʼλ�Ѹ��£�����˴�ֵС��0.5
        
    elseif (Samp_Posi+channel_spec.bitSync.sampPerCode>=N)    % Ϊ�˷�ֹ�������ݱ�Ե��������������Ծ���³����˴��ж�������Ϊ���ڵ���
        channel_spec.bitSync.resiData = sis(Samp_Posi+(1:(N-Samp_Posi)));        
        channel_spec.Samp_Posi = 0; 
        channel_spec.bitSync.resiN = length(channel_spec.bitSync.resiData);
        break;
    end
end
