function [channel_spc, STATUS] = l1ca_fine_acq(CH_SYST, channel_spc, config, sis, N, ~)

%bpSampling_oddFold��δʹ��

global GSAR_CONSTANTS;
STATUS = channel_spc.CH_STATUS;  %�趨Ĭ�Ϸ���ֵ

if (channel_spc.acq.resiN > 0 )
    sis = [channel_spc.acq.resiData sis];  %�����ʣ�����ݣ��Ⱥϲ�
    N = N + channel_spc.acq.resiN;
    channel_spc.acq.resiData = [];
end

N_1ms = GSAR_CONSTANTS.STR_RECV.fs * 0.001;  %1ms���ݶ�Ӧ�Ĳ�������  (sampPerCode)
if (channel_spc.Samp_Posi + N_1ms >= N) %�����ݲ��㣬�����»�  ���ڵ��ڣ��������ݱ��ص�������
    channel_spc.acq.resiData = sis(channel_spc.Samp_Posi+1:N);
    channel_spc.acq.resiN = N - channel_spc.Samp_Posi;
    channel_spc.Samp_Posi = 0;
    return;
end

roughAcq = 1; %���ƿ���
if (roughAcq)
    roughAcqStep = 1/7; %62M����Ӧ8��������
    downRate = floor(roughAcqStep*GSAR_CONSTANTS.STR_RECV.fs/1.023e6); %����������
    if (downRate == 0)
        downRate = 1;
    end
    N_down = ceil(N_1ms/downRate); %������������ݵ���
else
    downRate = 1;
    N_down = N_1ms;
end

L1CA_acq_config = config.recvConfig.configPage.acqConfig.GPS_L1CA;
fd0 = channel_spc.LO2_fd;  %������Ƶ����������
freqN = round( L1CA_acq_config.fineFreqRange / L1CA_acq_config.fineFreqBin )+1; %Ƶ��������
fd_search = fd0 + ( -L1CA_acq_config.fineFreqRange/2 : L1CA_acq_config.fineFreqBin : L1CA_acq_config.fineFreqRange/2 ); %����������λ��
IF_search = GSAR_CONSTANTS.STR_RECV.IF_L1CA + fd_search; %ʵ������Ƶ��λ��
Tc = round(L1CA_acq_config.tcoh_fine*1000); %��ɻ��ֺ�����
Nc = L1CA_acq_config.ncoh_fine;
     
if (channel_spc.acq.processing ~= 1) %��һ�ν���Ҫ��ʼ��
    channel_spc.acq.accum = 0; %������ۼӴ���
    channel_spc.acq.corr_fine = zeros(1,freqN); %�ܻ��ֽ��
    channel_spc.acq.corrtmp_fine  = zeros(1,freqN); %ÿ����ɻ��ֽ��
    channel_spc.acq.carriPhase = 0;
    channel_spc.acq.Samp_Posi_dot = 0; %������λ�õ�С������
    %skipNperCode��ÿ1ms����������������ֵΪ1�����ʾÿ��1ms���ֺ�Ҫ��Samp_Posi��1��
    channel_spc.acq.skipNperCode = N_1ms * channel_spc.LO_Fcode_fd / GSAR_CONSTANTS.STR_L1CA.Fcode0; 
    
    channel_spc.acq.processing = 1;
end

fprintf('\t\tFine acq GPS L1CA PRN%2.2d:  Coherent time: %d*%.3fs ; FreqBin: %.0fHz ; FreqRange: %.0f~%.0fHz\n', ...
    channel_spc.PRNID, Nc, L1CA_acq_config.tcoh_fine, L1CA_acq_config.fineFreqBin, fd_search(1), fd_search(freqN));
    
t = downRate*(0:N_down-1)/ GSAR_CONSTANTS.STR_RECV.fs; %������ĺ�����ʱ���

%���ڱ��ز����룬����ͳһ������������Ƶ�����ɣ�����ͬ��Ƶ���á����ڸ���Ƶ�ʲ��С���������������ʧ�Ǻ�С�ġ�
%��GPS�ľ�������ԣ�����ʱ����ܳ���1ms, ��˱����ز��źŲ����ȼ��㡣���Ǳ������С�
codePhase = mod( floor((GSAR_CONSTANTS.STR_L1CA.Fcode0 + channel_spc.LO_Fcode_fd)*t), 1023 ) + 1;
samplingCodes = channel_spc.codeTable(codePhase);

% 1ms��ѭ��
while(1)
    sis_seg = sis( channel_spc.Samp_Posi + (1:downRate:N_1ms) );
    crt = ( downRate*(0:N_down-1) + channel_spc.acq.carriPhase) / GSAR_CONSTANTS.STR_RECV.fs;  %����ʱ�������Ҫ��һ����ɻ���ʱ���ڱ�������
    channel_spc.acq.carriPhase = channel_spc.acq.carriPhase + N_1ms;
    
    for i = 1:freqN
        carrierTable = exp( -1i*2*pi*IF_search(i).*crt );  %�����ز��ź�
        channel_spc.acq.corrtmp_fine(i) = channel_spc.acq.corrtmp_fine(i) + sum(sis_seg.*carrierTable.*samplingCodes);
    end
    channel_spc.acq.accum = channel_spc.acq.accum + 1;
    channel_spc.acq.Samp_Posi_dot = channel_spc.acq.Samp_Posi_dot - channel_spc.acq.skipNperCode;
    channel_spc.Samp_Posi = channel_spc.Samp_Posi + N_1ms + round(channel_spc.acq.Samp_Posi_dot);
    channel_spc.acq.carriPhase = channel_spc.acq.carriPhase + round(channel_spc.acq.Samp_Posi_dot); %ע��������ʱ��֤�ز���λ����
    channel_spc.acq.Samp_Posi_dot = channel_spc.acq.Samp_Posi_dot - round(channel_spc.acq.Samp_Posi_dot);
    
    if ( mod(channel_spc.acq.accum,Tc)==0 ) %�ﵽ��ɻ���ʱ��
        channel_spc.acq.corr_fine = channel_spc.acq.corr_fine + abs(channel_spc.acq.corrtmp_fine);
        channel_spc.acq.corrtmp_fine = zeros(1,freqN);
    end
    
    if ( channel_spc.acq.accum == Tc*Nc ) %�ﵽ�ۼӴ���
        [~, peak_freq_idx] = max(channel_spc.acq.corr_fine);
        if config.logConfig.isAcqPlotMesh
            Title = ['Fine Acq GPS PRN=',num2str(channel_spc.PRNID)];
            figure('Name',Title,'NumberTitle','off');
            plot(fd_search,channel_spc.acq.corr_fine); 
            xlabel('Freq doppler / Hz');
            ylabel('Corr');
        end
        channel_spc.acq.ACQ_STATUS = 2;
        channel_spc.LO2_fd = fd_search(peak_freq_idx);
        channel_spc.LO_Fcode_fd = channel_spc.LO2_fd / GSAR_CONSTANTS.STR_L1CA.L0Fc0_R;
        fprintf('\t\t\tSamp_Posi:%d,  Result: %.2fHz\n', channel_spc.Samp_Posi, channel_spc.LO2_fd );
      
        channel_spc.acq.processing = 0;
        channel_spc.acq.accum = 0;
        channel_spc.acq.corr_fine = zeros(1,freqN);
        channel_spc.acq.corrtmp_fine = zeros(1,freqN);       
        channel_spc.Samp_Posi = channel_spc.Samp_Posi - channel_spc.acq.resiN; %����ƴ��ǰ�Ĳ�����λ��
        channel_spc.acq.resiData = [];
        channel_spc.acq.resiN = 0;
        
        switch (CH_SYST)
            case 'GPS_L1CA'
                channel_spc.CH_STATUS = 'BIT_SYNC';
                STATUS = 'BIT_SYNC';
                channel_spc = coldBitSync_init_new(channel_spc, config, 'GPS_L1CA');
                
            case 'GPS_L1CA_L2C'
                STATUS = 'COLD_ACQ';
        end
        return;
    end
    
    %ѭ����������Ҫ�ж���������
    if (channel_spc.Samp_Posi + N_1ms >= N) %�����ݲ��㣬�����»�  ���ڵ��ڣ��������ݱ��ص�������
        channel_spc.acq.resiData = sis(channel_spc.Samp_Posi+1:N);
        channel_spc.acq.resiN = N - channel_spc.Samp_Posi;
        channel_spc.Samp_Posi = 0;
        return;
    end
    
end
    
