function [posvel,el,az,dop,pvtCalculator] = kalmanPosiStaticMP_BDS(satpos, obs,Beijing_Time,ephemeris,activeChannel, ...
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
Sf = 25;
Sg = 0.01;
sigma=3;         %state transition variance
Qb = [Sf*T+Sg*T*T*T/3, Sg*T*T/2; Sg*T*T/2, Sg*T];
Qxyz = sigma^2 * T;
Q = blkdiag(Qxyz, Qxyz, Qxyz, Qb);
% ������������Set R����������������%
Rhoerror = [49,0;0,0.01];  % variance of measurement error(pseudorange error)
R = [];
for ii = 1:size(posiChannel,2)
    R = blkdiag(R, Rhoerror); 
end

X_static = pvtCalculator.kalman.state_static;     % ״̬����  N-by-1    ��̬ģ��ֻ����λ�ú��Ӳ�
P_static = pvtCalculator.kalman.P_static;         % ���Э�������
%�����������������������˲����¡���������������%
%=== Initialization =======================================================
%nmbOfIterations = 11;
dop     = zeros(1, 5);
pos     = X_static([1,2,3,4]);
vel = zeros(4,1); %calculate velocity and ddt
sat_xyz = satpos(1:3,:);
satVel = satpos(4:6,:);
nmbOfSatellites = size(activeChannel, 2);
Rot_X   = zeros(3,30);%%����������ת�����������λ��
%A       = zeros(size(posiChannel,2), 4);
%raimG = zeros(size(posiChannel,2), 4);  % raim �㷨��ʹ��
%omc     = zeros(size(posiChannel,2), 1);    
%raimB = zeros(size(posiChannel,2), 1);    % raim �㷨��ʹ��
az.BDS      = zeros(3, nmbOfSatellites);
el.BDS      = az.BDS;
az.BDS(2,:)=activeChannel(2,:);    %���������ֵ�����ǵ�prn�����Ӧ
el.BDS(2,:)=activeChannel(2,:);
az.BDS(3,:)=activeChannel(1,:);    %���������ֵ�����ǵ�prn�����Ӧ
el.BDS(3,:)=activeChannel(1,:);
az.GPS = [];
el.GPS = [];
%prError = [];   % ����һʱ�̶�λ�����α��в�
elUse = [];     % ʹ�����ǵ�����
%---
T_amb = 20;%20
P_amb = 101.325; %KPa
P_vap = .849179;%.86; 0.61078*(H/100)*exp(T/(T+238.3)*17.2694) KPa
posvel = zeros(1, 10);

%if length(activeChannel(1,:))>=4 && checkNGEO==1
    %=== Iteratively find receiver position ===================================
%    for iter = 1:nmbOfIterations
useNum = 0;     % ʹ�����ǵ���Ŀ//ÿ�ε�����Ҫ����
for i = 1:nmbOfSatellites         
    Alpha_i =[ephemeris(activeChannel(2,i)).eph.Alpha0,ephemeris(activeChannel(2,i)).eph.Alpha1, ...
            ephemeris(activeChannel(2,i)).eph.Alpha2,ephemeris(activeChannel(2,i)).eph.Alpha3];
    Beta_i =[ephemeris(activeChannel(2,i)).eph.Beta0,ephemeris(activeChannel(2,i)).eph.Beta1, ...
            ephemeris(activeChannel(2,i)).eph.Beta2,ephemeris(activeChannel(2,i)).eph.Beta3];        
    %--- Update equations -----------------------------------------
    rho2 = (sat_xyz(1, activeChannel(2,i)) - pos(1))^2 + (sat_xyz(2, activeChannel(2,i)) - pos(2))^2 + ...
        (sat_xyz(3, activeChannel(2,i)) - pos(3))^2;%����i��α��ƽ��
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
    trop1 = Tropospheric(T_amb,P_amb,P_vap,el.BDS(1,i));
    trop2 =Ionospheric_BD(Lat,Lon,el.BDS(1,i),az.BDS(1,i),Alpha_i,Beta_i,Beijing_Time(activeChannel(2,i)),Rot_X(:,activeChannel(2,i)));
    trop = trop1 + trop2;
    if ismember(activeChannel(2,i), posiChannel(2,:))
        if pvtCalculator.BDS.doppSmooth(activeChannel(2,i), 2) ~= 0 
            deltaP = pvtCalculator.BDS.doppSmooth(activeChannel(2,i),1) - pvtCalculator.BDS.doppSmooth(activeChannel(2,i),2);   %���ֶ�����һ��ı仯����m��
        else
            deltaP = -299792458/1561098000*pvtCalculator.BDS.doppSmooth(activeChannel(2,i),4);    % ������Ƶ�ƣ�m��
        end
        useNum = useNum + 1;
        obsKalman(2*useNum-1,1) = obs(activeChannel(2,i)) - trop;   % �������˲��е�α��۲�ֵ
        obsKalman(2*useNum,1) = [(-(Rot_X(1, activeChannel(2,i)) - pos(1))) / norm(Rot_X(:, activeChannel(2,i)) - pos(1:3), 'fro') ...
                                    (-(Rot_X(2, activeChannel(2,i)) - pos(2))) / norm(Rot_X(:, activeChannel(2,i)) - pos(1:3), 'fro') ...
                                    (-(Rot_X(3, activeChannel(2,i)) - pos(3))) / norm(Rot_X(:, activeChannel(2,i)) - pos(1:3), 'fro')]*satVel(:,activeChannel(2,i))...
                                    + deltaP + 299792458*satClkCorr(activeChannel(2,i)); % �������˲��еĶ�����Ƶ�ƹ۲�ֵ
        satKalman(useNum,1:3) = Rot_X(:,activeChannel(2,i))';     % �������˲��е�����λ��     N-by-6
        satKalman(useNum,4:6) = satVel(:,activeChannel(2,i))';
        elUse(useNum) = el.BDS(1,i);
    end
end % for i = 1:nmbOfSatellites
        
       
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
          
[X_static,P_static] = EKF_static(Q,R,obsKalman,X_static,P_static,satKalman,T,posiChannel);


%�������������������˲����״̬��ֵ��������������������%
pvtCalculator.kalman.state_static = X_static;     % ״̬����  N-by-1
pvtCalculator.kalman.P_static = P_static;         % Э�������
pos = X_static([1,2,3,4]);
%vel = X_static([2,4,6,8]);
posvel = [pos',0,0,0,0,0,0];



