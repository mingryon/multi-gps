function receiver = channel_Updating(receiver, N)

pvtCalculator = receiver.pvtCalculator;  
channel = receiver.channels;
if receiver.pvtCalculator.dataNum <= 0
    %������������������������GPS��������������������-%
    for i = 1 : receiver.actvPvtChannels.actChnsNum_GPS
        num = receiver.actvPvtChannels.GPS(1,i); % ͨ����
        prn = receiver.actvPvtChannels.GPS(2,i);
        switch pvtCalculator.posiCheck
            case 1
                if any(pvtCalculator.pvtSats(2).pvtS_prnList==prn)
                    channel(num).CH_L1CA(1).invalidNum = 0; % ��λ�ɹ�
                else
                    if channel(num).CH_L1CA(1).invalidNum < 0
                        channel(num).CH_L1CA(1).invalidNum = channel(num).CH_L1CA(1).invalidNum - 1; % �״ζ�λ��ʧЧ�����1
                    else
                        channel(num).CH_L1CA(1).invalidNum = channel(num).CH_L1CA(1).invalidNum + 1; % �ɹ���λ��ʧЧ�����1
                    end
                end
        end
        if abs(channel(num).CH_L1CA(1).invalidNum) > 2 * receiver.config.recvConfig.raimFailure
            channel(num).STATUS = 'POSI_FAIL';
        end
        
    end
    %������������������������BDS��������������������-%
    for i = 1 : receiver.actvPvtChannels.actChnsNum_BDS
        num = receiver.actvPvtChannels.BDS(1,i);
        prn = receiver.actvPvtChannels.BDS(2,i);
        switch pvtCalculator.posiCheck
            case 1
                if any(pvtCalculator.pvtSats(1).pvtS_prnList==prn)
                    channel(num).CH_B1I(1).invalidNum = 0; % ��λ�ɹ�
                else
                    if channel(num).CH_B1I(1).invalidNum < 0
                        channel(num).CH_B1I(1).invalidNum = channel(num).CH_B1I(1).invalidNum - 1; % �״ζ�λ��ʧЧ�����1
                    else
                        channel(num).CH_B1I(1).invalidNum = channel(num).CH_B1I(1).invalidNum + 1; % �ɹ���λ��ʧЧ�����1
                    end
                end
        end 
        if abs(channel(num).CH_B1I(1).invalidNum) > 2 * receiver.config.recvConfig.raimFailure
            channel(num).STATUS = 'POSI_FAIL';
        end
    end
end % EOF ��if receiver.pvtCalculator.dataNum <= 0

receiver.channels = channel;