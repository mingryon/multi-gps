function [channel, bitSyncResults] = bitSyncCOMPASS_Nms(config, sv_bitSync_cfg, channel, sis, bitSyncResults, Nms)

global GSAR_CONSTANTS;

%number of circulation   ��ɻ���ʱ�䣨ÿ��1ms��
channel.bitSync.accum = channel.bitSync.accum + 1;

%the code frequency
Fcodesearch = channel.LO_Fcode0 + channel.LO_Fcode_fd;      % ����������յ�CA����
t = (0:channel.bitSync.sampPerCode*Nms-1) / GSAR_CONSTANTS.STR_RECV.fs;     %����Nmsʱ����62000�ȷݣ���1ms��ÿ���������ʱ��
codePhase = mod( floor( (Fcodesearch).*t ),  GSAR_CONSTANTS.STR_B1I.ChipNum)+1; % ����Nms�������У����������������λֵ����Χ��1-2046��
%samples of the PNR code
samplingCodes = channel.codeTable(codePhase);   % �������ɲ�������ı�׼CA��

% skipNumberOfSamples = floor(channel.skipNumberOfChips * sampPerCode_s * 1000 / Fcodesearch);
% sis = sis(mod((1:samp2Code_s)-skipNumberOfSamples-1, samp2Code_s)+1 );
% channel.skipNumberOfChips = channel.skipNumberOfChips + Fcodesearch/1000 - 2046;

% wipe off code     ȥ��CA��
siswipeoffcodes = sis.* samplingCodes;      
% generate the sampling instances for carrier phase, sampPerCode long
% �����ز���λ��ʼλ�Ա�֤bitͬ���׶��ز���λ��������
channel.bitSync.carriPhase = channel.bitSync.sampPerCode*Nms + channel.bitSync.carriPhase + channel.bitSync.skipNumberOfSamples;
% ����Nms�������е�ÿ������������ȡ���ݶ�������Ӧ��ʱ�䣨���������õ�������λ�Ĳ�������Ϊ��ʼ�㣩
crt = ((0:channel.bitSync.sampPerCode*Nms-1) + channel.bitSync.carriPhase) / GSAR_CONSTANTS.STR_RECV.fs;
% if channel.bitSync.accum<=channel.bitSync.nhLength        % С�ڷ�����ۼӴ�����20��
%     nhCode = zeros(1, channel.bitSync.nhLength-channel.bitSync.accum);          % �����ƶ�������λ����NH��ǰ�油��
%     nhCode = [nhCode channel.bitSync.nhCode(1:channel.bitSync.accum)];
% elseif channel.bitSync.accum >sv_bitSync_cfg.nnchList*channel.bitSync.TC
%     nhCode = zeros(1, channel.bitSync.accum-sv_bitSync_cfg.nnchList*channel.bitSync.TC);
%     nhCode = [channel.bitSync.nhCode(channel.bitSync.accum+1-sv_bitSync_cfg.nnchList*channel.bitSync.TC:channel.bitSync.nhLength) nhCode];
% else
%     m = rem(channel.bitSync.accum-1, channel.bitSync.nhLength)+1;
%     nhCode = channel.bitSync.nhCode(mod((1:channel.bitSync.nhLength)+m-1, channel.bitSync.nhLength)+1);
% end

%-
% nhDoppler = GSAR_CONSTANTS.STR_RECV.bpSampling_OddFold * channel.LO2_fd * 1000 / GSAR_CONSTANTS.STR_B1I.B0;


% Ensure the noncoherent integration time
% L = rem(channel.bitSync.accum-channel.bitSync.TC, channel.bitSync.TC)+1;    

for k=1:channel.bitSync.fnum         % �Ը���Ƶ������ɻ���
    
    dopplerfreq = (k-1)*channel.bitSync.fbin - channel.bitSync.frange/2;
    
    carrierFreq = GSAR_CONSTANTS.STR_RECV.IF + channel.LO2_fd + dopplerfreq;
    
    % carrier   ��cos()+j*sin()��ʾ
    carrierTable = generateCarrier(carrierFreq, crt);
     
    % wipe off carrier
    siswpf_2 = siswipeoffcodes.*carrierTable;
    
    % ��Nms����ȥ���ز�
    for kk = 1 : Nms
        channel.bitSync.offCarri(k,(channel.bitSync.accum-1)*Nms+kk) = ...
            sum(siswpf_2((kk-1)*channel.bitSync.sampPerCode+(1:channel.bitSync.sampPerCode)));
    end
    
end 


%     channel.bitSync.corrtmp(k,:) = channel.bitSync.corrtmp(k,:) + corr * fliplr(nhCode);        % ��1ms�����ڸ�������λ��������  
%     if channel.bitSync.accum>= channel.bitSync.TC      % �ж��Ƿ񵽴�10ms��ɻ���ʱ��
%         channel.bitSync.corr(k, L) = channel.bitSync.corr(k, L) + abs(channel.bitSync.corrtmp(k,L));
%         channel.bitSync.corrtmp(k,L)=0;
%         if channel.PRNID > 5
%             channel.bitSync.corr(k, L+channel.bitSync.TC) = channel.bitSync.corr(k, L+channel.bitSync.TC) + ...
%                 abs(channel.bitSync.corrtmp(k,L+channel.bitSync.TC));
%             channel.bitSync.corrtmp(k,L+channel.bitSync.TC)=0;
%         end
%     end




if channel.bitSync.accum*Nms == sv_bitSync_cfg.nnchList*channel.bitSync.TC
    nhCode = repmat(channel.bitSync.nhCode,[13,10]);     % ��NH����չ10�Σ����ظ�13��
    for nhPhase = 1 : 20
        % ��20������λ�����
        channel.bitSync.corrtmp(:,:,rem(nhPhase,20)+1) = channel.bitSync.offCarri.*circshift(nhCode',nhPhase)';
    end
    for sumTimes = 1:sv_bitSync_cfg.nnchList
        % ��10ms����ɻ���
        cohMatrix(:,sumTimes,:) = sum(channel.bitSync.corrtmp(:,(sumTimes-1)*channel.bitSync.TC+(1:channel.bitSync.TC),:),2);
    end
    cohMatrix = sum(abs(cohMatrix),2);  % ������ۼ�
    channel.bitSync.corr = cohMatrix(:,:);      % ��ά
    % find spike and determine variable
    [peak_nc_corr, peak_freq_idx, peak_code_idx, ~] = find2DPeak(channel.bitSync.corr);
    bitSyncResults.sv = channel.PRNID;
    bitSyncResults.synced = 1;
    bitSyncResults.nc_corr = channel.bitSync.corr;
    bitSyncResults.freqIdx = peak_freq_idx;
    bitSyncResults.bitIdx = peak_code_idx;
    bitSyncResults.doppler = (bitSyncResults.freqIdx-1)*channel.bitSync.fbin - channel.bitSync.frange/2;
    %correct bitsync
    if  sv_bitSync_cfg.fcorrect
        fcorrect = bitSync_fcorrect(channel.bitSync.corr',sv_bitSync_cfg,bitSyncResults);
    end
    bitSyncResults.doppler = bitSyncResults.doppler + fcorrect;
    %plot bitsync
    if config.isSyncPlotMesh
        bitSync_plot(channel.bitSync.corr,bitSyncResults );
    end
elseif channel.bitSync.accum > sv_bitSync_cfg.nnchList*channel.bitSync.TC+channel.bitSync.nhLength
    bitSyncResults.synced = -1;
end