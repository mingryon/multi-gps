function [satPositions, satClkCorr] = calculateSatPosition_BD(transmitTime, channels, activeChannel)

% initial 
for i = 1:length(activeChannel)
    prnList(i) = channels(activeChannel(i)).CH_B1I(1).PRNID;
    eph(prnList(i)) = channels(activeChannel(i)).CH_B1I(1).eph;
end

numOfSatellites = size(prnList, 2);
%miu=3.986004418e14;%CGS2000����ϵ�µĵ�����������(m^3/s^2) 
OMEGA_dot=7.292115e-5;%CGS2000����ϵ�µĵ�����ת����(rad/s)
GM=3.986004418e14;%CGS2000����ϵ�µĵ�����������(m^3/s^2)
pi=3.1415926535898;
F = -4.442807633e-10; % Constant, [sec/(meter)^(1/2)]
%%%% for test
%transmitTime = time;
%%%%
for satNr = 1 : numOfSatellites

    prn = prnList(satNr);

toe=eph(prn).toe;%�����ο�ʱ��
sqrtA=eph(prn).sqrtA;%�������ƽ����
e=eph(prn).e;%ƫ����
w=eph(prn).w;%���ص����
deltan=eph(prn).deltan;%����ƽ���˶����������ֵ֮��
M0=eph(prn).M0;%�ο�ʱ���ƽ�����
omega0=eph(prn).omega0;%���ο�ʱ�����������㾭��
omega=eph(prn).omega;%OMEGA_DOT%�����㾭�ȱ仯��
i0=eph(prn).i0;%�ο�ʱ��Ĺ�����
iDot=eph(prn).iDot;%�����Ǳ仯��
Cuc=eph(prn).Cuc;%γ�ȷ��ǵ����ҵ��͸���������
Cus=eph(prn).Cus;%γ�ȷ��ǵ����ҵ��͸���������
Crc=eph(prn).Crc;%����뾶�����ҵ��͸���������
Crs=eph(prn).Crs;%����뾶�����ҵ��͸���������
Cic=eph(prn).Cic;%�����ǵ����ҵ��͸���������
Cis=eph(prn).Cis;%�����ǵ����ҵ��͸���������

toc=eph(prn).toe; %!!!!!!!!!!!!!!!!!causion
a0=eph(prn).a0;  
a1=eph(prn).a1; 
a2=eph(prn).a2; 
%transmitTime=eph(prn).SOW;
TGD1=eph(prn).TGD1;
%% find initial satellite clock correction 
%%%%%%%%��������ʱ��
dt = check_t(transmitTime(satNr)-toc);
% dt = check_t(transmitTime-toc);
%%%%%%�������ǲ������λʱ��ƫ��
satClkCorr(satNr) = a0+(a1+a2*dt)*dt-TGD1;
%%%%%%%%%���������У����
%%%%%%%%%%%%%%%%�����źŷ���ʱ��ϵͳʱ��
time = transmitTime(satNr) - satClkCorr(satNr);
%% find sat position
%����볤��
A=sqrtA^2;
%ʱ��У��
tk  = check_t(time - toe);
%��������ƽ�����ٶ�
n0=(GM/A^3)^0.5;
%����۲���Ԫ���ο���Ԫ��ʱ���
%t_k=t-toe;%t?
%����ƽ�����ٶ�
n=n0+deltan;
%����ƽ�����
% if t-toe>302400;
%     t=t-604800;
% else if t-toe<-302400;
%     t=t+604800;
%     end
% end
%t_k=t-toe;
%M_k=M0+n*t_k;
M=M0+n*tk;
M   = rem(M + 2*pi, 2*pi);

%��������ƫ�����,��Խ����
%Eold=M_k;
% error=1;
% while error>1e-12;
%     E=M_k-e*sin(Eold);
%     error=abs(E-Eold);
%     Eold= E;
% end
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
%ʱ������
%�����������
dtr = F*e*sqrtA * sin(E);
%��ʱ��������
% t_k=transmitTime-toe;
% dt=a0+(a1+a2)*t_k+dtr-TGD1;
% transmitTime=transmitTime-dt;
%%%����
%t=t-TGD1;
%%%%%
%t_k=t-toe;
%����������
%v_k2=asin(((1-e^2)^0.5*sin(E))/(1-e*cos(E)));
%v_k1=acos((cos(E)-e)/(1-e*cos(E)));
%v_k=v_k1*sign(v_k2);

v_k   = atan2(sqrt(1 - e^2) * sin(E), cos(E)-e);
%����γ�ȷ��ǲ���
phi_k=v_k+w;
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
%% GEO
if prn <=5 ;
%������Ԫ������ľ��ȣ�����ϵ��������GEO�������Զ������ϵ�е�����
OMEGA_k=omega0+omega*tk-OMEGA_dot*toe;
X_k=x_k.*cos(OMEGA_k)-y_k.*cos(i_k).*sin(OMEGA_k);
Y_k=x_k.*sin(OMEGA_k)+y_k.*cos(i_k).*cos(OMEGA_k);
Z_k=y_k.*sin(i_k);
%����GEO������CGS2000����ϵ�е�����
%[X_GK;Y_GK;Z_GK] = R_Z(OMEGA_dot*tk)*R_X(-5)*[X_k;Y_k;Z_k];%-5��
%positon=R_Z(OMEGA_dot*tk)*R_X(-5)*[X_k;Y_k;Z_k];%-5��
position=[cos(OMEGA_dot*tk) sin(OMEGA_dot*tk) ...
    0;-sin(OMEGA_dot*tk) cos(OMEGA_dot*tk) 0;0 0 1]*[1 ...
    0 0;0 cos(-pi/36) sin(-pi/36);0 -sin(-pi/36) cos(-pi/36)]*[X_k;Y_k;Z_k];%-5��
X_GK=position(1);
Y_GK=position(2);
Z_GK=position(3);
%NGEO(satNr)
else
%������Ԫ������ľ��ȣ��ع�ϵ��������MEO/IGSO������CGS2000����ϵ�е�����
OMEGA_k=omega0+(omega-OMEGA_dot)*tk-OMEGA_dot*toe;
X_k=x_k.*cos(OMEGA_k)-y_k.*cos(i_k).*sin(OMEGA_k);
Y_k=x_k.*sin(OMEGA_k)+y_k.*cos(i_k).*cos(OMEGA_k);
Z_k=y_k.*sin(i_k);
position = [X_k;Y_k;Z_k];
end
%%
satPositions(1, satNr) = position(1);
satPositions(2, satNr) = position(2);
satPositions(3, satNr) = position(3);
% satPositions(4, satNr) = 0;
% satPositions(5, satNr) = 0;
% satPositions(6, satNr) = 0;
%% calculate velocity of NGEO satellite
if prn > 5
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
r_k1 = A*e*E1*sin(E) + delta_u_k1;
i_k1 = iDot + delta_i_k1;
OMEGA_k1 = omega-OMEGA_dot;
%5.����x_k1,y_k1
x_k1 = r_k1*cos(u_k) - r_k*u_k1*sin(u_k);
y_k1 = r_k1*sin(u_k) + r_k*u_k1*cos(u_k);
%6.����X_k1,Y_k1,Z_k1��vx,vy,vz
X_k1 = -Y_k*OMEGA_k1-(y_k1*cos(i_k)-Z_k*i_k1)*sin(OMEGA_k)+x_k1*cos(OMEGA_k);
Y_k1 = X_k*OMEGA_k1+(y_k1*cos(i_k)-Z_k*i_k1)*cos(OMEGA_k)+x_k1*sin(OMEGA_k);
Z_k1 = y_k1*sin(i_k) + y_k*i_k1*cos(i_k);
%==============finish calculate velocity==========================
satPositions(4, satNr) = X_k1;
satPositions(5, satNr) = Y_k1;
satPositions(6, satNr) = Z_k1;
else
  satPositions(4, satNr) = 0;
  satPositions(5, satNr) = 0;
  satPositions(6, satNr) = 0;
end
%%
%R_X(phi)=[1 0 0;0 cos(-5) sin(-5);0 -sin(-5) cos(-5)];
%R_Z(phi)=[cos(OMEGA_dot*tk) sin(OMEGA_dot*tk) ...
 %   0;-sin(OMEGA_dot*tk) cos(OMEGA_dot*tk) 0;0 0 1];
%R_X(phi)=[1 0 0;0 cos(phi) sin(phi);0 -sin(phi) cos(phi)];
%R_Z(phi)=[cos(phi) sin(phi) 0;-sin(phi) cos(phi) 0;0 0 1];

%����ʽ�У�t���źŷ���ʱ�̵�BD-2ϵͳʱ�䣬Ҳ���ǶԴ���ʱ���������BD-2ϵͳ����ʱ�䣨����/���٣���
%��ˣ�t_k����BD-2ϵͳʱ��t�������ο�ʱ��toe֮�����ʱ���������˿��һ�ܿ�ʼ�������ʱ�䣬
%Ҳ���ǣ����t_k>302400ʱ���ʹ�t_k�м�ȥ604800�������t_k<-302400ʱ���Ͷ�t_k�м���604800
%satposition(satNr)=[X_GK;Y_GK;Z_GK];
satClkCorr(satNr)=a0+(a1+a2*tk)*tk+dtr-TGD1;
end

end