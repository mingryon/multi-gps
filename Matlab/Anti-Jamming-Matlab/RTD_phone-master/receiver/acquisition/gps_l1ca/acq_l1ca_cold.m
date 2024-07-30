function channel = acq_l1ca_cold(config, channel, satelliteTable, sis, N)
% ���ٰ�CA���䲶���޸����ݣ�
% 1. ȡ���������������������Ƶ��ʼ��ʹ��������գ�
% 2. �����ز����ɺͱ�����ĸ���Ҷ�任����whileѭ���⣬�����ظ����㣻
% 3. ����Ҷ���ȴ�2ms����1ms;
% 4. �ֲ����õ����ȼ��㡣
% Ĭ��1ms��ɻ���ʱ�䣬��֧����������

global GSAR_CONSTANTS;
switch (channel.SYST)
    case 'GPS_L1CA'
        channel_spc = channel.CH_L1CA;
    case 'GPS_L1CA_L2C'
        channel_spc = channel.CH_L1CA_L2C;
end

if (channel_spc.acq.resiN > 0 )
    sis = [channel_spc.acq.resiData sis];  %�����ʣ�����ݣ��Ⱥϲ�
    N = N + channel_spc.acq.resiN;
    channel_spc.acq.resiData = [];
end

N_1ms = GSAR_CONSTANTS.STR_RECV.fs * 0.001;  %1ms���ݶ�Ӧ�Ĳ�������  (sampPerCode)

roughAcq = 0; %���ƿ���
%ע�����ڸ���Ҷ�任�ڵ�������2,3,5��������ʱ������죬��˽��������ʲ���Խ��Խ�á�����62M�Ĳ����ʣ�����������2,4,8Ϊ�ˡ�
if (roughAcq)
    roughAcqStep = 1/7; %62M����Ӧ8��������
    downRate = floor(roughAcqStep*GSAR_CONSTANTS.STR_RECV.fs/1.023e6); %����������
    if (downRate >= 8)
        downRate = 8;
    elseif (downRate>= 4)
        downRate = 4;
    elseif (downRate>= 2)
        downRate = 2;
    elseif (downRate == 0)
        downRate = 1;
    end
    N_down = ceil(N_1ms/downRate); %������������ݵ���
else
    downRate = 1;
    N_down = N_1ms;
end

L1CA_acq_config = config.recvConfig.configPage.acqConfig.GPS_L1CA;
freqN = round( L1CA_acq_config.freqRange / L1CA_acq_config.freqBin )+1; %Ƶ��������
fd_search = ( -L1CA_acq_config.freqRange/2 : L1CA_acq_config.freqBin : L1CA_acq_config.freqRange/2 ); %����������λ��
IF_search = GSAR_CONSTANTS.STR_RECV.IF_L1CA + fd_search; %ʵ������Ƶ��λ��
Nc = L1CA_acq_config.nnchList(1);

if (channel_spc.acq.processing ~= 1) %��һ�ν���Ҫ��ʼ��
    channel_spc.codeTable = GSAR_CONSTANTS.PRN_CODE.CA_code(channel_spc.PRNID,:);
    channel_spc.acq.accum = 0; %������ۼӴ���
    channel_spc.acq.corr = zeros(freqN,N_down); %�ܻ��ֽ��
   
    channel_spc.acq.processing = 1;
end

fprintf('     %s GPS PRN%d:  Coherent accumulation: %1.3fs ; FreqBin: %dHz ; FreqRange: -%d~+%dHz\n', ...
            channel_spc.CH_STATUS, channel_spc.PRNID, L1CA_acq_config.tcoh, L1CA_acq_config.freqBin, L1CA_acq_config.freqRange/2, L1CA_acq_config.freqRange/2);
      
sis = single(sis);
%Ԥ�ȼ��㱾���ز��ͱ������fft
t_1ms = single( downRate*(0:N_down-1)/GSAR_CONSTANTS.STR_RECV.fs );  %1msʱ���
carrierTable = single( zeros(freqN, N_down) );  %���汾�ظ��ز�
for i = 1:freqN
    carrierTable(i,:) = exp( -1j*2*pi*IF_search(i).*t_1ms );
end
codeTable = single(channel_spc.codeTable( mod( floor(1.023e6*t_1ms),1023 ) + 1));  
codeTable_fft = conj(fft(codeTable));

% ��ѭ��
while 1
    sis_seg = sis( channel_spc.Samp_Posi + (1:downRate:N_1ms) );
    
    for i = 1:freqN
        sis_fft = fft(sis_seg.*carrierTable(i,:));
        channel_spc.acq.corr(i,:) = channel_spc.acq.corr(i,:) + abs( ifft(sis_fft.*codeTable_fft) );
    end
    
    channel_spc.acq.accum = channel_spc.acq.accum + 1;
    channel_spc.Samp_Posi = channel_spc.Samp_Posi + N_1ms;
    
    if ( channel_spc.acq.accum == Nc ) %�ﵽ�ۼӴ���
        [~, peak_freq_idx, peak_code_idx, svSnr] = find2DPeak(channel_spc.acq.corr);
                  
        if (svSnr>L1CA_acq_config.thre_stronmode ) %����ɹ�
            if (config.logConfig.isAcqPlotMesh)
                acq_plot_new('GPS_L1CA',channel_spc.acq.corr, fd_search, peak_freq_idx, peak_code_idx, channel_spc.PRNID);
            end
            peak_code_idx = downRate*peak_code_idx+1-downRate; %�ӽ����������ԭ���Ĳ�����λ��
            channel_spc.acq.ACQ_STATUS = 1; %����                               
            channel_spc.LO2_fd = fd_search(peak_freq_idx);
            channel_spc.LO_Fcode_fd = channel_spc.LO2_fd / 1540;
            channel_spc.Samp_Posi = channel_spc.Samp_Posi - channel_spc.acq.resiN + peak_code_idx;
            channel_spc.CN0_Estimator.CN0 = 10*log10(svSnr/L1CA_acq_config.tcoh); 
            fprintf('                    Succeed!  NonCohn_Accu: %d (StrongMode) -- ', Nc);
            fprintf('CodeIndx: %d ; Doppler: %.2fHz ; CN0: %.1fdB \n', ...
                channel_spc.Samp_Posi, channel.bpSampling_OddFold*channel_spc.LO2_fd, channel_spc.CN0_Estimator.CN0);
            
        else %����ʧ��
            fprintf('                    Fail! NonCohn_Accu: : %d.\n', Nc);
            if satelliteTable(2).satVisible(channel_spc.PRNID)==1 % ���ж����ǿɼ��򲶻�����
                channel.STATUS = 'COLD_ACQ_AGAIN';
                channel_spc.CH_STATUS = channel.STATUS;
                channel_spc.Samp_Posi = 0;
            else
                channel.STATUS = 'ACQ_FAIL'; 
                channel_spc.CH_STATUS = 'ACQ_FAIL';     
            end
        end
        
        channel_spc.acq.accum = 0;
        channel_spc.acq.corr = [];
        channel_spc.acq.resiData = [];
        channel_spc.acq.resiN = 0;        
        channel_spc.acq.processing = 0;
        
        switch (channel.SYST)
            case 'GPS_L1CA'
                channel.CH_L1CA = channel_spc;                
            case 'GPS_L1CA_L2C'
                channel.CH_L1CA_L2C = channel_spc;
        end
        return;
    end
    
    %ѭ����������Ҫ�ж���������
    if (channel_spc.Samp_Posi + N_1ms > N) %�����ݲ��㣬�����»�
        channel_spc.acq.resiData = sis(channel_spc.Samp_Posi+1:N);
        channel_spc.acq.resiN = N - channel_spc.Samp_Posi;
        channel_spc.Samp_Posi = 0;
        switch (channel.SYST)
            case 'GPS_L1CA'
                channel.CH_L1CA = channel_spc;
            case 'GPS_L1CA_L2C'
                channel.CH_L1CA_L2C = channel_spc;
        end
        return;
    end
    
end
    
    