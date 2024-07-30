%% start PVT
% initial
function [recv_time, ephemeris, pvtCalculator, config] = rangeDiffBDS(channels, config, recv_time, ephemeris, pvtCalculator) 
%% ��ʼ��
svnum = 0;% this flag is to find whether avaliable satellite is above 4
activeChannel = [];% avaliable channels
checkNGEO = 0;%%���NGEO����
inteDoppler = zeros(1,30);%���ֶ�����ֵ
dopplerfre = zeros(1,30);%������Ƶ��
CNR = zeros(1,30);  %��������
SNR = zeros(1,30);  %��������
carrierVar = zeros(1, 30);  % ����ز�������

%% start PVT
for  n=1:config.numberOfChannels
    prnNum = channels(n).CH_B1I(1).PRNID;
    if  ~isnan(prnNum) && (ephemeris(prnNum).ephReady==1 || ephemeris(prnNum).updateReady == 1) ...
            && ephemeris(prnNum).ephUpdate.health==0 && strcmp(channels(n).CH_B1I(1).CH_STATUS, 'SUBFRAME_SYNCED')        
        svnum = svnum + 1;
        activeChannel(1,svnum) = n;
        activeChannel(2,svnum) = channels(n).CH_B1I(1).PRNID;
        if activeChannel(2,svnum)>5
            checkNGEO = 1;
        end
        if ephemeris(prnNum).updateReady == 0   
            ephemeris(prnNum).eph = ephemeris(prnNum).ephUpdate;   % �״α�����������
            ephemeris(prnNum).updateReady = 1;
        else
            if ~isequal(ephemeris(prnNum).eph, ephemeris(prnNum).ephUpdate) ...
                     && ephemeris(prnNum).ephReady==1% �ж��Ƿ�����������
                 if ephemeris(prnNum).updating == 0
                     ephemeris(prnNum).ephReady = 0;        %������������
                     ephemeris(prnNum).subframeID(1:10) = 1:10; 
                     ephemeris(prnNum).updating = 1;   % ��1��ʾ�������ڸ�����
                 else
                     ephemeris(prnNum).eph = ephemeris(prnNum).ephUpdate;  % ��������
                     ephemeris(prnNum).updating = 0;   % ���������0
                 end                 
            end
        end

        % ���ֶ�����ֵ
        inteDoppler(activeChannel(2,svnum)) = -1*channels(n).CH_B1I(1).carrPhaseAccum*299792458/1561098000; 
        % ������Ƶ��
        dopplerfre(activeChannel(2,svnum)) = channels(n).CH_B1I(1).LO2_fd;
        % �����
        CNR(activeChannel(2,svnum))=channels(n).CH_B1I(1).CN0_Estimator.CN0;
        % �ز�������
        carrierVar(activeChannel(2,svnum))=channels(n).CH_B1I(1).sigma;
        % �����
        SNR(activeChannel(2,svnum)) = channels(n).ALL(1).SNR;
   end
 %%
    if svnum>=1 && n == config.numberOfChannels 
      % find trasmition time 
       [transmitTime] = findTransTime_BD(channels,activeChannel(1,:));
       recv_time.weeknum = ephemeris(activeChannel(2,1)).eph.weekNumber;  %%�����ܼ���

      % Compute satellite position
        [satPositions, satClkCorr,EphAll] = BD_calculateSatPosition(transmitTime, ...
         ephemeris,activeChannel(2,:));      
      if recv_time.recvSOW == -1
          rxTime = max(transmitTime) + 70*1e-3;
          recv_time.recvSOW = rxTime;
      else
          rxTime = recv_time.recvSOW;
      end
%       calculate raw Pseudoranges        
      [prDiff, rawP, activeChannel, pvtCalculator] = calculatePseudoranges_hatched...
          (transmitTime,rxTime,activeChannel,inteDoppler,pvtCalculator);           
      % Performing the PVT
       [xyzdt,~,~,~] = leastSq_rangeDiff(satPositions, prDiff, activeChannel, config.elevationMask, checkNGEO); %freqforcal,reveiver.recv_cfg);       
       
         %   ���õ��㶨λ��ʱ
        [dt,el,az,dop] = leastSquarePos(satPositions, rawP+satClkCorr*299792458, ... 
            transmitTime-satClkCorr,ephemeris,activeChannel, config.elevationMask, checkNGEO); %freqforcal,reveiver.recv_cfg);   
        queue=sort(el(2,:));
        %=== Convert to geodetic coordinates ==============================
       %-------save x,y,z to XYZ.txt-------------------------------------%
       logName = strcat(config.logFilePath, pvtCalculator.logName, '_XYZ.txt');
       fid = fopen(logName, 'a');
       fprintf(fid,'%f%20f%20f\n',xyzdt(1),xyzdt(2),xyzdt(3));
       fclose(fid);
       %-------printf results          ----------------------------------%
       [latitude,longitude,height] = cart2geo(xyzdt(1),xyzdt(2),xyzdt(3),5);
        fprintf('Positioning -- latitude: %.6f��;longitude: %.6f��;height: %.2f \n', ...
             latitude,longitude,height);
       fprintf('%f   %20f  %20f\n',xyzdt(1),xyzdt(2),xyzdt(3));
       %-------save la,lon,H to LLH.txt----------------------------------% 
       logName = strcat(config.logFilePath, pvtCalculator.logName, '_LLH.txt');
       fid = fopen(logName, 'a');
       fprintf(fid,'%f%20f%20.3f\n',latitude,longitude,height);
       fclose(fid);
       %--------save XYZ error_______________________________________%
%        right_xyz = [-2853454.640, 4667446.608, 3268284.718];
%        xyz_error = sqrt((xyzdt(1)-right_xyz(1))^2 + ...
%            (xyzdt(2)-right_xyz(2))^2 + (xyzdt(3)-right_xyz(3))^2);
%        fid = fopen('xyz_error.txt','a');
%        fprintf(fid,'%f\n',xyz_error);
%        fclose(fid);
%        fid = fopen('error_xyz.txt','a');
%        fprintf(fid,'%f  %f  %f\n',xyzdt(1)-right_xyz(1), xyzdt(2)-right_xyz(2), xyzdt(3)-right_xyz(3));
%        fclose(fid);       
       %-------printf results          ----------------------------------%   
       %-------save la,lon,H to LLH.txt----------------------------------% 
%        fid = fopen('LLH.txt','a');
%        fprintf(fid,'%f��%20f��%20.3f\n',latitude,longitude,height);
%        fclose(fid);

       %%
       %����������ʱ����
       [BJday_1, BJhour, BJmin, BJsec] = sow2BJT(recv_time.recvSOW);
       [BJyear,BJmonth,BJday] = calculate_yymmdd(recv_time.weeknum, BJday_1);
       recv_time.year = BJyear;
       recv_time.month = BJmonth;
       recv_time.day = BJday;
       recv_time.hour = BJhour;
       recv_time.min = BJmin;
       recv_time.sec = BJsec;
       %% ��������ʱ�����
       recv_time.recvSOW = recv_time.recvSOW - dt(4);  %
       config.truePosition = [xyzdt(1), xyzdt(2), xyzdt(3)];    % ���ݶ�λ���
       config.trueTime = recv_time.recvSOW;
       recv_time.loopSOW = recv_time.recvSOW;
     %%  output log file
       logName = strcat(config.logFilePath, pvtCalculator.logName, '.15O');
       fid_0=fopen(logName);
       if fid_0==-1
           rinexobs_header(xyzdt,recv_time, logName);
       else
           fclose(fid_0);
       end
       rinexobs_data(recv_time,rawP,inteDoppler,dopplerfre,CNR,dt(4),queue, logName);
       
       logName = strcat(config.logFilePath, pvtCalculator.logName, '.15N');
       fid_1=fopen(logName);
       if fid_1==-1
           rinexnavi_header(logName);
       else
           fclose(fid_1);
       end
       [pvtCalculator] = rinexnavi_data(recv_time,EphAll,satClkCorr,queue, pvtCalculator,logName);
       
       logName = strcat(config.logFilePath, pvtCalculator.logName, '.15MP');
       fid_2=fopen(logName);
       if fid_2==-1
           rinexmp_header(recv_time,logName);
       else
           fclose(fid_2);
       end
       rinexmp_data(recv_time,channels,activeChannel,logName); 
       
       OutputSateObs(el, az, dop, recv_time,queue, config.logFilePath, pvtCalculator.logName, carrierVar, SNR, CNR);      % ������ǵ����Ǻͷ�λ����Ϣ
       OutputGPGGA(latitude, longitude, height, BJhour, BJmin, BJsec, length(queue), config.logFilePath, pvtCalculator.logName);  % ���GPGGA����
     
            %% ���������������Ϣ      
        for nn = 1:length(el(3,:))
            pvtCalculator.sateStatus(1,el(2,nn)) = el(1,nn);             % ��������
            pvtCalculator.sateStatus(2,az(2,nn)) = az(1,nn);                % ���뷽λ��
            pvtCalculator.sateStatus(3,el(2,nn)) = rawP(el(2,nn));        % ����α��
        end
        pvtCalculator.positionXYZ = xyzdt(1:3);
        pvtCalculator.positionLLH = [latitude, longitude, height];
        pvtCalculator.positionTime = [recv_time.year, recv_time.month, recv_time.day, recv_time.hour, recv_time.min, recv_time.sec];
        pvtCalculator.positionDOP = dop(2);
    end
end  %  n=1:receiver.recv_cfg.numberOfChannels
      


end