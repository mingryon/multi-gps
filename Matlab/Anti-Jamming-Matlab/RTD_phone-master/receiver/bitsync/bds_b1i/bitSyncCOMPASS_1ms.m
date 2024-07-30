function [channel, bitSyncResults] = bitSyncCOMPASS_1ms(logConfig, channel, sis, bitSyncResults)

global GSAR_CONSTANTS;

%number of circulation   ��ɻ���ʱ�䣨ÿ��1ms��
channel.bitSync.accum = channel.bitSync.accum + 1;
if (strcmp(channel.bitSync.STATUS,'strong'))
    nnchList = channel.bitSync.noncoh(1);
else
    nnchList = channel.bitSync.noncoh(2);
end

%the code frequency
Fcodesearch = channel.LO_Fcode0 + channel.LO_Fcode_fd;      % ����������յ�CA����
t = (0:channel.bitSync.sampPerCode-1) / GSAR_CONSTANTS.STR_RECV.fs;     %����1msʱ����62000�ȷݣ���1ms��ÿ���������ʱ��
codePhase = mod( floor( (Fcodesearch).*t ),  GSAR_CONSTANTS.STR_B1I.ChipNum)+1; % ����1ms�������У����������������λֵ����Χ��1-2046��
%samples of the PNR code
samplingCodes = channel.codeTable(codePhase);   % �������ɲ�������ı�׼CA��

% skipNumberOfSamples = floor(channel.skipNumberOfChips * sampPerCode_s * 1000 / Fcodesearch);
% sis = sis(mod((1:samp2Code_s)-skipNumberOfSamples-1, samp2Code_s)+1 );
% channel.skipNumberOfChips = channel.skipNumberOfChips + Fcodesearch/1000 - 2046;

% wipe off code     ȥ��CA��
siswipeoffcodes = sis.* samplingCodes;      
% generate the sampling instances for carrier phase, sampPerCode long
% ����1ms�������е�ÿ������������ȡ���ݶ�������Ӧ��ʱ�䣨���������õ�������λ�Ĳ�������Ϊ��ʼ�㣩
crt = ((0:channel.bitSync.sampPerCode-1) + channel.bitSync.carriPhase) / GSAR_CONSTANTS.STR_RECV.fs;
% �����ز���λ��ʼλ�Ա�֤bitͬ���׶��ز���λ��������
channel.bitSync.carriPhase = channel.bitSync.sampPerCode + channel.bitSync.carriPhase + channel.bitSync.skipNumberOfSamples;

if channel.bitSync.accum<=channel.bitSync.nhLength        % С���볤��20��
    nhCode = zeros(1, channel.bitSync.nhLength-channel.bitSync.accum);          % �����ƶ�������λ����NH��ǰ�油��
    nhCode = [nhCode channel.bitSync.nhCode(1:channel.bitSync.accum)];
elseif channel.bitSync.accum >nnchList*channel.bitSync.TC
    nhCode = zeros(1, channel.bitSync.accum-nnchList*channel.bitSync.TC);
    nhCode = [channel.bitSync.nhCode(channel.bitSync.accum+1-nnchList*channel.bitSync.TC:channel.bitSync.nhLength) nhCode];
else
    m = rem(channel.bitSync.accum-1, channel.bitSync.nhLength)+1;
    nhCode = channel.bitSync.nhCode(mod((1:channel.bitSync.nhLength)+m-1, channel.bitSync.nhLength)+1);
end

%-
% nhDoppler = GSAR_CONSTANTS.STR_RECV.bpSampling_OddFold * channel.LO2_fd * 1000 / GSAR_CONSTANTS.STR_B1I.B0;


% Ensure the noncoherent integration time
L = rem(channel.bitSync.accum-channel.bitSync.TC, channel.bitSync.TC)+1;    

for k=1:channel.bitSync.fnum         % �Ը���Ƶ������ɻ���
    
    dopplerfreq = (k-1)*channel.bitSync.fbin - channel.bitSync.frange/2;
    
    carrierFreq = GSAR_CONSTANTS.STR_RECV.IF_B1I + channel.LO2_fd + dopplerfreq;
    
    % carrier   ��cos()+j*sin()��ʾ
    carrierTable = generateCarrier(carrierFreq, crt);
     
    % wipe off carrier
    siswpf_2 = siswipeoffcodes.*carrierTable;
    
    corr = sum(siswpf_2, 2);
    
    channel.bitSync.corrtmp(k,:) = channel.bitSync.corrtmp(k,:) + corr * fliplr(nhCode);        % ��1ms�����ڸ�������λ��������
    
% Consider the doppler frequency of nh code, actually the effect is very small.   
%     for m = 1:channel.bitSync.nhLength
%         tt = (((m - 1) * channel.bitSync.sampPerCode) : (m * channel.bitSync.sampPerCode - 1)) / GSAR_CONSTANTS.STR_RECV.fs;
%         nhPhase = mod(floor((1000 + nhDoppler) .* tt), channel.bitSync.nhLength) + 1;
%         nhCodeR = fliplr(nhCode);
%         samplingnhCodes = nhCodeR(nhPhase); % NH sampling codes
%         siswpf_3 = siswpf_2 .* samplingnhCodes;
%         corr = sum(siswpf_3, 2);
%         channel.bitSync.corrtmp(k, m) = channel.bitSync.corrtmp(k, m) + corr;
%     end
   
    if channel.bitSync.accum>= channel.bitSync.TC      % �ж��Ƿ񵽴�10ms��ɻ���ʱ��
        channel.bitSync.corr(k, L) = channel.bitSync.corr(k, L) + abs(channel.bitSync.corrtmp(k,L));
        channel.bitSync.corrtmp(k,L)=0;
        if channel.PRNID > 5
            channel.bitSync.corr(k, L+channel.bitSync.TC) = channel.bitSync.corr(k, L+channel.bitSync.TC) + ...
                abs(channel.bitSync.corrtmp(k,L+channel.bitSync.TC));
            channel.bitSync.corrtmp(k,L+channel.bitSync.TC)=0;
        end
    end
end



if (channel.bitSync.accum == nnchList*channel.bitSync.TC+channel.bitSync.nhLength) && (strcmp(channel.bitSync.STATUS,'strong'))
    % find spike and determine variable
    [peak_nc_corr, peak_freq_idx, peak_code_idx, snr] = find2DPeak(channel.bitSync.corr);
    peak_code = sort(channel.bitSync.corr(peak_freq_idx,:),'descend');
    th = thresholdDetermineBitSync(channel.bitSync.TC, channel.bitSync.noncoh(1),'BDS');
    if (peak_code(1)/peak_code(end)) > th
        bitSyncResults.sv = channel.PRNID;
        bitSyncResults.synced = 1;
        bitSyncResults.nc_corr = channel.bitSync.corr;
        bitSyncResults.freqIdx = peak_freq_idx;
        bitSyncResults.bitIdx = peak_code_idx;
        bitSyncResults.doppler = (bitSyncResults.freqIdx-1)*channel.bitSync.fbin - channel.bitSync.frange/2;
        %correct bitsync
        fcorrect = bitSync_fcorrect(channel.bitSync.corr',channel.bitSync,bitSyncResults);
        bitSyncResults.doppler = bitSyncResults.doppler + fcorrect;
        %plot bitsync
        if logConfig.isSyncPlotMesh
            bitSync_plot(channel.bitSync.corr,bitSyncResults );
        end
    else
        channel.bitSync.accum = 0;
        channel.bitSync.corr = zeros(channel.bitSync.fnum, channel.bitSync.nhLength);
        channel.bitSync.STATUS = 'weak';
    end
end
if (channel.bitSync.accum == nnchList*channel.bitSync.TC+channel.bitSync.nhLength) && (strcmp(channel.bitSync.STATUS,'weak'))
    % find spike and determine variable
    [peak_nc_corr, peak_freq_idx, peak_code_idx, snr] = find2DPeak(channel.bitSync.corr);
    peak_code = sort(channel.bitSync.corr(peak_freq_idx,:),'descend');
    th = thresholdDetermineBitSync(channel.bitSync.TC, channel.bitSync.noncoh(2),'BDS');
    
    if (peak_code(1)/peak_code(end)) > th
        bitSyncResults.sv = channel.PRNID;
        bitSyncResults.synced = 1;
        bitSyncResults.nc_corr = channel.bitSync.corr;
        bitSyncResults.freqIdx = peak_freq_idx;
        bitSyncResults.bitIdx = peak_code_idx;
        bitSyncResults.doppler = (bitSyncResults.freqIdx-1)*channel.bitSync.fbin - channel.bitSync.frange/2;
        %correct bitsync
        fcorrect = bitSync_fcorrect(channel.bitSync.corr',channel.bitSync,bitSyncResults);
        bitSyncResults.doppler = bitSyncResults.doppler + fcorrect;
        %plot bitsync
        if logConfig.isSyncPlotMesh
            bitSync_plot(channel.bitSync.corr,bitSyncResults );
        end
    else
        channel.bitSync.accum = 0;
        channel.bitSync.corr = zeros(channel.bitSync.fnum, channel.bitSync.nhLength);
        channel.bitSync.STATUS = 'wait';
        channel.bitSync.waitNum = GSAR_CONSTANTS.STR_RECV.fs*channel.bitSync.waitSec;
    end
end
if (channel.bitSync.accum == nnchList*channel.bitSync.TC+channel.bitSync.nhLength) && (strcmp(channel.bitSync.STATUS,'wait'))
    % find spike and determine variable
    [peak_nc_corr, peak_freq_idx, peak_code_idx, snr] = find2DPeak(channel.bitSync.corr);
    peak_code = sort(channel.bitSync.corr(peak_freq_idx,:),'descend');
    th = thresholdDetermineBitSync(channel.bitSync.TC, channel.bitSync.noncoh(2),'BDS');
    
    if (peak_code(1)/peak_code(end)) > th
        bitSyncResults.sv = channel.PRNID;
        bitSyncResults.synced = 1;
        bitSyncResults.nc_corr = channel.bitSync.corr;
        bitSyncResults.freqIdx = peak_freq_idx;
        bitSyncResults.bitIdx = peak_code_idx;
        bitSyncResults.doppler = (bitSyncResults.freqIdx-1)*channel.bitSync.fbin - channel.bitSync.frange/2;
        %correct bitsync
        fcorrect = bitSync_fcorrect(channel.bitSync.corr',channel.bitSync,bitSyncResults);
        bitSyncResults.doppler = bitSyncResults.doppler + fcorrect;
        %plot bitsync
        if logConfig.isSyncPlotMesh
            bitSync_plot(channel.bitSync.corr,bitSyncResults );
        end
    elseif channel.bitSync.waitTimes > 0
        channel.bitSync.accum = 0;
        channel.bitSync.corr = zeros(channel.bitSync.fnum, channel.bitSync.nhLength);
        channel.bitSync.STATUS = 'wait';
        channel.bitSync.waitNum = GSAR_CONSTANTS.STR_RECV.fs*channel.bitSync.waitSec;
        channel.bitSync.waitTimes = channel.bitSync.waitTimes - 1;
    else
        channel.bitSync.accum = 0;
        channel.bitSync.corr = zeros(channel.bitSync.fnum, channel.bitSync.nhLength);
        bitSyncResults.synced = -1;
    end
end

