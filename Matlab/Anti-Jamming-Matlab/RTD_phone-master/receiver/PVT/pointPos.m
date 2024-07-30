%% start PVT
% initial
function [recv_time, ephemeris, pvtCalculator, config] = pointPos(SYST,channels, config, recv_time, ephemeris, pvtCalculator, actvPvtChannels)
%% ��ʼ��
svnum.BDS = 0;% this flag is to find whether avaliable satellite is above 4
svnum.GPS = 0;
activeChannel.GPS = [];% avaliable channels
activeChannel.BDS = [];
posiChannel.GPS = [];   % raim�㷨���˺���ŵ�
posiChannel.BDS = [];
checkNGEO = 0;%%���NGEO����
inteDoppler.BDS = zeros(1,32);%���ֶ�����ֵ
inteDoppler.GPS = zeros(1,32);
dopplerfre.BDS = zeros(1,32);%������Ƶ��
dopplerfre.GPS = zeros(1,32);
CNR.BDS = zeros(1,32);  %��������
CNR.GPS = zeros(1,32);
SNR.BDS = zeros(1,32);  %��������
SNR.GPS = zeros(1,32);
carrierVar.BDS = zeros(1, 32);  % ����ز�������
carrierVar.GPS = zeros(1, 32);
EphAll.BDS = [];
EphAll.GPS = [];
rawP.GPS = [];
rawP.BDS = [];
satClkCorr.BDS = [];
satClkCorr.GPS = [];
satPositions.BDS = [];
satPositions.GPS = [];
raimG = []; % ״̬����
raimB = [];
prError = [];
raimFlag = 0;   % ���ֵΪ1����raimУ��ͨ��

if pvtCalculator.positionValid ==-1
    posiLast = [];
    transmitimeLast = [];
else
    posiLast = pvtCalculator.posiLast;
    transmitimeLast = pvtCalculator.timeLast;
end


%% start PVT
for n = 1 : config.recvConfig.numberOfChannels(1).channelNumAll
    switch channels(n).SYST
        case 'BDS_B1I'
            prnNum = channels(n).CH_B1I(1).PRNID;
%             if  ~isnan(prnNum) && (ephemeris(1).para(prnNum).ephReady==1 || ephemeris(1).para(prnNum).updateReady == 1) ...
%                     && ephemeris(1).para(prnNum).ephUpdate.health==0 && strcmp(channels(n).CH_B1I(1).CH_STATUS, 'SUBFRAME_SYNCED')
%                 svnum.BDS = svnum.BDS + 1;
%                 activeChannel.BDS(1,svnum.BDS) = n;
%                 activeChannel.BDS(2,svnum.BDS) = channels(n).CH_B1I(1).PRNID;
%                 if activeChannel.BDS(2,svnum.BDS)>5
%                     checkNGEO = 1;
%                 end
%                 if ephemeris(1).para(prnNum).updateReady == 0
%                     ephemeris(1).para(prnNum).eph = ephemeris(1).para(prnNum).ephUpdate;   % �״α�����������
%                     ephemeris(1).para(prnNum).updateReady = 1;
%                 else
%                     if ~isequal(ephemeris(1).para(prnNum).eph, ephemeris(1).para(prnNum).ephUpdate) ...
%                             && ephemeris(1).para(prnNum).ephReady==1% �ж��Ƿ�����������
%                         if ephemeris(1).para(prnNum).updating == 0
%                             ephemeris(1).para(prnNum).ephReady = 0;        %������������
%                             ephemeris(1).para(prnNum).subframeID(1:10) = 1:10;
%                             ephemeris(1).para(prnNum).updating = 1;   % ��1��ʾ�������ڸ�����
%                         else
%                             ephemeris(1).para(prnNum).eph = ephemeris(1).para(prnNum).ephUpdate;  % ��������
%                             ephemeris(1).para(prnNum).updating = 0;   % ���������0
%                         end
%                     end
%                 end
%                 % ���ֶ�����ֵ
%                 inteDoppler.BDS(activeChannel.BDS(2,svnum.BDS)) = -1*channels(n).CH_B1I(1).carrPhaseAccum*299792458/1561098000; % ��λΪ��
%                 % ������Ƶ��
%                 dopplerfre.BDS(activeChannel.BDS(2,svnum.BDS)) = channels(n).CH_B1I(1).LO2_fd;
%                 % �жϸ�������һ�����Ƿ�ʧ������ʧ�������¼���
%                 if pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,svnum.BDS),3) == 1
%                     pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,svnum.BDS),2) = pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,svnum.BDS),1);
%                     pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,svnum.BDS),1) = inteDoppler.BDS(activeChannel.BDS(2,svnum.BDS));
%                     pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,svnum.BDS),4) = dopplerfre.BDS(activeChannel.BDS(2,svnum.BDS));
%                 else
%                     pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,svnum.BDS),2) = 0;
%                     pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,svnum.BDS),1) = inteDoppler.BDS(activeChannel.BDS(2,svnum.BDS));
%                     pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,svnum.BDS),4) = dopplerfre.BDS(activeChannel.BDS(2,svnum.BDS));
%                 end
%                 % �����
%                 CNR.BDS(activeChannel.BDS(2,svnum.BDS))=channels(n).CH_B1I(1).CN0_Estimator.CN0;
%                 % �ز�������
%                 carrierVar.BDS(activeChannel.BDS(2,svnum.BDS))=channels(n).CH_B1I(1).sigma;
%                 % �����
%                 SNR.BDS(activeChannel.BDS(2,svnum.BDS)) = channels(n).ALL(1).SNR;
%             end
        case 'GPS_L1CA'
            prnNum = channels(n).CH_L1CA(1).PRNID;
            
%             % updateReady == 1: checking the new eph validation
%             if ~isnan(prnNum) && (ephemeris(2).para(prnNum).updateReady==1) && strcmp(channels(n).CH_L1CA(1).CH_STATUS, 'SUBFRAME_SYNCED')
%                 % perform the step 1 checking procedure
%                 [ephemeris(2).para(prnNum), updateSuccess] = ephUpdate_checkingStep1(ephemeris(2).syst, ephemeris(2).para(prnNum), posiLast, transmitimeLast);
%                 
%                 if updateSuccess ==1
%                     if (ephemeris(2).para(prnNum).ephReady ==1)
%                         ephemeris(2).para(prnNum).eph = ephsatorbit_cpy(ephemeris(2).syst, ephemeris(2).para(prnNum).eph, ephemeris(2).para(prnNum).ephUpdate);
%                         ephemeris(2).para(prnNum).ephTrustLevel = ephemeris(2).para(prnNum).ephUpdateTrustLevel;
%                     else % (ephemeris(2).para(prnNum).ephReady ==0)
%                         % ephupdate checking step 1 pass. if there is no previsou eph
%                         % available and there is no posiLast available, the
%                         % further raim checking cannot be performed, so we
%                         % update the ephupdate into eph and use it into the
%                         % first PVT calculation.
%                         % �״α�����������
%                         ephemeris(2).para(prnNum).eph = ephemeris(2).para(prnNum).ephUpdate;
%                         ephemeris(2).para(prnNum).ephRaid = ephemeris(2).para(prnNum).ephUpdate;
%                         ephemeris(2).para(prnNum).ephTrustLevel = ephemeris(2).para(prnNum).ephUpdateTrustLevel;
%                         ephemeris(2).para(prnNum).ephReady = 1;
%                     end %EOF "if (ephemeris(2).para(prnNum).ephReady ==1)"
%                 end %EOF "if updateSuccess ==1"
%                 
%                 %���ǽ�����һ������֡�����ܳɹ�������񣬾���Ҫ���½�subframeID�ó�1:10.
%                 ephemeris(2).para(prnNum).subframeID(1:10) = 1:10;
%                 ephemeris(2).para(prnNum).updateReady = 0;
%                 ephemeris(2).para(prnNum).ephUpdateTrustLevel = 0;
%             end %EOF "if ~isnan(prnNum) && (ephemeris(2).para(prnNum).updateReady==1) && strcmp(channels(n).CH_L1CA(1).CH_STATUS, 'SUBFRAME_SYNCED')"
            
            % Counting the svnum available to do PVT
%             if ~isnan(prnNum) && (ephemeris(2).para(prnNum).ephReady==1) && (ephemeris(2).para(prnNum).eph.health==0) && strcmp(channels(n).CH_L1CA(1).CH_STATUS, 'SUBFRAME_SYNCED')
%                 svnum.GPS = svnum.GPS + 1;
%                 % activeChannel.GPS: row1: channel No.;
%                 % activeChannel.GPS: row2: PRN that the channel is tracking;
%                 activeChannel.GPS(1,svnum.GPS) = n;
%                 activeChannel.GPS(2,svnum.GPS) = channels(n).CH_L1CA(1).PRNID;
%                 if activeChannel.GPS(2,svnum.GPS)>5
%                     checkNGEO = 1;
%                 end
%                 
%                 % ���ֶ�����ֵ
%                 inteDoppler.GPS(activeChannel.GPS(2,svnum.GPS)) = -1*channels(n).CH_L1CA(1).carrPhaseAccum*299792458/1575420000; % ��λΪ��
%                 % ������Ƶ��
%                 dopplerfre.GPS(activeChannel.GPS(2,svnum.GPS)) = channels(n).CH_L1CA(1).LO2_fd;
%                 % �жϸ�������һ�����Ƿ�ʧ������ʧ�������¼���
%                 if pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,svnum.GPS),3) == 1
%                     pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,svnum.GPS),2) = pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,svnum.GPS),1);
%                     pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,svnum.GPS),1) = inteDoppler.GPS(activeChannel.GPS(2,svnum.GPS));
%                     pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,svnum.GPS),4) = dopplerfre.GPS(activeChannel.GPS(2,svnum.GPS));
%                 else
%                     pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,svnum.GPS),2) = 0;
%                     pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,svnum.GPS),1) = inteDoppler.GPS(activeChannel.GPS(2,svnum.GPS));
%                     pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,svnum.GPS),4) = dopplerfre.GPS(activeChannel.GPS(2,svnum.GPS));
%                 end
%                 % �����
%                 CNR.GPS(activeChannel.GPS(2,svnum.GPS))=channels(n).CH_L1CA(1).CN0_Estimator.CN0;
%                 % �ز�������
%                 carrierVar.GPS(activeChannel.GPS(2,svnum.GPS))=channels(n).CH_L1CA(1).sigma;
%                 % �����
%                 SNR.GPS(activeChannel.GPS(2,svnum.GPS)) = channels(n).ALL(1).SNR;
%             end %EOF "if ~isnan(prnNum) && (ephemeris(2).para(prnNum).ephReady==1) && (ephemeris(2).para(prnNum).eph.health==0) && strcmp(channels(n).CH_L1CA(1).CH_STATUS, 'SUBFRAME_SYNCED')"
    end %EOF "switch channels(n).SYST"
    %%   ��ʼ����������ǵĹ۲�������λ
%     if n==config.recvConfig.numberOfChannels(1).channelNumAll && (svnum.BDS>=1||svnum.GPS>=1)
%         % ���㱱�����ǵĹ۲���
%         if svnum.BDS >= 1
%             % ����������־λ
%             pvtCalculator.BDS.doppSmooth(1:32,3) = 0;
%             pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,:),3) = 1;
%             % find trasmition time
%             [transmitTime.BDS] = findTransTime_BD(channels,activeChannel.BDS(1,:));
%             recv_time.weeknum_BDS = ephemeris(1).para(activeChannel.BDS(2,1)).eph.weekNumber;  %%�����ܼ���
%             % Compute satellite position
%             [satPositions.BDS, satClkCorr.BDS,EphAll.BDS] = BD_calculateSatPosition(transmitTime.BDS, ephemeris(1).para,activeChannel.BDS(2,:));
%             if recv_time.recvSOW_BDS == -1
%                 rxTime_BDS = median(transmitTime.BDS(transmitTime.BDS~=0)) + 70*1e-3;   % ȡ��λ������ֹ�״��ж�ʱ������쳣ֵ
%                 recv_time.recvSOW_BDS = rxTime_BDS;
%             else
%                 rxTime_BDS = recv_time.recvSOW_BDS;
%             end
%             % Compute the Pseudo-range / receiver time
%             [rawP.BDS] = calculatePseudoranges(transmitTime.BDS,rxTime_BDS,activeChannel.BDS);
%         end
%         % ����GPS�۲���
%         if svnum.GPS >= 1
%             % ����������־λ
%             pvtCalculator.GPS.doppSmooth(1:32,3) = 0;
%             pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,:),3) = 1;
%             % find trasmition time
%             [transmitTime.GPS] = findTransTime_GPS(channels, activeChannel.GPS(1,:));
%             % Compute satellite position
%             [satPositions.GPS, satClkCorr.GPS, EphAll.GPS] = GPS_calculateSatPosition(transmitTime.GPS, ephemeris(2).para,activeChannel.GPS(2,:));
%             % update time //  if BDS is used, local time uses BDT
%             recv_time.weeknum_GPS = ephemeris(2).para(activeChannel.GPS(2,1)).eph.weekNumber;  % �����ܼ���
%             if recv_time.recvSOW_GPS == -1
%                 rxTime_GPS = median(transmitTime.GPS(transmitTime.GPS~=0)) + 70*1e-3; % ȡ��λ������ֹ�״��ж�ʱ������쳣ֵ
%                 recv_time.recvSOW_GPS = rxTime_GPS;
%             else
%                 rxTime_GPS = recv_time.recvSOW_GPS;
%             end
%             % Compute the Pseudo-range / receiver time
%             [rawP.GPS] = calculatePseudoranges(transmitTime.GPS, rxTime_GPS, activeChannel.GPS);
%         end
%         %% ��������λ�ú��ٶ�
%         posiChannel = activeChannel;
%         while (1)
%             [raimFlag, posiChannel,activeChannel,svnum] =raim(prError, raimG, raimB, posiChannel, raimFlag, SYST, svnum, pvtCalculator, recv_time, rawP, activeChannel);
%             if raimFlag == 1
%                 break;
%             end
%             if strcmp(SYST,'BDS_B1I') || (strcmp(SYST,'B1I_L1CA')&&svnum.GPS==0)
%                 [xyzdt,el,az,dop, raimG, raimB,prError,pvtCalculator] = leastSquarePos_BDS(satPositions.BDS, rawP.BDS+satClkCorr.BDS(1,:)*299792458, ...
%                     transmitTime.BDS,ephemeris(1).para,activeChannel.BDS, config.recvConfig.elevationMask, checkNGEO,satClkCorr.BDS(2,:),pvtCalculator, posiChannel.BDS,recv_time);
%             elseif strcmp(SYST,'GPS_L1CA') || (strcmp(SYST,'B1I_L1CA')&&svnum.BDS==0)
%                 [xyzdt,el,az,dop, raimG, raimB,prError,pvtCalculator] = leastSquarePos_GPS(satPositions.GPS, rawP.GPS+satClkCorr.GPS(1,:)*299792458, ...
%                     transmitTime.GPS, ephemeris(2).para, activeChannel.GPS, config.recvConfig.elevationMask,satClkCorr.GPS(2,:),pvtCalculator, posiChannel.GPS,recv_time);
%             elseif  strcmp(SYST,'B1I_L1CA')
%                 [xyzdt,el,az,dop, raimG, raimB,prError,pvtCalculator] = leastSquarePos_dual(satPositions, rawP, transmitTime, ephemeris, activeChannel, config.recvConfig.elevationMask, satClkCorr, pvtCalculator, posiChannel,recv_time);
%             end
%         end
%         
%         config.recvConfig.truePosition = [xyzdt(1), xyzdt(2), xyzdt(3)];
%         %%
%         % ����������������������������ϵͳʱ�䡪��������������%
%         switch SYST
%             case 'BDS_B1I'
%                 recv_time.recvSOW_BDS = recv_time.recvSOW_BDS - xyzdt(4);   % ��������ʱ�����
%                 recv_time.weeknum = recv_time.weeknum_BDS;
%                 recv_time.recvSOW = recv_time.recvSOW_BDS;
%                 config.recvConfig.trueTime = recv_time.recvSOW;
%                 [BJyear,BJmonth,BJday_2] = calculate_yymmdd(recv_time.weeknum, 0);
%             case 'GPS_L1CA'
%                 recv_time.recvSOW_GPS = recv_time.recvSOW_GPS - xyzdt(4);
%                 recv_time.weeknum = recv_time.weeknum_GPS;
%                 recv_time.recvSOW = recv_time.recvSOW_GPS;
%                 config.recvConfig.trueTime = recv_time.recvSOW;
%                 [BJyear,BJmonth,BJday_2] = calculateGPS_yymmdd(recv_time.weeknum, 0);
%             case 'B1I_L1CA'
%                 if recv_time.recvSOW_BDS == -1
%                     recv_time.recvSOW_GPS = recv_time.recvSOW_GPS - xyzdt(4);
%                     recv_time.weeknum = recv_time.weeknum_GPS;
%                     recv_time.recvSOW = recv_time.recvSOW_GPS - recv_time.GPST2BDT;
%                     config.recvConfig.trueTime = recv_time.recvSOW;
%                     [BJyear,BJmonth,BJday_2] = calculateGPS_yymmdd(recv_time.weeknum, 0);
%                 else
%                     recv_time.recvSOW_BDS = recv_time.recvSOW_BDS - xyzdt(4);
%                     recv_time.recvSOW_GPS = recv_time.recvSOW_GPS - xyzdt(5);
%                     recv_time.weeknum = recv_time.weeknum_BDS;
%                     recv_time.recvSOW = recv_time.recvSOW_BDS;
%                     config.recvConfig.trueTime = recv_time.recvSOW;
%                     [BJyear,BJmonth,BJday_2] = calculate_yymmdd(recv_time.weeknum, 0);
%                 end
%         end
%         %�����������������������������ϴ���ȷ��λ�Ķ�λʱ�䡪������������������%
%         if pvtCalculator.posiTag == 1
%             pvtCalculator.timeLast = recv_time.recvSOW;  % ��¼�˴ζ�λʱ��
%             pvtCalculator.posiTag = 0;                   % ���±�־λ��Ϊ0
%         end
%         %����������������������������ʱ������Ϣ��������������������������������%
%         [BJday_1, BJhour, BJmin, BJsec] = sow2BJT(recv_time.recvSOW);
%         recv_time.year = BJyear;
%         recv_time.month = BJmonth;
%         recv_time.day = BJday_1 + BJday_2;
%         recv_time.hour = BJhour;
%         recv_time.min = BJmin;
%         recv_time.sec = BJsec;
%         
%         %��������������������log�ļ����������������������������%
%         logFileOutput(SYST, config, pvtCalculator, xyzdt, recv_time, rawP, inteDoppler, dopplerfre, CNR, EphAll,...
%             satClkCorr, satPositions, dop, el, az, channels, activeChannel, carrierVar, SNR, svnum,length(raimB));
%     end
    %
    %        %% ���������������Ϣ
    %         for nn = 1:length(el(3,:))
    %             pvtCalculator.sateStatus(1,el(2,nn)) = el(1,nn);             % ��������
    %             pvtCalculator.sateStatus(2,az(2,nn)) = az(1,nn);                % ���뷽λ��
    %             pvtCalculator.sateStatus(3,el(2,nn)) = rawP(el(2,nn));        % ����α��
    %         end
    %         pvtCalculator.positionXYZ = xyzdt(1:3);
    %         pvtCalculator.positionLLH = [latitude, longitude, height];
    %         pvtCalculator.positionTime = [recv_time.year, recv_time.month, recv_time.day, recv_time.hour, recv_time.min, recv_time.sec];
    %         pvtCalculator.positionDOP = dop(2);
    
end

%% Start PVT
if (svnum.BDS + svnum.GPS)>1
    % ����GPS�۲���
    if svnum.GPS >= 1
        % Find trasmition time
        [transmitTime.GPS] = findTransTime_GPS(channels, activeChannel.GPS(1,:));
        % Compute satellite position
        [satPositions.GPS, satClkCorr.GPS, EphAll.GPS] = GPS_calculateSatPosition(transmitTime.GPS, ephemeris(2).para, activeChannel.GPS(2,:));
        
%         % Update time //  if BDS is used, local time uses BDT
%         recv_time.weeknum_GPS = ephemeris(2).para(activeChannel.GPS(2,1)).eph.weekNumber;  % �����ܼ���
%         if recv_time.recvSOW_GPS == -1
%             rxTime_GPS = median(transmitTime.GPS(transmitTime.GPS~=0)) + 70*1e-3; % ȡ��λ������ֹ�״��ж�ʱ������쳣ֵ
%             recv_time.recvSOW_GPS = rxTime_GPS;
%         else
%             rxTime_GPS = recv_time.recvSOW_GPS;
%         end
        % Get the receiver local time
        [rxTime_GPS, recv_time] = get_rxTime('GPS_L1CA', recv_time, transmitTime);
        
        % Compute the Pseudo-range / receiver time
        [rawP.GPS] = calculatePseudoranges(transmitTime.GPS, rxTime_GPS, activeChannel.GPS);
    end
    
    if strcmp(SYST,'BDS_B1I') || (strcmp(SYST,'B1I_L1CA')&&svnum.GPS==0)
%         [xyzdt,el,az,dop, raimG, raimB,prError,pvtCalculator] = leastSquarePos_BDS(satPositions.BDS, rawP.BDS+satClkCorr.BDS(1,:)*299792458, ...
%                     transmitTime.BDS,ephemeris(1).para,activeChannel.BDS, config.recvConfig.elevationMask, checkNGEO,satClkCorr.BDS(2,:),pvtCalculator, posiChannel.BDS,recv_time);
    elseif strcmp(SYST,'GPS_L1CA') || (strcmp(SYST,'B1I_L1CA')&&svnum.BDS==0)
        [xyzdt,el,az,dop, raimG, raimB,prError,pvtCalculator] = ...
            leastSquarePos_GPS(satPositions.GPS, ...% matrix[6x32], each column for a sat [x;y;z;vx;vy;vz]
                               rawP.GPS, ...% vector[1x32], each for a sat pseudorange [meter]    %rawP.GPS+satClkCorr.GPS(1,:)*299792458, ...
                               transmitTime.GPS, ...% vector[1x32], each for a sat transmit time [sec]
                               ephemeris(2).para, ...% struct_vector[1x32], eph_para
                               activeChannel.GPS, ...% [2xNum], row1 is active CH No.; row2 is active CH prn; Num is the number of active chs
                               config.recvConfig.elevationMask, ...% a scalar
                               satClkCorr.GPS, ...% matrix[2x32], each colum for a sat [clk_dt; clk_df]
                               pvtCalculator, ...% PVT Calculator Structure
                               ...posiChannel.GPS,...
                               recv_time);
    elseif  strcmp(SYST,'B1I_L1CA')
%         [xyzdt,el,az,dop, raimG, raimB,prError,pvtCalculator] = leastSquarePos_dual(satPositions, rawP, transmitTime, ephemeris, activeChannel, config.recvConfig.elevationMask, satClkCorr, pvtCalculator, posiChannel,recv_time);
    end
end

end