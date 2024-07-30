function [channels, pvtCalculator] = sowCheck(channels, recvConfig,pvtCalculator, timer, actvPvtChannels)
% �����Լ���ͻ�����

for i = 1 : actvPvtChannels.actChnsNum_GPS
    num = actvPvtChannels.GPS(1,i); % ͨ����
    SOW_1 = channels(num).CH_L1CA(1).TOW_6SEC; % Ԥ������ֵ
    SOW_2 = mod(channels(num).CH_L1CA(1).SOW_check+1, 100800); % ÿ�ν��ֵ
    if timer.timeCheck == 1
        switch timer.timeType
            case 'GPST'
                SOW_local = timer.recvSOW;
            case 'BDST'
                SOW_local = timer.recvSOW + timer.BDT2GPST(1);
        end
        SOW_3 = SOW_local - channels(num).CH_L1CA(1).Word_N * 6/10 - ...
        channels(num).CH_L1CA(1).Bit_N * 0.6/30 - channels(num).CH_L1CA(1).T1ms_N * 0.001 - ...
        channels(num).CH_L1CA(1).LO_CodPhs/channels(num).CH_L1CA(1).LO_Fcode0 - 0.07;
        SOW_3 = round(SOW_3 / 6);
    end
    if (SOW_1 ~= SOW_2)
        if channels(num).CH_L1CA(1).bitDetect(3) == 1   % һ����һ�ν������ϴν���һ�£�����Ϊ��ȷ
            if (channels(num).CH_L1CA(1).invalidNum > recvConfig.raimFailure)
                channels(num).CH_L1CA(1).TOW_6SEC = SOW_2;
            end
        else
            channels(num).CH_L1CA(1).TOW_6SEC = SOW_2;
        end
        if timer.timeCheck == 1 
            channels(num).CH_L1CA(1).TOW_6SEC = SOW_3;
        end      
    end
end

for i = 1 : actvPvtChannels.actChnsNum_BDS
    num = actvPvtChannels.BDS(1,i); % ͨ����
    SOW_1 = channels(num).CH_B1I(1).SOW; % Ԥ������ֵ
    switch channels(num).CH_B1I(1).navType
        case 'B1I_D2'
            if channels(num).CH_B1I(1).SubFrame_N == 0 % �˴�Ĭ����֡���ǶԵģ��������
                SOW_2 = mod(channels(num).CH_B1I(1).SOW_check+3, 604800); % ÿ�ν��ֵ
            else
                SOW_2 = channels(num).CH_B1I(1).SOW_check;
            end
        case 'B1I_D1'
            SOW_2 = mod(channels(num).CH_B1I(1).SOW_check+6, 604800); % ÿ�ν��ֵ
    end
    if timer.timeCheck == 1
        switch timer.timeType
            case 'GPST'
                SOW_local = timer.recvSOW - timer.BDT2GPST(1);
            case 'BDST'
                SOW_local = timer.recvSOW;
        end
        switch channels(num).CH_B1I(1).navType
            case 'B1I_D2' 
                SOW_3 = SOW_local - channels(num).CH_B1I(1).SubFrame_N * 3/5 - ...
                    channels(num).CH_B1I(1).Word_N * 0.6/10 - ...
                    channels(num).CH_B1I(1).Bit_N * 0.06/30 - ...
                    channels(num).CH_B1I(1).T1ms_N * 0.001 - ...
                    channels(num).CH_B1I(1).LO_CodPhs/channels(num).CH_B1I(1).LO_Fcode0 - 0.07;
                SOW_3 = round(SOW_3/3) * 3;
            case 'B1I_D1'
                SOW_3 = SOW_local - channels(num).CH_B1I(1).Word_N * 6/10 - ...
                    channels(num).CH_B1I(1).Bit_N * 0.6/30 - ...
                    channels(num).CH_B1I(1).T1ms_N * 0.001 - ...
                    channels(num).CH_B1I(1).LO_CodPhs/channels(num).CH_B1I(1).LO_Fcode0 - 0.07;
                SOW_3 = round(SOW_3/6) * 6;
        end
    end % EOF : if timer.timeCheck == 1
    if (SOW_1 ~= SOW_2)
        if channels(num).CH_B1I(1).bitDetect(3) == 1
            if (channels(num).CH_B1I(1).invalidNum > recvConfig.raimFailure)
                channels(num).CH_B1I(1).SOW = SOW_2;
            end
        else
            channels(num).CH_B1I(1).SOW = SOW_2;
        end
        if timer.timeCheck == 1 
            channels(num).CH_B1I(1).SOW = SOW_3;
        end      
    end 
end

















% trustLevel_GPS_SOW = zeros(1,recvConfig.numberOfChannels(1).channelNumAll);
% GPS_SOW = zeros(1,recvConfig.numberOfChannels(1).channelNumAll);


% �������������������� ��У�� ����������������������������%
% for n = 1 : recvConfig.numberOfChannels(1).channelNumAll
%     if strcmp(channels(n).STATUS, 'SUBFRAME_SYNCED')
%         switch channels(n).SYST
%             case 'GPS_L1CA'
%                 prn = channels(n).CH_L1CA(1).PRNID;
% %                 GPS_SOW(prn) = channels(n).CH_L1CA(1).TOW_6SEC + channels(n).CH_L1CA(1).SubFrame_N/10;
%                 % ����SOWֵ
%                 trustLevel_GPS_SOW(prn) = 1; % 
%                 if pvtCalculator.GPS.SOW(1,prn) == -1  % �״ν��յ�SOW
%                     pvtCalculator.GPS.SOW(1,prn) = channels(n).CH_L1CA(1).TOW_6SEC;
%                 else 
%                     if pvtCalculator.posiCheck==1 && any(pvtCalculator.pvtSats(2).pvtS_prnList==prn)   % ��ʷSOW��ȷ
%                         if channels(n).CH_L1CA(1).bitDetect(1) == 1     % SOW �и���
%                             channels(n).CH_L1CA(1).TOW_6SEC = mod(pvtCalculator.GPS.SOW(1,prn)+1, 100800);
%                             pvtCalculator.GPS.SOW(1,prn) = channels(n).CH_L1CA(1).TOW_6SEC; 
%                         elseif channels(n).CH_L1CA(1).bitDetect(1) == 0  % SOW�޸���
%                             channels(n).CH_L1CA(1).TOW_6SEC = pvtCalculator.GPS.SOW(1,prn);
%                         end
%                         if channels(n).CH_L1CA(1).bitDetect(3) == 1
%                             trustLevel_GPS_SOW(prn) = 3;
%                         else
%                             trustLevel_GPS_SOW(prn) = 2;
%                         end  
%                     else
%                         pvtCalculator.GPS.SOW(1,prn) = channels(n).CH_L1CA(1).TOW_6SEC;
%                     end
%                 end % EOF :  if pvtCalculator.GPS.SOW(1,prn) == -1  % �״ν��յ�SOW
%                 
%                 % ����subFrame    
%                 if pvtCalculator.GPS.subFrameID(1,prn) == -1  % �״ν��յ�subframe
%                     pvtCalculator.GPS.subFrameID(1,prn) = channels(n).CH_L1CA(1).SubFrame_N;
%                 else 
%                     if pvtCalculator.posiCheck==1 && any(pvtCalculator.pvtSats(2).pvtS_prnList==prn)   % ��ʷsubframe��ȷ
%                         if channels(n).CH_L1CA(1).bitDetect(2) == 1     % subframe �и���
%                             channels(n).CH_L1CA(1).SubFrame_N = mod(pvtCalculator.GPS.subFrameID(1,prn)+1, 5);
%                             pvtCalculator.GPS.subFrameID(1,prn) = channels(n).CH_L1CA(1).SubFrame_N;
%                         elseif channels(n).CH_L1CA(1).bitDetect(2) == 0  % subframe�޸���
%                             channels(n).CH_L1CA(1).SubFrame_N = pvtCalculator.GPS.subFrameID(1,prn);
%                         end
%                     else
%                         pvtCalculator.GPS.subFrameID(1,prn) = channels(n).CH_L1CA(1).SubFrame_N;
%                     end
%                 end
%                 % ��ʼ�����±�־λ
%                 channels(n).CH_L1CA(1).bitDetect(1:2) = 0;
%                 
%             case 'BDS_B1I'
%                 prn = channels(n).CH_B1I(1).PRNID;
%                 % ����SOWֵ
%                 if pvtCalculator.BDS.SOW(1,prn) == -1  % �״ν��յ�SOW
%                     pvtCalculator.BDS.SOW(1,prn) = channels(n).CH_B1I(1).SOW;
%                 else 
%                     if pvtCalculator.posiCheck==1 && any(pvtCalculator.pvtSats(1).pvtS_prnList==prn)   % ��ʷSOW��ȷ
%                         if channels(n).CH_B1I(1).bitDetect(1) == 1     % SOW �и���
%                             if strcmp(channels(n).CH_B1I(1).navType, 'B1I_D1')
%                                 channels(n).CH_B1I(1).SOW = mod(pvtCalculator.BDS.SOW(1,prn)+6, 604800);
%                             else
%                                 channels(n).CH_B1I(1).SOW = mod(pvtCalculator.BDS.SOW(1,prn)+3, 604800);
%                             end
%                             pvtCalculator.BDS.SOW(1,prn) = channels(n).CH_B1I(1).SOW; 
%                         elseif channels(n).CH_B1I(1).bitDetect(1) == 0  % SOW�޸���
%                             channels(n).CH_B1I(1).SOW = pvtCalculator.BDS.SOW(1,prn);
%                         end
%                     else
%                         pvtCalculator.BDS.SOW(1,prn) = channels(n).CH_B1I(1).SOW;
%                     end
%                 end % EOF :  if pvtCalculator.GPS.SOW(1,prn) == -1  % �״ν��յ�SOW
%                 
%                 % ����subFrame    
%                 if pvtCalculator.BDS.subFrameID(1,prn) == -1  % �״ν��յ�subframe
%                     pvtCalculator.BDS.subFrameID(1,prn) = channels(n).CH_B1I(1).SubFrame_N;
%                 else 
%                     if pvtCalculator.posiCheck==1 && any(pvtCalculator.pvtSats(1).pvtS_prnList==prn)   % ��ʷsubframe��ȷ
%                         if channels(n).CH_B1I(1).bitDetect(2) == 1     % subframe �и���
%                             channels(n).CH_B1I(1).SubFrame_N = mod(pvtCalculator.BDS.subFrameID(1,prn)+1, 5);
%                             pvtCalculator.BDS.subFrameID(1,prn) = channels(n).CH_B1I(1).SubFrame_N;
%                         elseif channels(n).CH_B1I(1).bitDetect(2) == 0  % subframe�޸���
%                             channels(n).CH_B1I(1).SubFrame_N = pvtCalculator.BDS.subFrameID(1,prn);
%                         end
%                     else
%                         pvtCalculator.BDS.subFrameID(1,prn) = channels(n).CH_B1I(1).SubFrame_N;
%                     end
%                 end
%                 % ��ʼ�����±�־λ
%                 channels(n).CH_B1I(1).bitDetect(1:2) = 0;
%                 
%                 
%         end % EOF: switch SYST
%     end % EOF: if strcmp(channels(n).STATUS, 'SUBFRAME_SYNCED') 
% end % EOF:  for n = 1 : channelNumAll
% 
% % �������������������� ��У�� ����������������������������%
% if any(trustLevel_GPS_SOW)
%     trust3 = find(trustLevel_GPS_SOW == 3);
%     trust2 = find(trustLevel_GPS_SOW == 2);
%     trust1 = find(trustLevel_GPS_SOW == 1); 
%     if ~isempty(trust3)
%         trueSOW = GPS_SOW(trust3(1));
%     elseif ~isempty(trust2)
%         trueSOW = GPS_SOW(trust2(1));
%     else
%         trueSOW = median(GPS_SOW(trust1));
%     end
%     SOWdiff = GPS_SOW(find(trustLevel_GPS_SOW~=0)) - trueSOW;
%     
    
    
end
        
                