function [satPositions, satClkCorr] = gpsl1ca_calc_OneSatPosition(transmitTime, eph)

satPositions = zeros(6,1);

% GPS sat orbit constants
F = -4.442807633e-10; % Constant, [sec/(meter)^(1/2)]
GM = 3.986005e14; % [m^3/sec^2] Earth's universal gravitational parameter
C = 2.99792458e8; % [m/sec] speed of light
OMEGA_dot=7.2921151467e-5;%WGS84����ϵ�µĵ�����ת����(rad/s)
% GM=3.986004418e14;%CGS2000����ϵ�µĵ�����������(m^3/s^2)

% sat orbit parameters
toe=eph.toe;%�����ο�ʱ��
sqrtA=eph.sqrtA;%�������ƽ����
e=eph.e;%ƫ����
omega=eph.omega;%���ص����
deltan=eph.deltan;%����ƽ���˶����������ֵ֮��
M0=eph.M0;%�ο�ʱ���ƽ�����
omega0=eph.omega0;%���ο�ʱ�����������㾭��
omega_dot=eph.omegaDot;%OMEGA_DOT%�����㾭�ȱ仯��
i0=eph.i0;%�ο�ʱ��Ĺ�����
iDot=eph.iDot;%�����Ǳ仯��
Cuc=eph.Cuc;%γ�ȷ��ǵ����ҵ��͸���������
Cus=eph.Cus;%γ�ȷ��ǵ����ҵ��͸���������
Crc=eph.Crc;%����뾶�����ҵ��͸���������
Crs=eph.Crs;%����뾶�����ҵ��͸���������
Cic=eph.Cic;%�����ǵ����ҵ��͸���������
Cis=eph.Cis;%�����ǵ����ҵ��͸���������
    
toc=eph.toc; %!!!!!!!!!!!!!!!!!causion
a0=eph.af0;
a1=eph.af1;
a2=eph.af2;
%transmitTime=eph.SOW;
TGD1=eph.TGD;

%% find initial satellite clock correction
%��������ʱ��
dt = check_t(transmitTime-toc);
%�������ǲ������λʱ��ƫ��
satClkCorr = a0+(a1+a2*dt)*dt-TGD1;

%���������У����
%�����źŷ���ʱ��ϵͳʱ��
time = transmitTime - satClkCorr;

%% find sat position
%����볤��
A=sqrtA^2;
%����۲���Ԫ���ο���Ԫ��ʱ���,��ʱ��У��
tk  = check_t(time - toe);
%��������ƽ�����ٶ�
n0=(GM/A^3)^0.5;
%����ƽ�����ٶ�
n=n0+deltan;
%����ƽ�����
M=M0+n*tk;
M   = rem(M + 2*pi, 2*pi);
    
%��������ƫ�����,��Խ����
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
%ʱ������
%�����������
dtr = F*e*sqrtA * sin(E);

%��ʱ��������
%%%%%%%%%%%����һ�η����ٴμ���%%%%%%%%%%
satClkCorr=a0+(a1+a2*dt)*dt+dtr-TGD1;
time = transmitTime - satClkCorr;
%ʱ��У��
tk  = check_t(time - toe);
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

v_k   = atan2(sqrt(1 - e^2) * sin(E), cos(E)-e);
%����γ�ȷ��ǲ���
phi_k=v_k+omega;
%Reduce phi to between 0 and 360 deg
phi_k = rem(phi_k, 2*pi);
%�������ڸ����γ�ȷ��Ǹ�����������������Ǹ�����
delta_u_k=Cus*sin(2*phi_k)+Cuc*cos(2*phi_k);
delta_r_k=Crs*sin(2*phi_k)+Crc*cos(2*phi_k);
delta_i_k=Cis*sin(2*phi_k)+Cic*cos(2*phi_k);
%����������γ�Ȳ���
u_k=phi_k+delta_u_k;
%���������ľ���
r_k=A*(1-e*cos(E))+delta_r_k;
%�������������
i_k=i0+iDot*tk+delta_i_k;
%���������ڹ��ƽ���ڵ�����
x_k=r_k.*cos(u_k);
y_k=r_k.*sin(u_k);

%������Ԫ������ľ��ȣ��ع�ϵ��������MEO/IGSO������CGS2000����ϵ�е�����
OMEGA_k=omega0+(omega_dot-OMEGA_dot)*tk-OMEGA_dot*toe;
X_k=x_k.*cos(OMEGA_k)-y_k.*cos(i_k).*sin(OMEGA_k);
Y_k=x_k.*sin(OMEGA_k)+y_k.*cos(i_k).*cos(OMEGA_k);
Z_k=y_k.*sin(i_k);
position = [X_k;Y_k;Z_k];

satPositions(1) = position(1);
satPositions(2) = position(2);
satPositions(3) = position(3);

%% calculate velocity of NGEO satellite
%==============start calculate velocity===========================
%1.����E�ĵ���,����ȫ�����±�1��ʾ��E1
E1 = n/(1-e*cos(E));
%2.����phi_k�ĵ���phi_k1��phi_k1=v_k1
phi_k1 = sqrt(1-e*e)*E1/(1-e*cos(E));
%3.����delta_u_k1��delta_r_k1��delta_i_k1
delta_u_k1 = 2*phi_k1*(Cus*cos(2*phi_k)-Cuc*sin(2*phi_k));
delta_r_k1 = 2*phi_k1*(Crs*cos(2*phi_k)-Crc*sin(2*phi_k));
delta_i_k1 = 2*phi_k1*(Cis*cos(2*phi_k)-Cic*sin(2*phi_k));
%4.����u_k1,r_k1,i_k1,OMEGA_k1
u_k1 = phi_k1 + delta_u_k1;
r_k1 = A*e*E1*sin(E) + delta_r_k1;
i_k1 = iDot + delta_i_k1;
OMEGA_k1 = omega_dot-OMEGA_dot;
%5.����x_k1,y_k1
x_k1 = r_k1*cos(u_k) - r_k*u_k1*sin(u_k);
y_k1 = r_k1*sin(u_k) + r_k*u_k1*cos(u_k);
%6.����X_k1,Y_k1,Z_k1��vx,vy,vz
X_k1 = -Y_k*OMEGA_k1-(y_k1*cos(i_k)-Z_k*i_k1)*sin(OMEGA_k)+x_k1*cos(OMEGA_k);
Y_k1 = X_k*OMEGA_k1+(y_k1*cos(i_k)-Z_k*i_k1)*cos(OMEGA_k)+x_k1*sin(OMEGA_k);
Z_k1 = y_k1*sin(i_k) + y_k*i_k1*cos(i_k);
%==============finish calculate velocity==========================
satPositions(4) = X_k1;
satPositions(5) = Y_k1;
satPositions(6) = Z_k1;

%%   
%���ʽ�У�t���źŷ���ʱ�̵�BD-2ϵͳʱ�䣬Ҳ���ǶԴ���ʱ���������BD-2ϵͳ����ʱ�䣨����/���٣���
%��ˣ�t_k����BD-2ϵͳʱ��t�������ο�ʱ��toe֮�����ʱ���������˿��һ�ܿ�ʼ�������ʱ�䣬
%Ҳ���ǣ����t_k>302400ʱ���ʹ�t_k�м�ȥ604800�������t_k<-302400ʱ���Ͷ�t_k�м���604800
%satposition(satNr)=[X_GK;Y_GK;Z_GK];
satClkCorr = zeros(2,1);
dtr = F*e*sqrtA * sin(E);
satClkCorr(1)=a0+(a1+a2*dt)*dt+dtr-TGD1;
dtr_dot = F*e*sqrtA * E1 * cos(E);
satClkCorr(2) = a1 + 2*a2*dt + dtr_dot;
    
end