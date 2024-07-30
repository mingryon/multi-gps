function [verify, CH_PARA] = bitInfoCheck(CH_PARA, SYST)
global GSAR_CONSTANTS;
% ��������ȷ����Ϊ1��
verify = 0;

lockDect = CH_PARA.lockDect;
frameDect = struct( ...
    'WN',                    0,                 ...Week number counter
    'SOW',                   0,                 ...Second number counter of current subframe beginning in a week
    'Frame_N',               0,                 ...Frame counter, 0~23 for D1, 0~119 for D2
    'SubFrame_N',            0,                 ...Frame counter, 0~4
    'Word_N',                0,                 ...word counter,0~9
    'Bit_N',                 0,                 ...navigation bit counter in a word,0~29       
    'T1ms_N',                0,                 ...PRN period counter in a bit, 0~19 for D1, 0~1 for D2
    'codePhase',             0,                 ...
    'carriPhase',            0,                 ...
    'carriDopp',             0,                 ...
    'codeDopp',              0                  ...
    );
elapseTime = CH_PARA.bitSync.TimeLen / GSAR_CONSTANTS.STR_RECV.fs; % ����bitͬ����ʹ�õ�ʱ��
frameDect.codeDopp = CH_PARA.LO_Fcode_fd;
frameDect.carriDopp = CH_PARA.LO2_fd;

switch SYST
    case 'BDS_B1I'
        % ��������Ϣ����
        carriPhaseAll = (frameDect.carriDopp+GSAR_CONSTANTS.STR_RECV.IF_B1I)*elapseTime;
        codePhaseAll = (frameDect.codeDopp+GSAR_CONSTANTS.STR_B1I.Fcode0)*elapseTime; 
        frameDect.codePhase = mod((lockDect.codePhase + codePhaseAll), GSAR_CONSTANTS.STR_B1I.ChipNum);
        frameDect.carriPhase = lockDect.carriPhase + carriPhaseAll - floor(lockDect.carriPhase + carriPhaseAll);
        % ��������ȷ����codePhaseӦ����0�������������Բ���round
        T1ms_N_Num = round((lockDect.codePhase + codePhaseAll)/GSAR_CONSTANTS.STR_B1I.ChipNum); % T1ms_N�ĸ���
        if prn <= 5
            frameDect.T1ms_N = mod(lockDect.T1ms_N+T1ms_N_Num, 2);
            bit_Num = floor((lockDect.T1ms_N+T1ms_N_Num)/2); % bit�ĸ���
        else
            frameDect.T1ms_N = mod(lockDect.T1ms_N+T1ms_N_Num, 20);
            % ��������ȷӦ��Ϊ����������round�������ݴ���
            bit_Num = round((lockDect.T1ms_N+T1ms_N_Num)/20);
        end
        frameDect.Bit_N = mod((lockDect.Bit_N+bit_Num), 30);
        word_Num = floor((lockDect.Bit_N+bit_Num)/30);% word�ĸ���
        frameDect.Word_N = mod((lockDect.Word_N+word_Num), 10);
        SubFrame_N_Num = floor((lockDect.Word_N+word_Num)/10);
        frameDect.SubFrame_N_Num = mod((lockDect.SubFrame_N+SubFrame_N_Num), 5);
        Frame_N_Num = floor((lockDect.SubFrame_N+SubFrame_N_Num)/5);
        if prn <= 5
            frameDect.Frame_N = mod((lockDect.Frame_N+Frame_N_Num), 120);  % D2��120����֡
            frameDect.SOW = mod((lockDect.SOW + Frame_N_Num*3), 604800);    % 3s per frame in D2
            frameDect.WN = lockDect.WN + floor((lockDect.SOW + Frame_N_Num*3)/604800);
        else
            frameDect.Frame_N = mod((lockDect.Frame_N+Frame_N_Num), 24);   % D1��24����֡
            frameDect.SOW = mod((lockDect.SOW + SubFrame_N_Num*6), 604800);    % 6s per subframe in D1
            frameDect.WN = lockDect.WN + floor((lockDect.SOW + SubFrame_N_Num*6)/604800);
        end
        % �ж�����λ��������ʵ�ʽ���Ƿ�һ�£�ͨ������λԤ����֤��
        if frameDect.T1ms_N == 0
            verify = 1;
        end
        % ������ͨ��������ֵ
        CH_PARA.WN = frameDect.WN;
        CH_PARA.SOW = frameDect.SOW;
        CH_PARA.Frame_N = frameDect.Frame_N;
        CH_PARA.SubFrame_N = frameDect.SubFrame_N;
        CH_PARA.Word_N = frameDect.Word_N;
        CH_PARA.Bit_N = frameDect.Bit_N;
%         CH_PARA.T1ms_N = frameDect.T1ms_N;
        % ����lockDect�и��������ֵ
        CH_PARA.lockDect.WN = CH_PARA.WN;
        CH_PARA.lockDect.SOW = CH_PARA.SOW;
        CH_PARA.lockDect.Frame_N = CH_PARA.Frame_N;
        CH_PARA.lockDect.SubFrame_N = CH_PARA.SubFrame_N;
        CH_PARA.lockDect.Word_N = CH_PARA.Word_N;
        CH_PARA.lockDect.Bit_N = CH_PARA.Bit_N;
        CH_PARA.lockDect.T1ms_N = CH_PARA.T1ms_N;
        CH_PARA.lockDect.carriDopp = CH_PARA.LO2_fd;
        CH_PARA.lockDect.carriPhase = CH_PARA.LO2_CarPhs;
        CH_PARA.lockDect.codeDopp = CH_PARA.LO_Fcode_fd;
        CH_PARA.lockDect.codePhase = CH_PARA.LO_CodPhs;
        
    case 'GPS_L1CA'
        carriPhaseAll = (frameDect.carriDopp+GSAR_CONSTANTS.STR_RECV.IF_B1I)*elapseTime;
        codePhaseAll = (frameDect.codeDopp+GSAR_CONSTANTS.STR_B1I.Fcode0)*elapseTime; 
        frameDect.codePhase = mod((lockDect.codePhase + codePhaseAll), GSAR_CONSTANTS.STR_B1I.ChipNum);
        frameDect.carriPhase = lockDect.carriPhase + carriPhaseAll - floor(lockDect.carriPhase + carriPhaseAll);
        % ��������ȷ����codePhaseӦ����0�������������Բ���round
        T1ms_N_Num = round((lockDect.codePhase + codePhaseAll)/GSAR_CONSTANTS.STR_B1I.ChipNum);
        frameDect.T1ms_N = mod(lockDect.T1ms_N+T1ms_N_Num, 20);
        % ��������ȷӦ��Ϊ����������round�������ݴ���
        bit_Num = round((lockDect.T1ms_N+T1ms_N_Num)/20);
        frameDect.Bit_N = mod((lockDect.Bit_N+bit_Num), 30);
        word_Num = floor((lockDect.Bit_N+bit_Num)/30);
        frameDect.Word_N = mod((lockDect.Word_N+word_Num), 10);
        SubFrame_N_Num = floor((lockDect.Word_N+word_Num)/10);
        frameDect.SubFrame_N_Num = mod((lockDect.SubFrame_N+SubFrame_N_Num), 5);
        Frame_N_Num = floor((lockDect.SubFrame_N+SubFrame_N_Num)/5);
        frameDect.Frame_N = lockDect.Frame_N+Frame_N_Num;
        frameDect.SOW = mod((lockDect.SOW + SubFrame_N_Num), 100800);    % GPS��SOW����ÿ6s��1
        frameDect.WN = lockDect.WN + floor((lockDect.SOW + SubFrame_N_Num)/100800);
        % �ж�����λ��������ʵ�ʽ���Ƿ�һ��
        if frameDect.T1ms_N == 0
            verify = 1;
        end
        % ������ͨ��������ֵ
        CH_PARA.WN = frameDect.WN;
        CH_PARA.TOW_6SEC = frameDect.SOW;
        CH_PARA.SubFrame_N = frameDect.SubFrame_N;
        CH_PARA.Word_N = frameDect.Word_N;
        CH_PARA.Bit_N = frameDect.Bit_N;
%         CH_PARA.T1ms_N = frameDect.T1ms_N;
        % ����lockDect�и��������ֵ
        CH_PARA.lockDect.WN = CH_PARA.WN;
        CH_PARA.lockDect.TOW_6SEC = CH_PARA.TOW_6SEC;
        CH_PARA.lockDect.SubFrame_N = CH_PARA.SubFrame_N;
        CH_PARA.lockDect.Word_N = CH_PARA.Word_N;
        CH_PARA.lockDect.Bit_N = CH_PARA.Bit_N;
        CH_PARA.lockDect.T1ms_N = CH_PARA.T1ms_N;
        CH_PARA.lockDect.carriDopp = CH_PARA.LO2_fd;
        CH_PARA.lockDect.carriPhase = CH_PARA.LO2_CarPhs;
        CH_PARA.lockDect.codeDopp = CH_PARA.LO_Fcode_fd;
        CH_PARA.lockDect.codePhase = CH_PARA.LO_CodPhs;
        
end % EOF��switch SYST

end % EOF��function




