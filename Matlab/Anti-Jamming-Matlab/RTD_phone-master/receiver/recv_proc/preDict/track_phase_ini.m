function [recv_channel]=track_phase_ini(recv_channel)

switch recv_channel.SYST
    case 'GPS_L1CA'
        TimeLen = 0 - recv_channel.CH_L1CA.Samp_Posi;
        % ֡��Ϣ�����У��
        [~, recv_channel.CH_L1CA] = hotInfoCheck(recv_channel.CH_L1CA, TimeLen, recv_channel.SYST,'NORM');               
        recv_channel.CH_L1CA.CN0_Estimator.muk_cnt = recv_channel.CH_L1CA.T1ms_N;
        recv_channel.CH_L1CA.Tcohn_cnt = mod(recv_channel.CH_L1CA.T1ms_N, recv_channel.CH_L1CA.Tcohn_N);
        %ע�⣺channel�������counter����Ҫͬ������
        recv_channel.CH_L1CA.Trk_Count = recv_channel.CH_L1CA.T1ms_N;
        recv_channel.ALL.acnt = floor(recv_channel.CH_L1CA.T1ms_N/recv_channel.CH_L1CA.Tcohn_N);
        recv_channel.CH_L1CA.Samp_Posi = 0;
        
    case 'BDS_B1I'
        TimeLen = 0 - recv_channel.CH_B1I.Samp_Posi;
        % ֡��Ϣ�����У��
        [~, recv_channel.CH_B1I] = hotInfoCheck(recv_channel.CH_B1I, TimeLen, recv_channel.SYST,'NORM');               
        recv_channel.CH_B1I.CN0_Estimator.muk_cnt = recv_channel.CH_B1I.T1ms_N;
        recv_channel.CH_B1I.Tcohn_cnt = mod(recv_channel.CH_B1I.T1ms_N, recv_channel.CH_B1I.Tcohn_N);
        %ע�⣺channel�������counter����Ҫͬ������
        recv_channel.CH_B1I.Trk_Count = recv_channel.CH_B1I.T1ms_N;
        recv_channel.ALL.acnt = floor(recv_channel.CH_B1I.T1ms_N/recv_channel.CH_B1I.Tcohn_N);
        recv_channel.CH_B1I.Samp_Posi = 0;
        
    case 'GPS_L1CA_L2C' %acq_l1ca_l2c_hot �Ȳ��ɹ������˴�
        recv_channel.DLL.SPACING = 0.5;
        recv_channel.DLL.SPACING_MP = 0.5;
        recv_channel.CH_L1CA_L2C.CN0_Estimator.CN0EstActive = 1;
        recv_channel.CH_L1CA_L2C.CN0_Estimator.muk_cnt = recv_channel.CH_L1CA_L2C.T1ms_N;
        recv_channel.CH_L1CA_L2C.Tcohn_cnt = mod(recv_channel.CH_L1CA_L2C.T1ms_N, recv_channel.CH_L1CA_L2C.Tcohn_N);
        recv_channel.CH_L1CA_L2C.Trk_Count = recv_channel.CH_L1CA_L2C.T1ms_N;
        %recv_channel.ALL.acnt = floor(recv_channel.CH_L1CA_L2C.T1ms_N/recv_channel.CH_L1CA_L2C.Tcohn_N);
end
        






% switch recv_channel.SYST
%     case 'GPS_L1CA'
%         Fcode = recv_channel.CH_L1CA.LO_Fcode0 + recv_channel.CH_L1CA.LO_Fcode_fd; % ʵ������
%         Fcarri = recv_channel.CH_L1CA.LO2_IF0 + recv_channel.CH_L1CA.LO2_fd; % ʵ������
%         codePhase = Fcode/GSAR_CONSTANTS.STR_RECV.fs;   % ÿ����������������λ�仯
%         carriPhase = Fcarri/GSAR_CONSTANTS.STR_RECV.fs;
%         codePhaseAll = recv_channel.CH_L1CA.Samp_Posi * codePhase; % 
%         carriPhaseAll = carriPhase * recv_channel.CH_L1CA.Samp_Posi;
%         phaseIndex = GSAR_CONSTANTS.STR_L1CA.ChipNum - mod(codePhaseAll,GSAR_CONSTANTS.STR_L1CA.ChipNum);
%         recv_channel.CH_L1CA.LO_CodPhs  = phaseIndex;
%         carriIndex = ceil(carriPhaseAll) - carriPhaseAll;
%         recv_channel.CH_L1CA.LO2_CarPhs  = carriIndex;
%         
%         T1msNum = floor((0-codePhaseAll)/GSAR_CONSTANTS.STR_L1CA.ChipNum); % Ϊ������������floor
%         T1msIndex = mod(recv_channel.CH_L1CA.T1ms_N + T1msNum, 20);
%         bitNum = floor((recv_channel.CH_L1CA.T1ms_N+T1msNum)/20);% ��ǰ��bit�������������ڱ���ͬ����T1msΪ0��       ע�⣺���ڽ��Ϊ������������floor
%         recv_channel.CH_L1CA.T1ms_N = T1msIndex;
%         recv_channel.CH_L1CA.CN0_Estimator.muk_cnt = T1msIndex;
%         recv_channel.CH_L1CA.Tcohn_cnt = mod(T1msIndex, recv_channel.CH_L1CA.Tcohn_N);
%         
%         
%                     
%         
%         
%        
%         
%         % ������������֡��������Ҫ��ǰ����
%         % 
%         bitIndex = mod(recv_channel.CH_L1CA.Bit_N+bitNum, 30); % bitNum���Ϊ����,������+
%         wordNum = floor((recv_channel.CH_L1CA.Bit_N+bitNum)/30); % ��ǰ��wordNum���㱣��һ��
%         recv_channel.CH_L1CA.Bit_N = bitIndex;  
%         
%         wordIndex = mod(recv_channel.CH_L1CA.Word_N+wordNum, 10);
%         subframeNum = floor((recv_channel.CH_L1CA.Word_N+wordNum)/10);
%         recv_channel.CH_L1CA.Word_N = wordIndex;
%         
%         subframeIndex = mod((recv_channel.CH_L1CA.SubFrame_N+subframeNum), 5);
%         recv_channel.CH_L1CA.SubFrame_N = subframeIndex;
%         % ����SOW��WNֵ
%         recv_channel.CH_L1CA.TOW_6SEC = mod((recv_channel.CH_L1CA.TOW_6SEC+subframeNum), 100800);
%         recv_channel.CH_L1CA.WN = recv_channel.CH_L1CA.WN + floor((recv_channel.CH_L1CA.TOW_6SEC + subframeNum)/100800);
%         %ע�⣺channel�������counter����Ҫͬ������
%         recv_channel.CH_L1CA.Trk_Count = recv_channel.CH_L1CA.T1ms_N;
%         recv_channel.ALL.acnt = floor(recv_channel.CH_L1CA.T1ms_N/recv_channel.CH_L1CA.Tcohn_N);
%         
%          recv_channel.CH_L1CA.Samp_Posi = 0;
%     case 'BDS_B1I'
%         Fcode = recv_channel.CH_B1I.LO_Fcode0 + recv_channel.CH_B1I.LO_Fcode_fd; % ʵ������
%         Fcarri = recv_channel.CH_B1I.LO2_IF0 + recv_channel.CH_B1I.LO2_fd; % ʵ������
%         codePhase = Fcode/GSAR_CONSTANTS.STR_RECV.fs;   % ÿ����������������λ�仯
%         carriPhase = Fcarri/GSAR_CONSTANTS.STR_RECV.fs;
%         codePhaseAll = recv_channel.CH_B1I.Samp_Posi * codePhase; % 
%         carriPhaseAll = carriPhase * recv_channel.CH_B1I.Samp_Posi;
%         if strcmp(recv_channel.CH_B1I.navType,'B1I_D1')
%             T1msIndex = floor(codePhaseAll/GSAR_CONSTANTS.STR_B1I.ChipNum);  % 
%             bitNum = floor((0-T1msIndex)/20);    % ��ǰ��bit��������       ע�⣺���ڽ��Ϊ������������floor
%             T1msIndex = 19 - mod(T1msIndex,20);
%              % ������������֡��������Ҫ��ǰ����
%             bitIndex = mod(recv_channel.CH_B1I.Bit_N+bitNum, 30); % bitNum���Ϊ����,������+
%             wordNum = floor((recv_channel.CH_B1I.Bit_N+bitNum)/30); % ��ǰ��wordNum���㱣��һ��
%             recv_channel.CH_B1I.Bit_N = bitIndex;
%             
%             wordIndex = mod(recv_channel.CH_B1I.Word_N+wordNum, 10);
%             subframeNum = floor((recv_channel.CH_B1I.Word_N+wordNum)/10);
%             recv_channel.CH_B1I.Word_N = wordIndex;
%             
%             subframeIndex = mod((recv_channel.CH_B1I.SubFrame_N+subframeNum), 5);
%             frameNum = floor((recv_channel.CH_B1I.SubFrame_N+subframeNum)/5);
%             recv_channel.CH_B1I.SubFrame_N = subframeIndex;
%             
%             frameIndex = mod((recv_channel.CH_B1I.Frame_N+frameNum), 24);   % D1��24����֡
%             recv_channel.CH_B1I.Frame_N = frameIndex;
%             % ����SOW��WNֵ
%             recv_channel.CH_B1I.SOW = mod((recv_channel.CH_B1I.SOW+subframeNum*6), 604800);
%             recv_channel.CH_B1I.WN = recv_channel.CH_B1I.WN + floor((recv_channel.CH_B1I.SOW + subframeNum*6)/604800);
%         else
%             T1msIndex = floor(codePhaseAll/GSAR_CONSTANTS.STR_B1I.ChipNum);  % 
%             bitNum = floor((0-T1msIndex)/2);    % ��ǰ��bit��������       ע�⣺���ڽ��Ϊ������������floor
%             T1msIndex = 1 - mod(T1msIndex,2);
%              % ������������֡��������Ҫ��ǰ����
%             bitIndex = mod(recv_channel.CH_B1I.Bit_N+bitNum, 30); % bitNum���Ϊ����,������+
%             wordNum = floor((recv_channel.CH_B1I.Bit_N+bitNum)/30); % ��ǰ��wordNum���㱣��һ��
%             recv_channel.CH_B1I.Bit_N = bitIndex;
%             
%             wordIndex = mod(recv_channel.CH_B1I.Word_N+wordNum, 10);
%             subframeNum = floor((recv_channel.CH_B1I.Word_N+wordNum)/10);
%             recv_channel.CH_B1I.Word_N = wordIndex;
%             
%             subframeIndex = mod((recv_channel.CH_B1I.SubFrame_N+subframeNum), 5);
%             frameNum = floor((recv_channel.CH_B1I.SubFrame_N+subframeNum)/5);
%             recv_channel.CH_B1I.SubFrame_N = subframeIndex;
%             
%             frameIndex = mod((recv_channel.CH_B1I.Frame_N+frameNum), 120);   % D2��120����֡
%             recv_channel.CH_B1I.Frame_N = frameIndex;
%             % ����SOW��WNֵ
%             recv_channel.CH_B1I.SOW = mod((recv_channel.CH_B1I.SOW+frameNum*3), 604800);
%             recv_channel.CH_B1I.WN = recv_channel.CH_B1I.WN + floor((recv_channel.CH_B1I.SOW + frameNum*3)/604800);
%         end
%         phaseIndex = GSAR_CONSTANTS.STR_B1I.ChipNum - mod(codePhaseAll,GSAR_CONSTANTS.STR_B1I.ChipNum);
%         carriIndex = ceil(carriPhaseAll) - carriPhaseAll;
%         recv_channel.CH_B1I.T1ms_N = T1msIndex;
%         recv_channel.CH_B1I.CN0_Estimator.muk_cnt = T1msIndex;
%         recv_channel.CH_B1I.Tcohn_cnt = mod(T1msIndex, recv_channel.CH_B1I.Tcohn_N);
%         recv_channel.CH_B1I.LO_CodPhs  = phaseIndex;
%         recv_channel.CH_B1I.Samp_Posi = 0;
%         recv_channel.CH_B1I.LO2_CarPhs  = carriIndex;
%         %ע�⣺channel�������counter����Ҫͬ������
%         recv_channel.CH_B1I.Trk_Count = recv_channel.CH_B1I.T1ms_N;
%         recv_channel.ALL.acnt = floor(recv_channel.CH_B1I.T1ms_N/recv_channel.CH_B1I.Tcohn_N);
% end