function [posvel, el, az, dop, raimG, raimB,prError,pvtCalculator] = ...
    leastSquarePos_BDS(satpos, obs,Beijing_Time,ephemeris,activeChannel, elevationMask, checkNGEO,satClkCorr,pvtCalculator,posiChannel,recv_time)%freqforcal, settings)
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
dop     = zeros(1, 5);
dtr     = pi/180;
pos     = zeros(4, 1);
vel = zeros(4,1); %calculate velocity and ddt
sat_xyz = satpos(1:3,:);
satVel = satpos(4:6,:);
nmbOfSatellites = size(activeChannel, 2);
Rot_X   = zeros(3,30);%%����������ת�����������λ��
A       = zeros(size(posiChannel,2), 4);
raimG = zeros(size(posiChannel,2), 4);  % raim �㷨��ʹ��
omc     = zeros(size(posiChannel,2), 1);
raimB = zeros(size(posiChannel,2), 1);    % raim �㷨��ʹ��
az.BDS      = zeros(3, nmbOfSatellites);
el.BDS      = az.BDS;
az.BDS(2,:)=activeChannel(2,:);    %���������ֵ�����ǵ�prn�����Ӧ
el.BDS(2,:)=activeChannel(2,:);
az.BDS(3,:)=activeChannel(1,:);    %���������ֵ�����ǵ�prn�����Ӧ
el.BDS(3,:)=activeChannel(1,:);
az.GPS = [];
el.GPS = [];
prError = [];   % ����һʱ�̶�λ�����α��в�
elUse = [];     % ʹ�����ǵ�����
%---
T_amb = 20;%20
P_amb = 101.325; %KPa
P_vap = .849179;%.86; 0.61078*(H/100)*exp(T/(T+238.3)*17.2694) KPa
posvel = zeros(1, 10);

if length(activeChannel(1,:))>=4 && checkNGEO==1
    %=== Iteratively find receiver position ===================================
    for iter = 1:nmbOfIterations
        useNum = 0;     % ʹ�����ǵ���Ŀ//ÿ�ε�����Ҫ����
        for i = 1:nmbOfSatellites
            Alpha_i =[ephemeris(activeChannel(2,i)).eph.Alpha0,ephemeris(activeChannel(2,i)).eph.Alpha1, ...
                ephemeris(activeChannel(2,i)).eph.Alpha2,ephemeris(activeChannel(2,i)).eph.Alpha3];
            Beta_i =[ephemeris(activeChannel(2,i)).eph.Beta0,ephemeris(activeChannel(2,i)).eph.Beta1, ...
                ephemeris(activeChannel(2,i)).eph.Beta2,ephemeris(activeChannel(2,i)).eph.Beta3];
            if iter == 1
                %--- Initialize variables at the first iteration --------------
                Rot_X(:, activeChannel(2,i)) = sat_xyz(:, activeChannel(2,i));%����i��λ��
                trop = 4;%���������������ʱ
            else
                %--- Update equations -----------------------------------------
                rho2 = (Rot_X(1, activeChannel(2,i)) - pos(1))^2 + (Rot_X(2, activeChannel(2,i)) - pos(2))^2 + ...
                    (Rot_X(3, activeChannel(2,i)) - pos(3))^2;%����i��α��ƽ��
                traveltime = sqrt(rho2) / 299792458 ;
                
                %--- Correct satellite position (do to earth rotation) --------
                Rot_X(:, activeChannel(2,i)) = e_r_corr(traveltime, sat_xyz(:, activeChannel(2,i)));%����i����������ת�������λ��
                
                %--- Find the elevation angle of the satellite ----------------
                [az.BDS(1,i), el.BDS(1,i), dist] = topocent(pos(1:3, :), Rot_X(:, activeChannel(2,i)) - pos(1:3, :));
                el.BDS(2,i) = activeChannel(2,i);
                az.BDS(2,i) = activeChannel(2,i);
                az.BDS(3,i) = activeChannel(1,i);
                el.BDS(3,i) = activeChannel(1,i);
                %            ---find the longtitude and latitude of position CGCS2000---
                [ Lat, Lon, Hight ] = cart2geo( pos(1), pos(2), pos(3), 5 );
                %-
                if iter>=4
                    %             if (settings.useTropCorr == 1)
                    %                 %--- Calculate tropospheric correction --------------------
                    %                 if (settings.useIonoCorr == 1)
                    trop1 = Tropospheric(T_amb,P_amb,P_vap,el.BDS(1,i));
                    trop2 =Ionospheric_BD(Lat,Lon,el.BDS(1,i),az.BDS(1,i),Alpha_i,Beta_i,Beijing_Time(activeChannel(2,i)),Rot_X(:,activeChannel(2,i)));
                    trop = trop1 + trop2;
                    wucha(i,1) = trop1;
                    wucha(i,2) = trop2;
                    
                end % if iter >=6 , ... ... correct atmesphere
                %-
            end % if iter == 1 ... ... else
            if ismember(activeChannel(2,i), posiChannel(2,:))
                useNum = useNum + 1;
                elUse(useNum) = el.BDS(1,i);
                %--- Apply the corrections ----------------------------------------
                omc(useNum) = (obs(activeChannel(2,i)) - norm(Rot_X(:, activeChannel(2,i)) - pos(1:3), 'fro') - pos(4) - trop);
                %--- Construct the A matrix ---------------------------------------
                A(useNum, :) =  [ (-(Rot_X(1, activeChannel(2,i)) - pos(1))) / norm(Rot_X(:, activeChannel(2,i)) - pos(1:3), 'fro') ...
                    (-(Rot_X(2, activeChannel(2,i)) - pos(2))) / norm(Rot_X(:, activeChannel(2,i)) - pos(1:3), 'fro') ...
                    (-(Rot_X(3, activeChannel(2,i)) - pos(3))) / norm(Rot_X(:, activeChannel(2,i)) - pos(1:3), 'fro') ...
                    1 ];
            end
        end % for i = 1:nmbOfSatellites
        if iter == nmbOfIterations
            raimG = A;
            raimB = omc;
        end
        if iter > 6
            satUsed = posiChannel(2,:);  % ����λ�����ٶȽ�������Ǻ�
            bEsti = omc - A/(A'*A)*A'*omc;    % �������
            WSSE = (norm(bEsti))^2;         % �����ֵ
            if WSSE < chi2inv(0.99999, size(A,1)-4)     % ����ж��д������ǣ��򲻾����������ж�
                for j= useNum:-1:1  %ȥ�����ǵ���elevationMask������
                    if elUse(j) < elevationMask
                        if size(A,1) >= 4
                            omc(j)=[];
                            A(j,:)=[];
                            satUsed(j)=[];
                        end
                    end
                end
            end
        end
        % These lines allow the code to exit gracefully in case of any errors
        if rank(A) ~= 4
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
    bVel = zeros(length(satUsed), 1);
    for k = 1:length(satUsed)
        if pvtCalculator.BDS.doppSmooth(satUsed(k), 2) ~= 0
            deltaP = pvtCalculator.BDS.doppSmooth(satUsed(k),1) - pvtCalculator.BDS.doppSmooth(satUsed(k),2);   %���ֶ�����һ��ı仯����m��
        else
            deltaP = -299792458/1561098000*pvtCalculator.BDS.doppSmooth(satUsed(k),4);    % ������Ƶ�ƣ�m��
        end
        bVel(k) = [ (-(Rot_X(1, satUsed(k)) - pos(1))) / norm(Rot_X(:, satUsed(k)) - pos(1:3)', 'fro') ...
            (-(Rot_X(2, satUsed(k)) - pos(2))) / norm(Rot_X(:, satUsed(k)) - pos(1:3)', 'fro') ...
            (-(Rot_X(3, satUsed(k)) - pos(3))) / norm(Rot_X(:, satUsed(k)) - pos(1:3)', 'fro')]*satVel(:,satUsed(k))...
            + deltaP + 299792458*satClkCorr(satUsed(k));
    end
    vel = A \ bVel;     % �����ٶ�
    pos(4)=pos(4)/299792458;
    posvel=[pos,0,vel',0];
    
    %��������������������������������α�����ϴζ�λ����Ĳв��������������������������%
    for k = 1 : size(posiChannel, 2)
        timeDiff = recv_time.recvSOW - pvtCalculator.timeLast;
        posiFore = pvtCalculator.posiLast(1:3);% + pvtCalculator.posiLast(6:8) * timeDiff;        % ����Ϊ�����˶����Ӷ��Ե�ǰλ����������
        rho2 = (sat_xyz(1, posiChannel(2,k)) - posiFore(1))^2 + (sat_xyz(2, posiChannel(2,k)) - posiFore(2))^2 + ...
            (sat_xyz(3, posiChannel(2,k)) - posiFore(3))^2;%����i��α��ƽ��
        traveltime = sqrt(rho2) / 299792458 ;
        %--- Correct satellite position (do to earth rotation) --------
        Rot_X(:, posiChannel(2,k)) = e_r_corr(traveltime, sat_xyz(:, posiChannel(2,k)));%����i����������ת�������λ��
        prError(k) = (obs(posiChannel(2,k)) - norm(Rot_X(:, posiChannel(2,k)) - posiFore(1:3), 'fro') - pvtCalculator.posiLast(4)*299792458 - trop);
    end
    clcErrFore = median(prError);    % Ԥ�������ջ����Ӳ�ֵ
    prError = prError - clcErrFore;   % ȥ���Ӳ�ֵ
    %���������������������������������ζ�λ�����ȷ�����¼���ζ�λ�������������������%
    bEsti = omc - A/(A'*A)*A'*omc;    % �������
    WSSE = (norm(bEsti))^2;         % �����ֵ
    if size(A,1) > 4    % ��λ����Ϊ��������
        if WSSE < chi2inv(0.99999, size(A,1)-4)     % �ж϶�λ����Ƿ���ȷ
            pvtCalculator.posiLast = posvel';    % ����ȷ����¼��λ���
            pvtCalculator.posiTag = 1;  % λ����Ϣ�Ѹ���
            pvtCalculator.posiCheck = 1;    % ��Ϊ��λ�������
        end
    else
        if pvtCalculator.posiLast(1)~=0 && pvtCalculator.posiCheck==1
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
    if pvtCalculator.kalman.preTag==0 %&& pvtCalculator.posiCheck==1
        pvtCalculator.kalman.state = posvel([1,6,2,7,3,8,4,9])';     % ״̬����  N-by-1    ��̬ģ��ֻ����λ�ú��Ӳ�
        pvtCalculator.kalman.P = eye(8)*10;         % ���Э�������
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
    %          fprintf('dop -- %.6f \n',dop(2));
end
end
