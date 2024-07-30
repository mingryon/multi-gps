function [channel_spc, STATUS, CL_time] = acq_l2cl_aid(channel_spc, config, sis, N, ~, CL_time)

%bpSampling_oddFold��δʹ��
%��CL�����У�ֻ��һ��Ƶ�ʣ���75��λ�õĻ��ֽ�����ͬ���ģ����������ԱȽϷ���ش���������ֱ��������λ����ʱ�����˶����յ��ۻ�ЧӦ��
%�������Samp_Posi��У�����ڻ��ֽ��������,���ڲ����ڱ������䣬���û�л�����ʧ��
%��CM�벻ͬ��CL�벶��ʱ��Ҫ�õ�ʱ��1500ms�ı��ز����룬��MATLAB�������double�����ڴ����Ľϴ���˲���ÿ���뼴ʱ���ɵķ�ʽ��
%���ַ�ʽ�ڻ���ʱ��Ϊ1*20ms������²����������ļ�����������ʹ���Ǽ丨��ʱ��������㡣

global GSAR_CONSTANTS;

%�趨Ĭ�Ϸ���ֵ
STATUS = channel_spc.CH_STATUS; 
 
%����CM���������˶��������㣬��Ҫ��������Ƿ����
if (channel_spc.Samp_Posi >= N)
    channel_spc.Samp_Posi = channel_spc.Samp_Posi - N;
    return;
end

%�����ʣ�����ݣ��Ⱥϲ�
if (channel_spc.acq.resiN > 0 )
    sis = [channel_spc.acq.resiData sis];  
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

if (channel_spc.acq.processing ~= 1) %��һ�ν���Ҫ��ʼ��
    if (CL_time>=0)  %����ͨ�������CL�룬��ô������Χ������С��
        %���㵱ǰ�������Ӧ��CLʱ��
        CL_time_prompt = mod( CL_time+(channel_spc.Samp_Posi-channel_spc.acq.resiN)/GSAR_CONSTANTS.STR_RECV.fs, 1.5);
        CL_phase = floor(50*CL_time_prompt)+1; %CL��λ1~75
        if (CL_phase==75)
            channel_spc.acq.CL_search = [1,75];
        else
            channel_spc.acq.CL_search = [CL_phase,CL_phase+1];
        end      
    else
        channel_spc.acq.CL_search = 1:75;
    end
        
    channel_spc.acq.accum = 0; %������ۼӴ���
    channel_spc.acq.CL_corr = zeros(1,75); %�ܻ��ֽ��
    channel_spc.acq.CL_corrtmp  = zeros(1,75); %ÿ����ɻ��ֽ��
    channel_spc.acq.carriPhase = 0; %�����ز���λ��Ϣ,0~1��һ��  
    
    channel_spc.acq.processing = 1;
end

l2c_acq_config = config.recvConfig.configPage.acqConfig.GPS_L2C_aid;
fd0 = channel_spc.LO2_fd_L2; %������Ƶ��
IF_search = GSAR_CONSTANTS.STR_RECV.IF_L2C + fd0; %ʵ������Ƶ��λ��
Tc = round(l2c_acq_config.tcoh*1000); %��ɻ��ֺ�����
Nc = l2c_acq_config.ncoh; %�ۼӴ���
CL_code = GSAR_CONSTANTS.PRN_CODE.RZCL_code(channel_spc.PRNID,:); %ȡ����Ӧ��Ƶ�� 0CL
t_1ms = (0:N_1ms-1)/GSAR_CONSTANTS.STR_RECV.fs;  %1msʱ���

fprintf('\t\tAcquire GPS L2CL PRN%2.2d:  Coherent time: %d*%.3fs ; FreqCenter: %.2fHz\n', ...
    channel_spc.PRNID, Nc, l2c_acq_config.tcoh, fd0);

%1ms��ѭ��
while 1
    sis_seg = sis( channel_spc.Samp_Posi + (1:N_1ms) );    
    sis_seg_swpt = sis_seg.*exp( -1j*2*pi*( IF_search.*t_1ms+channel_spc.acq.carriPhase ) ); %�ز�����
    channel_spc.acq.carriPhase = mod(channel_spc.acq.carriPhase+ IF_search*0.001,1); %��λ�ƽ�,ÿ��ģ1�ɼ�С�������
    
    %���������
    for i = channel_spc.acq.CL_search
        codePhase = mod( floor( (i-1)*20460+channel_spc.acq.accum*(1023+fd0/1200000)+t_1ms*(1.023e6+fd0/1200) ), 1534500)+1;
        channel_spc.acq.CL_corrtmp(i) = channel_spc.acq.CL_corrtmp(i) + sum(sis_seg_swpt.*CL_code(codePhase)); 
    end
    
    channel_spc.Samp_Posi = channel_spc.Samp_Posi + N_1ms;
    channel_spc.acq.accum = channel_spc.acq.accum + 1;
    
    %�ﵽ��ɻ���ʱ��
    if (channel_spc.acq.accum>=Tc) 
        channel_spc.acq.CL_corr = channel_spc.acq.CL_corr + abs(channel_spc.acq.CL_corrtmp);
        channel_spc.acq.CL_corrtmp = zeros(1,75);
    end
    
    %�ﵽ�趨���ۼӴ��������ֽ���
    if (channel_spc.acq.accum>=Tc*Nc)
        [peak_nc_corr, peak_code_phase] = max(channel_spc.acq.CL_corr);
        th = peak_nc_corr / channel_spc.acq.CM_peak;
        if (th>l2c_acq_config.thre_CL) %����ɹ�  
            if config.logConfig.isAcqPlotMesh
                Title = ['Acq GPS_L2CL PRN=',num2str(channel_spc.PRNID)];
                figure('Name',Title,'NumberTitle','off');
                plot(channel_spc.acq.CL_corr);
                xlabel('Code position');
                ylabel('Corr');
            end
            STATUS = 'PULLIN';
            channel_spc.STATUS = 'PULLIN';
            channel_spc.acq.ACQ_STATUS = 4;   %4��ʱ��Ҫ������ٳ�ʼ��
            %Samp_Posi����
            skipNperCode = N_1ms * channel_spc.LO_Fcode_fd / GSAR_CONSTANTS.STR_L1CA.Fcode0;
            skipNumOfSamples = round(skipNperCode*Tc*Nc);
            channel_spc.Samp_Posi = channel_spc.Samp_Posi - skipNumOfSamples - channel_spc.acq.resiN;
            %����Samp_Posi=0λ�õ�CLʱ��
            CL_time = mod( (peak_code_phase-1)*0.02 + Tc*Nc*0.001 - channel_spc.Samp_Posi/GSAR_CONSTANTS.STR_RECV.fs, 1.5);
            channel_spc.CL_time = CL_time;
            
            fprintf('\t\t\tSucceed!Samp_pos: %d ; CM_in_CL: %d corrPeakRatio: %.4f \n', ...
                channel_spc.Samp_Posi, peak_code_phase, th);           
        else %����ʧ��
            %�˴��ɲ����������������ж����ǿɼ����������Σ�������ʱֻ����һ��
            STATUS = 'ACQ_FAIL';
            channel_spc.CH_STATUS = 'ACQ_FAIL';
            channel_spc.acq.ACQ_STATUS = 0;
            fprintf('\t\t\tFailed!corrPeakRatio: %.4f \n',th);
        end
        
        channel_spc.acq.CL_corr = [];
        channel_spc.acq.CL_corrtmp = [];
        channel_spc.acq.accum = 0;
        channel_spc.acq.resiN = 0;
        channel_spc.acq.resiData = [];
        channel_spc.acq.carriPhase = 0;
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
    
end
