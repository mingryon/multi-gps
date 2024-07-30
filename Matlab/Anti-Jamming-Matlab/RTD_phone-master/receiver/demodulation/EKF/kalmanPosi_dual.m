function [posvel,el,az,dop,pvtCalculator] = kalmanPosi_dual(satPositions, rawP,transmitTime,ephemeris,activeChannel, ...
    elevationMask,satClkCorr,pvtCalculator,posiChannel,recv_time)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%
%
%
%
%
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = 1;  % �۲���1s
%������������ Set Q����������������%
Sf = 1;
Sg = 0.01;
sigma=1;         %state transition variance
Qb = [Sf*T+Sg*T*T*T/3, Sg*T*T/2; Sg*T*T/2, Sg*T];
Qxyz = sigma^2 * [T^3/3, T^2/2; T^2/2, T];
Q = blkdiag(Qxyz, Qxyz, Qxyz, Qb, Qb);
% ������������Set R����������������%
Rhoerror = [49,0.06];                                               % variance of measurement error(pseudorange error)
R_Num = size(posiChannel.BDS,2)+size(posiChannel.GPS,2);
R = diag(repmat(Rhoerror,1,R_Num)); 

X = pvtCalculator.kalman.state;     % ״̬����  N-by-1
P = pvtCalculator.kalman.P;         % ���Э�������
%�����������������������˲����¡���������������%
%=== Initialization =======================================================
%nmbOfIterations = 11;
%=== Initialization =======================================================
nmbOfSatellites.BDS = size(activeChannel.BDS, 2);
nmbOfSatellites.GPS = size(activeChannel.GPS, 2);
dop = zeros(1, 5);
pos = X([1,3,5,7,9]);
Rot_X.BDS = zeros(3,32); %%����������ת�����������λ��
Rot_X.GPS = zeros(3,32);
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
sat_xyz.BDS = satPositions.BDS(1:3,:);
sat_xyz.GPS = satPositions.GPS(1:3,:);
satVel.BDS = satPositions.BDS(4:6,:);
satVel.GPS = satPositions.GPS(4:6,:);
obs.BDS = rawP.BDS + satClkCorr.BDS(1,:)*299792458;
obs.GPS = rawP.GPS + satClkCorr.GPS(1,:)*299792458;
%---
T_amb = 20;%20
P_amb = 101.325; %KPa
P_vap = .849179;%.86; 0.61078*(H/100)*exp(T/(T+238.3)*17.2694) KPa
posvel = zeros(1, 10);


%if length(activeChannel(1,:))>=4 && checkNGEO==1
    %=== Iteratively find receiver position ===================================
%    for iter = 1:nmbOfIterations
useNum_BDS = 0;     % BDSʹ�����ǵ���Ŀ//ÿ�ε�����Ҫ����
useNum_GPS = 0;     % GPSʹ�����ǵ���Ŀ//ÿ�ε�����Ҫ����
% ---------------------����BDS�۲���Ϣ--------------------%
for i = 1:nmbOfSatellites.BDS
    Alpha_i.BDS =[ephemeris(1).para(activeChannel.BDS(2,i)).eph.Alpha0,ephemeris(1).para(activeChannel.BDS(2,i)).eph.Alpha1, ...
           ephemeris(1).para(activeChannel.BDS(2,i)).eph.Alpha2,ephemeris(1).para(activeChannel.BDS(2,i)).eph.Alpha3];
    Beta_i.BDS =[ephemeris(1).para(activeChannel.BDS(2,i)).eph.Beta0,ephemeris(1).para(activeChannel.BDS(2,i)).eph.Beta1, ...
          ephemeris(1).para(activeChannel.BDS(2,i)).eph.Beta2,ephemeris(1).para(activeChannel.BDS(2,i)).eph.Beta3];         
    %--- Update equations -----------------------------------------
    rho2 = (sat_xyz.BDS(1, activeChannel.BDS(2,i)) - pos(1))^2 + (sat_xyz.BDS(2, activeChannel.BDS(2,i)) - pos(2))^2 + ...
        (sat_xyz.BDS(3, activeChannel.BDS(2,i)) - pos(3))^2;%����i��α��ƽ��
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
    trop1 = Tropospheric(T_amb,P_amb,P_vap,el.BDS(1,i));
    trop2 =Ionospheric_BD(Lat,Lon,el.BDS(1,i),az.BDS(1,i),Alpha_i.BDS,Beta_i.BDS,transmitTime.BDS(activeChannel.BDS(2,i)),Rot_X.BDS(:,activeChannel.BDS(2,i)));
    trop_BDS = trop1 + trop2;

    
    %-
    if ismember(activeChannel.BDS(2,i), posiChannel.BDS(2,:))
        if pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,i), 2) ~= 0 
            deltaP = pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,i),1) - pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,i),2);   %���ֶ�����һ��ı仯����m��
        else
            deltaP = -299792458/1561098000*pvtCalculator.BDS.doppSmooth(activeChannel.BDS(2,i),4);    % ������Ƶ�ƣ�m��
        end
        useNum_BDS = useNum_BDS + 1;
        elUse_BDS(useNum_BDS) = el.BDS(1,i);
        obsKalman(2*useNum_BDS-1,1) = obs.BDS(activeChannel.BDS(2,i)) - trop_BDS;   % �������˲��е�α��۲�ֵ
        obsKalman(2*useNum_BDS,1) = [(-(Rot_X.BDS(1, activeChannel.BDS(2,i)) - pos(1))) / norm(Rot_X.BDS(:, activeChannel.BDS(2,i)) - pos(1:3), 'fro') ...
                                    (-(Rot_X.BDS(2, activeChannel.BDS(2,i)) - pos(2))) / norm(Rot_X.BDS(:, activeChannel.BDS(2,i)) - pos(1:3), 'fro') ...
                                    (-(Rot_X.BDS(3, activeChannel.BDS(2,i)) - pos(3))) / norm(Rot_X.BDS(:, activeChannel.BDS(2,i)) - pos(1:3), 'fro')]*satVel.BDS(:,activeChannel.BDS(2,i))...
                                    + deltaP + 299792458*satClkCorr.BDS(2,activeChannel.BDS(2,i)); % �������˲��еĶ�����Ƶ�ƹ۲�ֵ
        satKalman(useNum_BDS,1:3) = Rot_X.BDS(:,activeChannel.BDS(2,i))';     % �������˲��е�����λ��     N-by-6
        satKalman(useNum_BDS,4:6) = satVel.BDS(:,activeChannel.BDS(2,i))';
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
    %--- Update equations -----------------------------------------
    rho2 = (sat_xyz.GPS(1, activeChannel.GPS(2,i)) - pos(1))^2 + (sat_xyz.GPS(2, activeChannel.GPS(2,i)) - pos(2))^2 + ...
        (sat_xyz.GPS(3, activeChannel.GPS(2,i)) - pos(3))^2;%����i��α��ƽ��
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
    %--- Calculate tropospheric correction --------------------
    trop1 = Tropospheric(T_amb,P_amb,P_vap,el.GPS(1,i));
    trop2 =Ionospheric_GPS(Lat,Lon,el.GPS(1,i),az.GPS(1,i),Alpha_i.GPS,Beta_i.GPS,transmitTime.GPS(activeChannel.GPS(2,i)));
    trop_GPS = trop1 + trop2;
    if ismember(activeChannel.GPS(2,i), posiChannel.GPS(2,:))
        if pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,i), 2) ~= 0 
            deltaP = pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,i),1) - pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,i),2);   %���ֶ�����һ��ı仯����m��
        else
            deltaP = -299792458/1575420000*pvtCalculator.GPS.doppSmooth(activeChannel.GPS(2,i),4);    % ������Ƶ�ƣ�m��
        end
        useNum_GPS = useNum_GPS + 1;
        elUse_GPS(useNum_GPS) = el.GPS(1,i);
        obsKalman(2*useNum_BDS+2*useNum_GPS-1, 1) = obs.GPS(activeChannel.GPS(2,i)) - trop_GPS;   % �������˲��е�α��۲�ֵ
        obsKalman(2*useNum_BDS+2*useNum_GPS, 1) = [(-(Rot_X.GPS(1, activeChannel.GPS(2,i)) - pos(1))) / norm(Rot_X.GPS(:, activeChannel.GPS(2,i)) - pos(1:3), 'fro') ...
                                    (-(Rot_X.GPS(2, activeChannel.GPS(2,i)) - pos(2))) / norm(Rot_X.GPS(:, activeChannel.GPS(2,i)) - pos(1:3), 'fro') ...
                                    (-(Rot_X.GPS(3, activeChannel.GPS(2,i)) - pos(3))) / norm(Rot_X.GPS(:, activeChannel.GPS(2,i)) - pos(1:3), 'fro')]*satVel.GPS(:,activeChannel.GPS(2,i))...
                                    + deltaP + 299792458*satClkCorr.GPS(2,activeChannel.GPS(2,i)); % �������˲��еĶ�����Ƶ�ƹ۲�ֵ
        satKalman(useNum_BDS+useNum_GPS,1:3) = Rot_X.GPS(:,activeChannel.GPS(2,i))';     % �������˲��е�����λ��     N-by-6
        satKalman(useNum_BDS+useNum_GPS,4:6) = satVel.GPS(:,activeChannel.GPS(2,i))';
    end
end        

        
       
% satUsed = posiChannel(2,:);  % ����λ�����ٶȽ�������Ǻ�
% bEsti = omc - A/(A'*A)*A'*omc;    % �������
% WSSE = (norm(bEsti))^2;         % �����ֵ
% if WSSE < chi2inv(0.99999, size(A,1)-4)     % ����ж��д������ǣ��򲻾����������ж�
%     for j= useNum:-1:1  %ȥ�����ǵ���elevationMask������
%          if elUse(j) < elevationMask            
%              if size(A,1) >= 4
%                  satUsed(j)=[];
%              end
%          end
%     end
% end
          
[X,P] = EKF_dual(Q,R,obsKalman,X,P,satKalman,T,posiChannel,useNum_BDS);

pvtCalculator.kalman.state = X;     % ״̬����  N-by-1
pvtCalculator.kalman.P = P;         % Э�������
pos = X([1,3,5,7,9]);
vel = X([2,4,6,8,10]);
posvel = [pos',vel'];



