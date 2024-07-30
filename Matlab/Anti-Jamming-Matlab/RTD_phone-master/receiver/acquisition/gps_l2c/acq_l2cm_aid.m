function [channel_spc, STATUS] = acq_l2cm_aid(channel_spc, config, sis, N, ~)

%bpSampling_OddFold ���޸�
%CM�벶����Ҫ���Ƶ�ʣ���20����λ���ֿ�ʼʱ�������ͬ������������Ϸ�����
%Ϊ�˼򻯣��������ڻ��ֹ����в��������������������������������ͳһ������������CM�벶��ʱ��϶�һ��Ϊ39ms��59ms��������ʧ��С��
%��ɻ���ʱ��̶�Ϊ20ms

global GSAR_CONSTANTS;
STATUS = channel_spc.CH_STATUS;  %�趨Ĭ�Ϸ���ֵ

if (channel_spc.acq.resiN > 0 )
    sis = [channel_spc.acq.resiData sis];  %�����ʣ�����ݣ��Ⱥϲ�
    N = N + channel_spc.acq.resiN;
    channel_spc.acq.resiData = [];
end

N_1ms = GSAR_CONSTANTS.STR_RECV.fs * 0.001;  %1ms���ݶ�Ӧ�Ĳ�������  (sampPerCode)
if (channel_spc.Samp_Posi + N_1ms > N) %�����ݲ��㣬�����»�, �����������ô��ں�
    channel_spc.acq.resiData = sis(channel_spc.Samp_Posi+1:N);
    channel_spc.acq.resiN = N - channel_spc.Samp_Posi;
    channel_spc.Samp_Posi = 0;
    return;
end

l2c_acq_config = config.recvConfig.configPage.acqConfig.GPS_L2C_aid;
fd0 = GSAR_CONSTANTS.STR_L2C.L2L1_FreqRatio * channel_spc.LO2_fd; %Ƶ����������
freqN = round( l2c_acq_config.freqRange / l2c_acq_config.freqBin )+1; %Ƶ��������
fd_search = fd0 + ( -l2c_acq_config.freqRange/2 : l2c_acq_config.freqBin : l2c_acq_config.freqRange/2 ); %����������λ��
IF_search = GSAR_CONSTANTS.STR_RECV.IF_L2C + fd_search; %ʵ������Ƶ��λ��
Tc = round(l2c_acq_config.tcoh*1000); %��ɻ��ֺ�����
Nc = l2c_acq_config.ncoh; %�ۼӴ���

if (channel_spc.acq.processing ~= 1) %��һ�ν���Ҫ��ʼ��
    channel_spc.acq.accum = 0; %������ۼӴ���
    channel_spc.acq.CM_corr = zeros(freqN,20); %�ܻ��ֽ��
    channel_spc.acq.CM_corrtmp  = zeros(freqN,20); %ÿ����ɻ��ֽ��
    channel_spc.acq.carriPhase_vt = zeros(freqN,1); %�����Ƶ����ز���λ��Ϣ,0~1��һ��  
    channel_spc.acq.processing = 1;
end

fprintf('\t\tAcquire GPS L2CM PRN%2.2d:  Coherent time: %d*%.3fs ; FreqBin: %.0fHz ; FreqRange: %.2f~%.2fHz\n', ...
    channel_spc.PRNID, Nc, l2c_acq_config.tcoh, l2c_acq_config.freqBin, fd_search(1), fd_search(freqN));

t_1ms = (0:N_1ms-1)/GSAR_CONSTANTS.STR_RECV.fs;  %1msʱ���
t_20ms = (0:20*N_1ms-1)/GSAR_CONSTANTS.STR_RECV.fs;  %20msʱ���
CM_code = GSAR_CONSTANTS.PRN_CODE.RZCM_code(channel_spc.PRNID,:); %ȡ����Ӧ��Ƶ��

%������20ms���ز����룬ÿ·���ֻ���н�ȡһ��ʹ�ã�����������ѭ���е��ظ�����
 %CM0 ����1.023M �볤20460 ����20ms ��Ƭ���ز���������1200
codeTable = CM_code( mod( floor( (1.023e6 + fd0/1200)*t_20ms ), 20460 ) + 1 );  %���ز���CM0��


%������ѭ��
while 1
    sis_seg = sis( channel_spc.Samp_Posi + (1:N_1ms) );
    Phase = mod(channel_spc.acq.accum,20)+1; %1~20,�ӻ��ֿ�ʼ�����ĺ�������1����0~1ms,��������
    
    for i=1:freqN
        sis_seg_swpt = sis_seg.*exp( -1j*2*pi*( IF_search(i).*t_1ms+channel_spc.acq.carriPhase_vt(i) ) ); %�ز�����
        channel_spc.acq.carriPhase_vt(i) = mod(channel_spc.acq.carriPhase_vt(i)+ IF_search(i)*0.001,1); %��λ�ƽ�,ÿ��ģ1�ɼ�С�������
        
        if (channel_spc.acq.accum<19) %0~19ms:�����׶�
            for k = 1:Phase
                channel_spc.acq.CM_corrtmp(i,k) = channel_spc.acq.CM_corrtmp(i,k) + sum( sis_seg_swpt.*codeTable( (Phase-k)*N_1ms+(1:N_1ms)) );
            end     
            
        elseif (channel_spc.acq.accum<20*Nc)  %19~20n ms:ƽ�Ƚ׶�       
            for k = 1:20
                channel_spc.acq.CM_corrtmp(i,k) = channel_spc.acq.CM_corrtmp(i,k) + sum( sis_seg_swpt.*codeTable( (mod(Phase-k,20))*N_1ms+(1:N_1ms)) );
            end
                      
        else %20n~20n+19 ms:��β�׶�           
            for k = Phase+1:20
                channel_spc.acq.CM_corrtmp(i,k) = channel_spc.acq.CM_corrtmp(i,k) + sum( sis_seg_swpt.*codeTable( (mod(Phase-k,20))*N_1ms+(1:N_1ms)) );
            end           
        end
    end
    
    channel_spc.Samp_Posi = channel_spc.Samp_Posi + N_1ms;
    channel_spc.acq.accum = channel_spc.acq.accum + 1;
    if (channel_spc.acq.accum>=Tc) %����20ms����ɻ���ʱ�䣬��ȡģ���ӵ����յ��ۼӽ����ȥ
        Pos = mod(Phase,20)+1;
        channel_spc.acq.CM_corr(:,Pos) = channel_spc.acq.CM_corr(:,Pos) + abs(channel_spc.acq.CM_corrtmp(:,Pos));
        channel_spc.acq.CM_corrtmp(:,Pos) = 0;
    end
    
    %�ﵽ�趨���ۼӴ��������ֽ���
    if (channel_spc.acq.accum>=Tc*Nc+19)
        [peak_nc_corr, peak_freq_idx, peak_code_phase, th] = find2DPeakWithThre(channel_spc.acq.CM_corr, 'CM');
        if (th>l2c_acq_config.thre_CM) %����ɹ�
            if config.logConfig.isAcqPlotMesh
                Title = ['Acq GPS_L2CM PRN=',num2str(channel_spc.PRNID)];
                figure('Name',Title,'NumberTitle','off');
                mesh(1:20,fd_search,channel_spc.acq.CM_corr);
                xlabel('Code position');
                ylabel('Freq doppler / Hz');
                zlabel('Corr');
            end
            STATUS = 'COLD_ACQ';
            channel_spc.acq.ACQ_STATUS = 3;   
            %���¶�����
            freqBias = freqCorrect( channel_spc.acq.CM_corr(:,peak_code_phase), peak_freq_idx, l2c_acq_config.freqBin); %���ƾ�ȷ������
            channel_spc.LO2_fd_L2 = fd_search(peak_freq_idx) + freqBias;
            channel_spc.LO_Fcode_fd = channel_spc.LO2_fd_L2 / 1200;
            channel_spc.LO2_fd = channel_spc.LO2_fd_L2 / GSAR_CONSTANTS.STR_L2C.L2L1_FreqRatio;
            %������һ��������,��������20ms,���CL����ʱ��Ҫ���ж������Ƿ����
            skipNperCode = N_1ms * channel_spc.LO_Fcode_fd / GSAR_CONSTANTS.STR_L1CA.Fcode0;
            timeLen = peak_code_phase + channel_spc.acq.accum; %����ĺ�����
            skipNumOfSamples = round(skipNperCode*timeLen);
            channel_spc.Samp_Posi = channel_spc.Samp_Posi + peak_code_phase*N_1ms - skipNumOfSamples - channel_spc.acq.resiN;
            %��¼��ֵ����ΪCL�벶��ʱ�Ĳο�
            channel_spc.acq.CM_peak = peak_nc_corr;            
            fprintf('\t\t\tSucceed!Samp_pos: %d ; Doppler: %.2fHz Strength: %.4f \n', ...
                channel_spc.Samp_Posi, channel_spc.LO2_fd_L2, th);           
        else %����ʧ��
            %�˴��ɲ����������������ж����ǿɼ����������Σ�������ʱֻ����һ��
            STATUS = 'ACQ_FAIL';
            channel_spc.CH_STATUS = 'ACQ_FAIL';
            channel_spc.acq.ACQ_STATUS = 0;
            fprintf('\t\t\tFailed!Strength: %.4f \n',th);
        end
        
        channel_spc.acq.carriPhase_vt = [];
        channel_spc.acq.CM_corr = [];
        channel_spc.acq.CM_corrtmp = [];
        channel_spc.acq.accum = 0;
        channel_spc.acq.resiN = 0;
        channel_spc.acq.resiData = [];
        channel_spc.acq.processing = 0;
        return;
    end
    
    %�ж���������
    if (channel_spc.Samp_Posi + N_1ms > N) %�����ݲ��㣬�����»�  �����������ô��ں�
        channel_spc.acq.resiData = sis(channel_spc.Samp_Posi+1:N);
        channel_spc.acq.resiN = N - channel_spc.Samp_Posi;
        channel_spc.Samp_Posi = 0;
        return;
    end
    
end %EOF while(1)
    