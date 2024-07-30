function [posvel, el, az, dop, raimG, raimB,prError,pvtCalculator] = leastSquarePos_dual(satPositions, rawP, transmitTime, ephemeris, activeChannel, elevationMask, satClkCorr, pvtCalculator,posiChannel,recv_time)
%Function calculates the Least Square Solution.
%
%[pos, el, az, dop] = leastSquarePos(satpos, obs, settings);
%
%   Inputs:
%       satpos      - Satellites positions (in ECEF system: [X; Y; Z;] -
%                   one column per satellite)
%       obs         - Observations - the pseudorange measurements to each
%                   satellite:
%                   (e.g. [20000000 21000000 .... .... .... .... ....])
%       settings    - receiver settings
%        time        -transmit time
%       channelList   -activechannel
%   Outputs:
%       pos         - receiver position and receiver clock error
%                   (in ECEF system: [X, Y, Z, dt])
%       el          - Satellites elevation angles (degrees)
%       az          - Satellites azimuth angles (degrees)
%       dop         - Dilutions Of Precision ([GDOP PDOP HDOP VDOP TDOP])

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
%--------------------------------------------------------------------------
%Based on Kai Borre
%Copyright (c) by Kai Borre
%Updated by Darius Plausinaitis, Peter Rinder and Nicolaj Bertelsen
%
% CVS record:
% $Id: leastSquarePos.m,v 1.1.2.12 2006/08/22 13:45:59 dpl Exp $
%==========================================================================

%=== Initialization =======================================================
nmbOfIterations = 11;
nmbOfSatellites.BDS = size(activeChannel.BDS, 2);
nmbOfSatellites.GPS = size(activeChannel.GPS, 2);
dop = zeros(1, 5);
dtr = pi/180;
pos = zeros(5, 1);
vel = zeros(5,1); %calculate velocity and ddt
Rot_X.BDS = zeros(3,32); %%����������ת�����������λ��
Rot_X.GPS = zeros(3,32);
A = zeros(size(posiChannel.BDS,2)+size(posiChannel.GPS,2), 5);
raimG = zeros(size(posiChannel.BDS,2)+size(posiChannel.GPS,2), 5);
omc = zeros(size(posiChannel.BDS,2)+size(posiChannel.GPS,2), 1);
raimB = zeros(size(posiChannel.BDS,2)+size(posiChannel.GPS,2), 1);
az.BDS = zeros(3, nmbOfSatellites.BDS);
az.GPS = zeros(3, nmbOfSatellites.GPS);
el = az;
az.BDS(2,:)=activeChannel.BDS(2,:);    %���������ֵ�����ǵ�prn�����Ӧ
el.BDS(2,:)=activeChannel.BDS(2,:);
az.BDS(3,:)=activeChannel.BDS(1,:);    %���������ֵ�����ǵ�prn�����Ӧ
el.BDS(3,:)=activeChannel.BDS(1,:);

az.GPS(2,:)=activeChannel.GPS(2,:);    %���������ֵ�����ǵ�prn�����Ӧ
el.GPS(2,:)=activeChannel.GPS(2,:);
az.GPS(3,:)=activeChannel.GPS(1,:);    %���������ֵ�����ǵ�prn�����Ӧ
el.GPS(3,:)=activeChannel.GPS(1,:);
elUse_BDS = [];     % ʹ�����ǵ�����
elUse_GPS = [];     % ʹ�����ǵ�����
prError = [];   % ����һʱ�̶�λ�����α��в�
prError_BDS = [];   % BDS����һʱ�̶�λ�����α��в�
prError_GPS = [];   % GPS����һʱ�̶�λ�����α��в�
%---
T_amb = 20;%20
P_amb = 101.325; %KPa
P_vap = .849179;%.86; 0.61078*(H/100)*exp(T/(T+238.3)*17.2694) KPa
posvel = zeros(1, 10);

if (length(activeChannel.BDS(1,:))+length(activeChannel.GPS(1,:))) >= 5  
    sat_xyz.BDS = satPositions.BDS(1:3,:);
    sat_xyz.GPS = satPositions.GPS(1:3,:);
    satVel.BDS = satPositions.BDS(4:6,:);
    satVel.GPS = satPositions.GPS(4:6,:);
    obs.BDS = rawP.BDS + satClkCorr.BDS(1,:)*299792458;
    obs.GPS = rawP.GPS + satClkCorr.GPS(1,:)*299792458;
    %=== Iteratively find receiver position ===================================
    for iter = 1:nmbOfIterations
        useNum_BDS = 0;     % BDSʹ�����ǵ���Ŀ//ÿ�ε�����Ҫ����
        useNum_GPS = 0;     % GPSʹ�����ǵ���Ŀ//ÿ�ε�����Ҫ����
        % ---------------------����BDS�۲���Ϣ--------------------%
        for i = 1:nmbOfSatellites.BDS
           Alpha_i.BDS =[ephemeris(1).para(activeChannel.BDS(2,i)).eph.Alpha0,ephemeris(1).para(activeChannel.BDS(2,i)).eph.Alpha1, ...
                   ephemeris(1).para(activeChannel.BDS(2,i)).eph.Alpha2,ephemeris(1).para(activeChannel.BDS(2,i)).eph.Alpha3];
           Beta_i.BDS =[ephemeris(1).para(activeChannel.BDS(2,i)).eph.Beta0,ephemeris(1).para(activeChannel.BDS(2,i)).eph.Beta1, ...
                  ephemeris(1).para(activeChannel.BDS(2,i)).eph.Beta2,ephemeris(1).para(activeChannel.BDS(2,i)).eph.Beta3];         
            if iter == 1
                %--- Initialize variables at the first iteration --------------
                Rot_X.BDS(:, activeChannel.BDS(2,i)) = sat_xyz.BDS(:, activeChannel.BDS(2,i));%����i��λ��
                trop_BDS = 4;%���������������ʱ
            else
                %--- Update equations -----------------------------------------
                rho2 = (Rot_X.BDS(1, activeChannel.BDS(2,i)) - pos(1))^2 + (Rot_X.BDS(2, activeChannel.BDS(2,i)) - pos(2))^2 + ...
                    (Rot_X.BDS(3, activeChannel.BDS(2,i)) - pos(3))^2;%����i��α��ƽ��
                traveltime = sqrt(rho2) / 299792458 ;
                %--- Correct satellite position (do to earth rotation) --------
                Rot_X.BDS(:, activeChannel.BDS(2,i)) = e_r_corr(traveltime, sat_xyz.BDS(:, activeChannel.BDS(2,i)));%����i����������ת�������λ��
                %--- Find the elevation angle of the satellite ----------------
                [az.BDS(1,i), el.BDS(1,i), dist] = topocent(pos(1:3, :), Rot_X.BDS(:, activeChannel.BDS(2,i)) - pos(1:3, :));
                el.BDS(2,i) = activeChannel.BDS(2,i);
                az.BDS(2,i) = activeChannel.BDS(2,i);
                az.BDS(3,i) = activeChannel.BDS(1,i);   
                el.BDS(3,i) = activeChannel.BDS(1,i);
                % ---find the longtitude and latitude of position CGCS2000---
                [ Lat, Lon, Hight ] = cart2geo( pos(1), pos(2), pos(3), 5 );
                if iter >= 4
        %                 %--- Calculate tropospheric correction --------------------
                     trop1 = Tropospheric(T_amb,P_amb,P_vap,el.BDS(1,i));
                     trop2 =Ionospheric_BD(Lat,Lon,el.BDS(1,i),az.BDS(1,i),Alpha_i.BDS,Beta_i.BDS,transmitTime.BDS(activeChannel.BDS(2,i)),Rot_X.BDS(:,activeChannel.BDS(2,i)));
                     trop_BDS = trop1 + trop2;
                end % if iter >=6 , ... ... correct atmesphere
                %-
            end % if iter == 1 ... ... else
            if ismember(activeChannel.BDS(2,i), posiChannel.BDS(2,:))
                useNum_BDS = useNum_BDS + 1;
                elUse_BDS(useNum_BDS) = el.BDS(1,i);
            %--- Apply the corrections ----------------------------------------
                omc(useNum_BDS) = (obs.BDS(activeChannel.BDS(2,i)) - norm(Rot_X.BDS(:, activeChannel.BDS(2,i)) - pos(1:3), 'fro') - pos(4) - trop_BDS);
        %         accP(i)= (obs(activeChannel(2,i))- trop);

                %--- Construct the A matrix ---------------------------------------
                A(useNum_BDS, :) =  [ (-(Rot_X.BDS(1, activeChannel.BDS(2,i)) - pos(1))) / norm(Rot_X.BDS(:, activeChannel.BDS(2,i)) - pos(1:3), 'fro') ...
                    (-(Rot_X.BDS(2, activeChannel.BDS(2,i)) - pos(2))) / norm(Rot_X.BDS(:, activeChannel.BDS(2,i)) - pos(1:3), 'fro') ...
                    (-(Rot_X.BDS(3, activeChannel.BDS(2,i)) - pos(3))) / norm(Rot_X.BDS(:, activeChannel.BDS(2,i)) - pos(1:3), 'fro') ...
                    1 0];
            end
        end % for i = 1:nmbOfSatellites
        % ---------------------����GPS�۲���Ϣ--------------------%
        for i = 1 : nmbOfSatellites.GPS
            if ephemeris(2).para(activeChannel.GPS(2,i)).eph.Alpha0 == 'N'
                Alpha_i.GPS = [2.186179e-008,-9.73869e-008,7.03774e-008,3.031505e-008];
                Beta_i.GPS = [ 129643.8, -64245.75, -866336.2,1612913];
            else
                Alpha_i.GPS =[ephemeris(2).para(activeChannel.GPS(2,i)).eph.Alpha0,ephemeris(2).para(activeChannel.GPS(2,i)).eph.Alpha1, ...
                       ephemeris(2).para(activeChannel.GPS(2,i)).eph.Alpha2,ephemeris(2).para(activeChannel.GPS(2,i)).eph.Alpha3];
                Beta_i.GPS =[ephemeris(2).para(activeChannel.GPS(2,i)).eph.Beta0,ephemeris(2).para(activeChannel.GPS(2,i)).eph.Beta1, ...
                      ephemeris(2).para(activeChannel.GPS(2,i)).eph.Beta2,ephemeris(2).para(activeChannel.GPS(2,i)).eph.Beta3];        
            end
            if iter == 1
                %--- Initialize variables at the first iteration --------------
                Rot_X.GPS(:, activeChannel.GPS(2,i)) = sat_xyz.GPS(:, activeChannel.GPS(2,i));%����i��λ��
                trop_GPS = 4;%���������������ʱ
            else
                %--- Update equations -----------------------------------------
                rho2 = (Rot_X.GPS(1, activeChannel.GPS(2,i)) - pos(1))^2 + (Rot_X.GPS(2, activeChannel.GPS(2,i)) - pos(2))^2 + ...
                    (Rot_X.GPS(3, activeChannel.GPS(2,i)) - pos(3))^2;%����i��α��ƽ��
                traveltime = sqrt(rho2) / 299792458 ;
                %--- Correct satellite position (do to earth rotation) --------
                Rot_X.GPS(:, activeChannel.GPS(2,i)) = e_r_corr(traveltime, sat_xyz.GPS(:, activeChannel.GPS(2,i)));%����i����������ת�������λ��
                %--- Find the elevation angle of the satellite ----------------
                [az.GPS(1,i), el.GPS(1,i), dist] = topocent(pos(1:3, :), Rot_X.GPS(:, activeChannel.GPS(2,i)) - pos(1:3, :));
                el.GPS(2,i) = activeChannel.GPS(2,i);
                az.GPS(2,i) = activeChannel.GPS(2,i);
                az.GPS(3,i) = activeChannel.GPS(1,i);   
                el.GPS(3,i) = activeChannel.GPS(1,i);
                % ---find the longtitude and latitude of position CGCS2000---
                [ Lat, Lon, Hight ] = cart2geo( pos(1), pos(2), pos(3), 5 );
                if iter >= 4
        %                 %--- Calculate tropospheric correction --------------------
                     trop1 = Tropospheric(T_amb,P_amb,P_vap,el.GPS(1,i));
                     trop2 =Ionospheric_GPS(Lat,Lon,el.GPS(1,i),az.GPS(1,i),Alpha_i.GPS,Beta_i.GPS,transmitTime.GPS(activeChannel.GPS(2,i)));
                     trop_GPS = trop1 + trop2;
                end % if iter >=6 , ... ... correct atmesphere
                %-
            end % if iter == 1 ... ... else
            if ismember(activeChannel.GPS(2,i), posiChannel.GPS(2,:))
                useNum_GPS = useNum_GPS + 1;
                elUse_GPS(useNum_GPS) = el.GPS(1,i); 
                %--- Apply the corrections ----------------------------------------
                omc(useNum_GPS+useNum_BDS) = (obs.GPS(activeChannel.GPS(2,i)) - norm(Rot_X.GPS(:, activeChannel.GPS(2,i)) - pos(1:3), 'fro') - pos(5) - trop_GPS);
        %         accP(i)= (obs(activeChannel(2,i))- trop);

                %--- Construct the A matrix ---------------------------------------
                A(useNum_GPS+useNum_BDS, :) =  [ (-(Rot_X.GPS(1, activeChannel.GPS(2,i)) - pos(1))) / norm(Rot_X.GPS(:, activeChannel.GPS(2,i)) - pos(1:3), 'fro') ...
                    (-(Rot_X.GPS(2, activeChannel.GPS(2,i)) - pos(2))) / norm(Rot_X.GPS(:, activeChannel.GPS(2,i)) - pos(1:3), 'fro') ...
                    (-(Rot_X.GPS(3, activeChannel.GPS(2,i)) - pos(3))) / norm(Rot_X.GPS(:, activeChannel.GPS(2,i)) - pos(1:3), 'fro') ...
                    0 1];
            end
        end
        if iter == nmbOfIterations
            raimG = A;
            raimB = omc;
        end
        if iter >= 6
            satUsed.GPS = posiChannel.GPS(2,:);  % ����λ�����ٶȽ�������Ǻ�
            satUsed.BDS = posiChannel.BDS(2,:);  % ����λ�����ٶȽ�������Ǻ�
            bEsti = omc - A/(A'*A)*A'*omc;    % �������
            WSSE = (norm(bEsti))^2;         % �����ֵ
            if WSSE < chi2inv(0.99999, size(A,1)-4)     % ����ж��д������ǣ��򲻾����������ж�
            % ��ȥ��GPS���ǵ���elevationMask������    
                for j = useNum_GPS:-1:1  
                     if elUse_GPS(j) < elevationMask    
                         if size(A,1) >= 4
                             omc(j+useNum_BDS) = [];
                             A(j+useNum_BDS,:) = [];
                             satUsed.GPS(j) = [];
                         end
                     end
                end
                % ��ȥ��BDS���ǵ���elevationMask������
                for j = useNum_BDS:-1:1  
                     if elUse_BDS(j) < elevationMask
                         if size(A,1) >= 4
                             omc(j) = [];
                             A(j,:) = [];
                             satUsed.BDS(j) = [];
                         end
                     end
                end
            end
        end
        % These lines allow the code to exit gracefully in case of any errors
        if rank(A) ~= 5
            posvel     = zeros(1, 10);
            return
        end

        %--- Find position update ---------------------------------------------
        x   = A \ omc;

        %--- Apply position update --------------------------------------------
        pos = pos + x;

    end % for iter = 1:nmbOfIterations
    % fprintf('Satellite pos(��ת����) -- %.6f \n', Rot_X);
    % fprintf('accP -- %.6f \n',accP);
    % fprintf('daqiwucha -- %.6f     dianliwucha -- %.6f \n',wucha(:,1),wucha(:,2));
    % fprintf('az -- %.6f \n',az);
    % fprintf('el -- %.6f \n',el);
    pos = pos';
    
    %calculate velocity from carrier frequency
    bVel = zeros((length(satUsed.BDS)+length(satUsed.GPS)), 1);
    for k = 1:length(satUsed.BDS)
        if pvtCalculator.BDS.doppSmooth(satUsed.BDS(k), 2) ~= 0 
            deltaP = pvtCalculator.BDS.doppSmooth(satUsed.BDS(k),1) - pvtCalculator.BDS.doppSmooth(satUsed.BDS(k),2);   %���ֶ�����һ��ı仯����m��
        else
            deltaP = -299792458/1561098000*pvtCalculator.BDS.doppSmooth(satUsed.BDS(k),4);    % ������Ƶ�ƣ�m��
        end
        bVel(k) = [ (-(Rot_X.BDS(1, satUsed.BDS(k)) - pos(1))) / norm(Rot_X.BDS(:, satUsed.BDS(k)) - pos(1:3)', 'fro') ...
                (-(Rot_X.BDS(2, satUsed.BDS(k)) - pos(2))) / norm(Rot_X.BDS(:, satUsed.BDS(k)) - pos(1:3)', 'fro') ...
                (-(Rot_X.BDS(3, satUsed.BDS(k)) - pos(3))) / norm(Rot_X.BDS(:, satUsed.BDS(k)) - pos(1:3)', 'fro')]*satVel.BDS(:,satUsed.BDS(k))...
                + deltaP + 299792458*satClkCorr.BDS(2,satUsed.BDS(k));
    end
    for k = 1:length(satUsed.GPS)
        if pvtCalculator.GPS.doppSmooth(satUsed.GPS(k), 2) ~= 0 
            deltaP = pvtCalculator.GPS.doppSmooth(satUsed.GPS(k),1) - pvtCalculator.GPS.doppSmooth(satUsed.GPS(k),2);   %���ֶ�����һ��ı仯����m��
        else
            deltaP = -299792458/1575420000*pvtCalculator.GPS.doppSmooth(satUsed.GPS(k),4);    % ������Ƶ�ƣ�m��
        end
        bVel(k+length(satUsed.BDS)) = [ (-(Rot_X.GPS(1, satUsed.GPS(k)) - pos(1))) / norm(Rot_X.GPS(:, satUsed.GPS(k)) - pos(1:3)', 'fro') ...
                (-(Rot_X.GPS(2, satUsed.GPS(k)) - pos(2))) / norm(Rot_X.GPS(:, satUsed.GPS(k)) - pos(1:3)', 'fro') ...
                (-(Rot_X.GPS(3, satUsed.GPS(k)) - pos(3))) / norm(Rot_X.GPS(:, satUsed.GPS(k)) - pos(1:3)', 'fro')]*satVel.GPS(:,satUsed.GPS(k))...
                + deltaP + 299792458*satClkCorr.GPS(2,satUsed.GPS(k));
    end
    vel = A \ bVel;     % �����ٶ�
    % vel=HH\d;
    pos(4) = pos(4)/299792458;
    pos(5) = pos(5)/299792458;
    posvel = [pos,vel'];
    
     %��������������������������������α�����ϴζ�λ����Ĳв�  BDS����������������������������%
    for k = 1 : size(posiChannel.BDS, 2)
        timeDiff = recv_time.recvSOW - pvtCalculator.timeLast;
        posiFore = pvtCalculator.posiLast(1:3);% + pvtCalculator.posiLast(6:8) * timeDiff;        % ����Ϊ�����˶����Ӷ��Ե�ǰλ����������
        rho2 = (sat_xyz.BDS(1, posiChannel.BDS(2,k)) - posiFore(1))^2 + (sat_xyz.BDS(2, posiChannel.BDS(2,k)) - posiFore(2))^2 + ...
                    (sat_xyz.BDS(3, posiChannel.BDS(2,k)) - posiFore(3))^2;%����i��α��ƽ��
        traveltime = sqrt(rho2) / 299792458 ; 
        %--- Correct satellite position (do to earth rotation) --------
        Rot_X.BDS(:, posiChannel.BDS(2,k)) = e_r_corr(traveltime, sat_xyz.BDS(:, posiChannel.BDS(2,k)));%����i����������ת�������λ��
        prError_BDS(k) = (obs.BDS(posiChannel.BDS(2,k)) - norm(Rot_X.BDS(:, posiChannel.BDS(2,k)) - posiFore(1:3), 'fro') - pvtCalculator.posiLast(4)*299792458 - trop_BDS);
    end 
    clcErrFore = median(prError_BDS);    % Ԥ�������ջ����Ӳ�ֵ
    prError_BDS = prError_BDS - clcErrFore;   % ȥ���Ӳ�ֵ
    %��������������������������������α�����ϴζ�λ����Ĳв�  GPS����������������������������%
    for k = 1 : size(posiChannel.GPS, 2)
        timeDiff = recv_time.recvSOW - pvtCalculator.timeLast;
        posiFore = pvtCalculator.posiLast(1:3);% + pvtCalculator.posiLast(6:8) * timeDiff;        % ����Ϊ�����˶����Ӷ��Ե�ǰλ����������
        rho2 = (sat_xyz.GPS(1, posiChannel.GPS(2,k)) - posiFore(1))^2 + (sat_xyz.GPS(2, posiChannel.GPS(2,k)) - posiFore(2))^2 + ...
                    (sat_xyz.GPS(3, posiChannel.GPS(2,k)) - posiFore(3))^2;%����i��α��ƽ��
        traveltime = sqrt(rho2) / 299792458 ; 
        %--- Correct satellite position (do to earth rotation) --------
        Rot_X.GPS(:, posiChannel.GPS(2,k)) = e_r_corr(traveltime, sat_xyz.GPS(:, posiChannel.GPS(2,k)));%����i����������ת�������λ��
        prError_GPS(k) = (obs.GPS(posiChannel.GPS(2,k)) - norm(Rot_X.GPS(:, posiChannel.GPS(2,k)) - posiFore(1:3), 'fro') - pvtCalculator.posiLast(4)*299792458 - trop_GPS);
    end 
    clcErrFore = median(prError_GPS);    % Ԥ�������ջ����Ӳ�ֵ
    prError_GPS = prError_GPS - clcErrFore;   % ȥ���Ӳ�ֵ
    prError = [prError_BDS, prError_GPS];
    %���������������������������������ζ�λ�����ȷ�����¼���ζ�λ�������������������%
    bEsti = omc - A/(A'*A)*A'*omc;    % �������
    WSSE = (norm(bEsti))^2;         % �����ֵ
    if size(A,1) > 5    % ��λ����Ϊ��������
        if WSSE < chi2inv(0.99999, size(A,1)-5)     % �ж϶�λ����Ƿ���ȷ
            pvtCalculator.posiLast = posvel';    % ����ȷ����¼��λ���
            pvtCalculator.posiTag = 1;  % λ����Ϣ�Ѹ���
            pvtCalculator.posiCheck = 1;    % ��Ϊ��λ�������
        end
    else
        if pvtCalculator.posiLast(1)~=0 && pvtCalculator.posiCheck==1  % �п��Ž��
            posiDistance = sqrt((pvtCalculator.posiLast(1) - posvel(1))^2+(pvtCalculator.posiLast(2) - posvel(2))^2+(pvtCalculator.posiLast(3) - posvel(3))^2);
            if posiDistance < 100   % ���ζ�λ���С��100m
                pvtCalculator.posiLast = posvel';    % ��¼��λ���
                pvtCalculator.posiTag = 1;  % λ����Ϣ�Ѹ���
                pvtCalculator.posiCheck = 1;    % ��Ϊ��λ�������
            else
                pvtCalculator.posiLast = posvel';    % ��¼��λ���
                pvtCalculator.posiTag = 1;  % λ����Ϣ�Ѹ���
                pvtCalculator.posiCheck = 0;    % ��Ϊ��λ�����ȷ��
            end
        else
            pvtCalculator.posiLast = posvel';    % ��¼��λ���
            pvtCalculator.posiTag = 1;  % λ����Ϣ�Ѹ���
            pvtCalculator.posiCheck = 0;    % ��Ϊ��λ�����ȷ��
        end
    end
    
     %������������������������������������ֵ��������������������������������%
    if pvtCalculator.kalman.preTag==0 && pvtCalculator.posiCheck==1
        pvtCalculator.kalman.state = posvel([1,6,2,7,3,8,4,9,5,10])';     % ״̬����  N-by-1    ��̬ģ��ֻ����λ�ú��Ӳ�
        P_1 = [36,0;0,0.1];
        pvtCalculator.kalman.P = blkdiag(P_1,P_1,P_1,P_1,P_1);         % ���Э�������
        pvtCalculator.kalman.state_static = posvel([1,2,3,4,9])';     % ״̬����  N-by-1    ��̬ģ��ֻ����λ�ú��Ӳ�
        pvtCalculator.kalman.P_static = blkdiag(eye(4)*10,0.01);         % ���Э�������
        pvtCalculator.kalman.preTag = 1;
    end
    %=== Calculate Dilution Of Precision ======================================
    % if nargout  == 4
        %--- Initialize output ------------------------------------------------


        %--- Calculate DOP ----------------------------------------------------
        Q       = inv(A'*A);

        dop(1)  = sqrt(trace(Q));                       % GDOP
        dop(2)  = sqrt(Q(1,1) + Q(2,2) + Q(3,3));       % PDOP
        dop(3)  = sqrt(Q(1,1) + Q(2,2));                % HDOP
        dop(4)  = sqrt(Q(3,3));                         % VDOP
        dop(5)  = sqrt(Q(4,4));                         % TDOP
         fprintf('dop -- %.6f \n',dop(2));
end
end
