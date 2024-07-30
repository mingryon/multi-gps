function [az,el] = BD_calculateSatPosition_almanac(time,prn_num,almanac,antenna_position)

% initial 

    
    alm = almanac.alm(prn_num).para;


%miu=3.986004418e14;%CGS2000����ϵ�µĵ�����������(m^3/s^2) 
OMEGA_dot=7.292115e-5;%CGS2000����ϵ�µĵ�����ת����(rad/s)
GM=3.986004418e14;%CGS2000����ϵ�µĵ�����������(m^3/s^2)
pi=3.1415926535898;
F = -4.442807633e-10; % Constant, [sec/(meter)^(1/2)]
%%%% for test
%transmitTime = time;
%%%%


    

toa=alm.toa;%�����ο�ʱ��
sqrtA=alm.sqrtA;%�������ƽ����
e=alm.e;%ƫ����
w=alm.w;%���ص����
deltan=alm.deltan;%����ƽ���˶����������ֵ֮��
M0=alm.M0;%�ο�ʱ���ƽ�����
omega0=alm.omega0;%���ο�ʱ�����������㾭��
omega=alm.omega;%OMEGA_DOT%�����㾭�ȱ仯��
if prn_num>5
    i0=0.3*pi;%�ο�ʱ��Ĺ�����
else
    i0=0;
end


% % a0=alm(ii).a0;  
% % a1=alm(ii).a1; 


%% find initial satellite clock correction 

%% find sat position
%����볤��
A=sqrtA^2;
%ʱ��У��
tk  = check_t(time - toa);
%��������ƽ�����ٶ�
n=(GM/A^3)^0.5;

M=M0+n*tk;
M   = rem(M + 2*pi, 2*pi);


E=M;
  %--- Iteratively compute eccentric anomaly ----------------------------
    for ii = 1:10
        Eold   = E;
        E       = M + e * sin(E);
        dE      = rem(E - Eold, 2*pi);

        if abs(dE) < 1.e-12
            % Necessary precision is reached, exit from the loop
            break;
        end
    end
 
E   = rem(E + 2*pi, 2*pi);
%M_k=E-e*sin(E);




v_k   = atan2(sqrt(1 - e^2) * sin(E), cos(E)-e);
%����γ�ȷ��ǲ���
phi_k=v_k+w;
%Reduce phi to between 0 and 360 deg
phi_k = rem(phi_k, 2*pi);


%���������ľ���
r_k=A*(1-e*cos(E));

%���������ڹ��ƽ���ڵ�����
x_k=r_k.*cos(phi_k);
y_k=r_k.*sin(phi_k);

%������Ԫ������ľ��ȣ��ع�ϵ��������MEO/IGSO������CGS2000����ϵ�е�����
OMEGA_k=omega0+(omega-OMEGA_dot)*tk-OMEGA_dot*toa;
i_k=i0+deltan;
X_k=x_k.*cos(OMEGA_k)-y_k.*cos(i_k).*sin(OMEGA_k);
Y_k=x_k.*sin(OMEGA_k)+y_k.*cos(i_k).*cos(OMEGA_k);
Z_k=y_k.*sin(i_k);
sat_position = [X_k;Y_k;Z_k];
% % end


if prn_num > 5
%==============start calculate velocity===========================
%1.����E�ĵ���,����ȫ�����±�1��ʾ��E1
E1 = n/(1-e*cos(E));
%2.����phi_k�ĵ���phi_k1��phi_k1=v_k1
phi_k1 = sqrt(1-e*e)*E1/(1-e*cos(E));
%3.����delta_u_k1��delta_r_k1��delta_i_k1
% delta_u_k1 = 2*phi_k1*(Cus*cos(2*phi_k)-Cuc*sin(2*phi_k));
% delta_r_k1 = 2*phi_k1*(Crs*cos(2*phi_k)-Crc*sin(2*phi_k));
% delta_i_k1 = 2*phi_k1*(Cis*cos(2*phi_k)-Cic*sin(2*phi_k));
%4.����u_k1,r_k1,i_k1,OMEGA_k1
u_k1 = phi_k1 ;
r_k1 = A*e*E1*sin(E) ;
i_k1 = iDot ;
OMEGA_k1 = omega-OMEGA_dot;
%5.����x_k1,y_k1
x_k1 = r_k1*cos(phi_k) - r_k*u_k1*sin(phi_k);
y_k1 = r_k1*sin(phi_k) + r_k*u_k1*cos(phi_k);
%6.����X_k1,Y_k1,Z_k1��vx,vy,vz
X_k1 = -Y_k*OMEGA_k1-(y_k1*cos(i_k)-Z_k*i_k1)*sin(OMEGA_k)+x_k1*cos(OMEGA_k);
Y_k1 = X_k*OMEGA_k1+(y_k1*cos(i_k)-Z_k*i_k1)*cos(OMEGA_k)+x_k1*sin(OMEGA_k);
Z_k1 = y_k1*sin(i_k) + y_k*i_k1*cos(i_k);
% satPositions(4, satNr) = 0;
% satPositions(5, satNr) = 0;
% satPositions(6, satNr) = 0;
%%

[az, el, dist] = topocent(antenna_position, sat_position -antenna_position);
end


