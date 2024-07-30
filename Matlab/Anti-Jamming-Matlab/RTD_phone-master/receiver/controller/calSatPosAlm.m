%% This function is used to calculate satellite's positions during warm start through almanac info.
function [sat_position] = calSatPosAlm(SYST, refTime, alm, prnNum)

% Initial
OMEGA_dot = 7.292115e-5; % CGS2000����ϵ�µĵ�����ת����(rad/s)
GM = 3.986004418e14; % CGS2000����ϵ�µĵ�����������(m^3/s^2)
pi = 3.1415926535898;
% F = -4.442807633e-10; % Constant, [sec/(meter)^(1/2)]


sat_position = zeros(6, 1);

toa = alm.toa; % �����ο�ʱ��
sqrtA = alm.sqrtA; % �������ƽ����
e = alm.e; % ƫ����
omega = alm.omega; % ���ص����
deltai = alm.deltai; % �ο�ʱ��Ĺ���ο���ǵĸ�����
M0 = alm.M0; % �ο�ʱ���ƽ�����
omega0 = alm.omega0; % ���ο�ʱ�����������㾭��
omegaDot = alm.omegaDot; % OMEGA_DOT%�����㾭�ȱ仯��
switch SYST
    case 'BDS_B1I'
        if prnNum > 5
            i0 = 0.3 * pi; % �ο�ʱ��Ĺ�����
        else
            i0 = 0;
        end
    case 'GPS_L1CA'
        i0 = 0.3 * pi;
end

% Find sat position
A = sqrtA ^ 2; % ����볤��
tk = check_t(refTime - toa); % ʱ��У��
n = (GM / A ^ 3) ^ 0.5; % ��������ƽ�����ٶ�

M = M0 + n * tk;
M = rem(M + 2 * pi, 2 * pi);

E = M;
% Iteratively compute eccentric anomaly
for ii = 1:10
    Eold = E;
    E = M + e * sin(E);
    dE = rem(E - Eold, 2 * pi);

    if abs(dE) < 1.e-12
        % Necessary precision is reached, exit from the loop
        break;
    end
end

E = rem(E + 2 * pi, 2 * pi);

v_k = atan2(sqrt(1 - e ^ 2) * sin(E), cos(E) - e);
% ����γ�ȷ��ǲ���
phi_k = v_k + omega;
% Reduce phi to between 0 and 360 deg
phi_k = rem(phi_k, 2 * pi);


% ���������ľ���
r_k = A * (1 - e * cos(E));

% ���������ڹ��ƽ���ڵ�����
x_k = r_k .* cos(phi_k);
y_k = r_k .* sin(phi_k);

% ������Ԫ������ľ��ȣ��ع�ϵ��������MEO/IGSO������CGS2000����ϵ�е�����
OMEGA_k = omega0 + (omegaDot - OMEGA_dot) * tk - OMEGA_dot * toa;
%     i_k = i0 + deltai;
i_k = deltai + i0;
X_k = x_k .* cos(OMEGA_k) - y_k .* cos(i_k) .* sin(OMEGA_k);
Y_k = x_k .* sin(OMEGA_k) + y_k .* cos(i_k) .* cos(OMEGA_k);
Z_k = y_k .* sin(i_k);
sat_position(1:3) = [X_k; Y_k; Z_k];

switch SYST
    case 'BDS_B1I'
        if prnNum > 5
            % Start calculate velocity
            % 1.����E�ĵ���,����ȫ�����±�1��ʾ��E1
            E1 = n/(1-e*cos(E));
            % 2.����phi_k�ĵ���phi_k1��phi_k1=v_k1
            phi_k1 = sqrt(1-e*e)*E1/(1-e*cos(E));
            % 3.����delta_u_k1��delta_r_k1��delta_i_k1
            % delta_u_k1 = 2*phi_k1*(Cus*cos(2*phi_k)-Cuc*sin(2*phi_k));
            % delta_r_k1 = 2*phi_k1*(Crs*cos(2*phi_k)-Crc*sin(2*phi_k));
            % delta_i_k1 = 2*phi_k1*(Cis*cos(2*phi_k)-Cic*sin(2*phi_k));
            % 4.����u_k1, r_k1, i_k1, OMEGA_k1
            u_k1 = phi_k1 ;
            r_k1 = A*e*E1*sin(E) ;
            i_k1 = 0;
            OMEGA_k1 = omegaDot-OMEGA_dot;
            % 5.����x_k1, y_k1
            x_k1 = r_k1*cos(phi_k) - r_k*u_k1*sin(phi_k);
            y_k1 = r_k1*sin(phi_k) + r_k*u_k1*cos(phi_k);
            % 6.����X_k1, Y_k1, Z_k1��vx, vy, vz
            X_k1 = -Y_k*OMEGA_k1-(y_k1*cos(i_k)-Z_k*i_k1)*sin(OMEGA_k)+x_k1*cos(OMEGA_k);
            Y_k1 = X_k*OMEGA_k1+(y_k1*cos(i_k)-Z_k*i_k1)*cos(OMEGA_k)+x_k1*sin(OMEGA_k);
            Z_k1 = y_k1*sin(i_k) + y_k*i_k1*cos(i_k);
            sat_position(4:6) = [X_k1; Y_k1; Z_k1];
%         [az, el, dist] = topocent(refPos, sat_position -refPos);
        else
            sat_position(4:6) = [0; 0; 0]; % GEO satellite
        end

    case 'GPS_L1CA'
        % Start calculate velocity
        % 1.����E�ĵ���,����ȫ�����±�1��ʾ��E1
        E1 = n/(1-e*cos(E));
        % 2.����phi_k�ĵ���phi_k1��phi_k1=v_k1
        phi_k1 = sqrt(1-e*e)*E1/(1-e*cos(E));
        % 3.����delta_u_k1��delta_r_k1��delta_i_k1
        % delta_u_k1 = 2*phi_k1*(Cus*cos(2*phi_k)-Cuc*sin(2*phi_k));
        % delta_r_k1 = 2*phi_k1*(Crs*cos(2*phi_k)-Crc*sin(2*phi_k));
        % delta_i_k1 = 2*phi_k1*(Cis*cos(2*phi_k)-Cic*sin(2*phi_k));
        % 4.����u_k1, r_k1, i_k1, OMEGA_k1
        u_k1 = phi_k1 ;
        r_k1 = A*e*E1*sin(E) ;
        i_k1 = 0;
        OMEGA_k1 = omegaDot-OMEGA_dot;
        % 5.����x_k1, y_k1
        x_k1 = r_k1*cos(phi_k) - r_k*u_k1*sin(phi_k);
        y_k1 = r_k1*sin(phi_k) + r_k*u_k1*cos(phi_k);
        % 6.����X_k1, Y_k1, Z_k1��vx, vy, vz
        X_k1 = -Y_k*OMEGA_k1-(y_k1*cos(i_k)-Z_k*i_k1)*sin(OMEGA_k)+x_k1*cos(OMEGA_k);
        Y_k1 = X_k*OMEGA_k1+(y_k1*cos(i_k)-Z_k*i_k1)*cos(OMEGA_k)+x_k1*sin(OMEGA_k);
        Z_k1 = y_k1*sin(i_k) + y_k*i_k1*cos(i_k);
        sat_position(4:6) = [X_k1; Y_k1; Z_k1];

%             [~, el(prnNum), ~] = topocent(refPos, sat_position -refPos);
end



end