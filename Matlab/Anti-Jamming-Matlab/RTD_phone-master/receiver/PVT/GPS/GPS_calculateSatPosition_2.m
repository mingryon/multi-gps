function [satPos, satClkCorr] = GPS_calculateSatPosition_2(transmitTime, ephemeris1, ephemeris2, chSyst)
% ��˫Ƶģʽ�£���������λ�á��ٶȺ��Ӳ�
% ephemeris1: NAV�������Ľṹ�壬 ephemeris2: CNAV���������ṹ��  clk: CNAVʱ�Ӳ���
% SYST:  GPS_L1CA/GPS_L1CA_L2C �������ͣ���Ƶ/˫Ƶ��

naviType = 0; %����ʱ�����������ͣ� 1��NAV�� 2��CNAV
satPos = zeros(6,1);   % X,Y,Z,Vx,Vy,Vz
satClkCorr = zeros(2,1); % 1λ�Ӳ 2ΪƵƮ

miu = 3.986005e14;           %CGS2000����ϵ�µĵ�����������(m^3/s^2)������CNAV
GM = 3.986004418e14;         %CGS2000����ϵ�µĵ�����������(m^3/s^2)
Omega_e_dot = 7.2921151467e-5; %������ת���ٶ�(rad/s)
Omega_dot_ref = -2.6e-9;     %������ת���ٶȲο�ֵ(semi-circles/second) - ����CNAV 
Pi = 3.1415926535898;
F = -4.442807633e-10;      % Constant, [sec/(meter)^(1/2)]
A_ref = 26559710;          %����볤���׼ֵ��meters)

%% ������ֵ
if strcmp('GPS_L1CA',chSyst)  %��Ƶ���Ǵ���
    eph = ephemeris1.eph;
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
    TGD1=eph.TGD;

    naviType = 1;
end

if strcmp('GPS_L1CA_L2C',chSyst)  %˫Ƶ���Ǵ���
    %>>>>>>>>>>��ʱ����CNAV����<<<<<<<<< 20170707   
    %ע�⣺ CNAV�Ĳ����ڽ��ʱ������ԭʼ��λ���˴�semi-circleȫ��ת����rad
%     if (ephemeris2.ephReady)  %��CNAV���ã�����ʹ��
%         eph = ephemeris2.eph;
%         t_oe = eph.t_oe_10;        %����/ʱ�Ӳο�ʱ��
%         Delta_A = eph.Delta_A;     %t_oe�볤��ƫ����
%         A_dot = eph.A_dot;         %�볤��仯��        
%         Delta_n0 = eph.Delta_n0*Pi;   %t_oeƽ���˶����ٶ�У��ֵ
%         Delta_n0_dot = eph.Delta_n0_dot*Pi;  %t_oeƽ���˶����ٶ�У��ֵ�仯��
%         M_0 = eph.M_0n*Pi;            %t_oeƽ�����
%         e = eph.e_n;               %���������
%         omega_n = eph.omega_n*Pi;       %������ؽǾ�
%         Omega_0 = eph.Omega_0n*Pi;    %SOW=0ʱ��������ྭ
%         Delta_Omega_dot = eph.Delta_Omega_dot*Pi; %���������ྭ�仯��ƫ����
%         i_0 = eph.i_0n*Pi;            %t_oe������
%         i_0_dot = eph.i_0n_dot*Pi;    %�����Ǳ仯��
%         Cis = eph.Cis_n;
%         Cic = eph.Cic_n;
%         Crs = eph.Crs_n;
%         Crc = eph.Crc_n;
%         Cus = eph.Cus_n;
%         Cuc = eph.Cuc_n;
%         
%         t_oc = eph.t_oc;
%         a_f0 = eph.a_f0n;
%         a_f1 = eph.a_f1n;
%         a_f2 = eph.a_f2n;
%         
%         naviType = 2;
    %>>>>>>>>>>��ʱ����CNAV����<<<<<<<<<^          
    if (ephemeris1.ephReady)
        eph = ephemeris1.eph;
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
        toc=eph.toc;
        a0=eph.af0;
        a1=eph.af1;
        a2=eph.af2;
        TGD1=0; %˫Ƶ�޴���У����!
            
        naviType = 1;
    end
end

%% ����NAV���Ľ���
if (naviType == 1)
    A=sqrtA^2; %����볤��
    %% find initial satellite clock correction
    %��������ʱ��
    dt = check_t(transmitTime-toc);
    % dt = check_t(transmitTime-toc);
    %�������ǲ������λʱ��ƫ��
    satClkCorr(1) = a0+(a1+a2*dt)*dt-TGD1;
    %�����źŷ���ʱ��ϵͳʱ��
    time = transmitTime - satClkCorr(1);
    %% find sat position
    %ʱ��У��
    tk  = check_t(time - toe);
    %��������ƽ�����ٶ�
    n0=(GM/A^3)^0.5;
    %����ƽ�����ٶ�
    n=n0+deltan;
    %����ƽ�����
    M=M0+n*tk;
    M   = rem(M + 2*Pi, 2*Pi);
    
    %��������ƫ�����,��Խ����
    E=M;
    %--- Iteratively compute eccentric anomaly ----------------------------
    for ii = 1:10
        Eold   = E;
        E       = M + e * sin(E);
        dE      = rem(E - Eold, 2*Pi);
        
        if abs(dE) < 1.e-12
            % Necessary precision is reached, exit from the loop
            break;
        end
    end
    
    E   = rem(E + 2*Pi, 2*Pi);
    %M_k=E-e*sin(E);
    %ʱ������
    %�����������
    dtr = F*e*sqrtA * sin(E);
    %��ʱ��������
    %%%%%%%%%%%����һ�η����ٴμ���%%%%%%%%%%
    satClkCorr(1)=a0+(a1+a2*dt)*dt+dtr-TGD1;
    time = transmitTime - satClkCorr(1);
    %ʱ��У��
    tk  = check_t(time - toe);
    %��������ƽ�����ٶ�
    n0=(GM/A^3)^0.5;
    %����۲���Ԫ���ο���Ԫ��ʱ���
    %t_k=t-toe;%t?
    %����ƽ�����ٶ�
    n=n0+deltan;
    %����ƽ�����
    M=M0+n*tk;
    M   = rem(M + 2*Pi, 2*Pi);
    
    E=M;
    %--- Iteratively compute eccentric anomaly ----------------------------
    for ii = 1:10
        Eold   = E;
        E       = M + e * sin(E);
        dE      = rem(E - Eold, 2*Pi);
        
        if abs(dE) < 1.e-12
            % Necessary precision is reached, exit from the loop
            break;
        end
    end
    
    E   = rem(E + 2*Pi, 2*Pi);
    
    v_k   = atan2(sqrt(1 - e^2) * sin(E), cos(E)-e);
    %����γ�ȷ��ǲ���
    phi_k=v_k+omega;
    %Reduce phi to between 0 and 360 deg
    phi_k = rem(phi_k, 2*Pi);
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
    OMEGA_k=omega0+(omega_dot-Omega_e_dot)*tk-Omega_e_dot*toe;
    X_k=x_k.*cos(OMEGA_k)-y_k.*cos(i_k).*sin(OMEGA_k);
    Y_k=x_k.*sin(OMEGA_k)+y_k.*cos(i_k).*cos(OMEGA_k);
    Z_k=y_k.*sin(i_k);
    position = [X_k;Y_k;Z_k];
    % % end
    %%
    satPos(1) = position(1);
    satPos(2) = position(2);
    satPos(3) = position(3);
    
    %% calculate velocity of NGEO satellite
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
    OMEGA_k1 = omega_dot-Omega_e_dot;
    %5.����x_k1,y_k1
    x_k1 = r_k1*cos(u_k) - r_k*u_k1*sin(u_k);
    y_k1 = r_k1*sin(u_k) + r_k*u_k1*cos(u_k);
    %6.����X_k1,Y_k1,Z_k1��vx,vy,vz
    X_k1 = -Y_k*OMEGA_k1-(y_k1*cos(i_k)-Z_k*i_k1)*sin(OMEGA_k)+x_k1*cos(OMEGA_k);
    Y_k1 = X_k*OMEGA_k1+(y_k1*cos(i_k)-Z_k*i_k1)*cos(OMEGA_k)+x_k1*sin(OMEGA_k);
    Z_k1 = y_k1*sin(i_k) + y_k*i_k1*cos(i_k);
    %==============finish calculate velocity==========================
    satPos(4) = X_k1;
    satPos(5) = Y_k1;
    satPos(6) = Z_k1;
    
    %%
    %���ʽ�У�t���źŷ���ʱ�̵�BD-2ϵͳʱ�䣬Ҳ���ǶԴ���ʱ���������BD-2ϵͳ����ʱ�䣨����/���٣���
    %��ˣ�t_k����BD-2ϵͳʱ��t�������ο�ʱ��toe֮�����ʱ���������˿��һ�ܿ�ʼ�������ʱ�䣬
    %Ҳ���ǣ����t_k>302400ʱ���ʹ�t_k�м�ȥ604800�������t_k<-302400ʱ���Ͷ�t_k�м���604800
    %satposition(satNr)=[X_GK;Y_GK;Z_GK];
    dtr = F*e*sqrtA * sin(E);
    satClkCorr(1)=a0+(a1+a2*dt)*dt+dtr-TGD1;
    dtr_dot = F*e*sqrtA * E1 * cos(E);
    satClkCorr(2) = a1 + 2*a2*dt + dtr_dot;
end %EOF: if (naviType == 1)

%% ����CNAV���Ľ���
if (naviType == 2)
    %% �Ӳ�Ԥ��
    dt = check_t(transmitTime - t_oc);  %ʱ���ֵ����
    satClkCorr(1) = a_f0 + a_f1*dt + a_f2*dt^2; %�Ӳ���ƣ��������У���
    t_k = check_t(transmitTime - t_oe - satClkCorr(1)); %����ʱ���ֵ����
    
    A_0 = A_ref + Delta_A;   %�ο�ʱ��İ볤��
    A_k = A_0 + A_dot * t_k; %��ǰ�볤��
    n0 = sqrt(miu/A_0^3);    %�ο�ʱ��ƽ�����ٶ�
    n_A = n0 + Delta_n0 + 0.5*Delta_n0_dot*t_k;  %�������ٶ�
    
    M_k = M_0 + n_A*t_k;  %ƽ����� 
    %��������ƫ�����
    E_k=M_k;
    for ii = 1:10
        Eold    = E_k;
        E_k     = M_k + e * sin(E_k);
        dE      = rem(E_k - Eold, 2*Pi);       
        if abs(dE) < 1e-12
            % Necessary precision is reached, exit from the loop
            break;
        end
    end
    
    %% ���������ʱ��У������������ʱ��У��ֵ�����¸�����ز���
    dtr = F*e*sqrt(A_k) * sin(E_k);
    
    satClkCorr(1) = a_f0 + a_f1*dt + a_f2*dt^2 + dtr;
    t_k = check_t(transmitTime - t_oe - satClkCorr(1));
    A_k = A_0 + A_dot * t_k; %��ǰ�볤��
    n_A = n0 + Delta_n0 + 0.5*Delta_n0_dot*t_k;  %�������ٶ�
    M_k = M_0 + n_A*t_k;  %ƽ����� 
    %��������ƫ�����
    for ii = 1:10
        Eold    = E_k;
        E_k     = M_k + e * sin(E_k);
        dE      = rem(E_k - Eold, 2*Pi);       
        if abs(dE) < 1e-12
            % Necessary precision is reached, exit from the loop
            break;
        end
    end
    
    %% ��������λ��
    %����������
    v_k = atan2( sqrt(1-e^2)*sin(E_k), cos(E_k)-e );
    
    Phi_k = v_k + omega_n;
    %�������г���Ŷ������γ�ȷ��Ǹ�����������������Ǹ�����
    delta_u_k = Cus*sin(2*Phi_k) + Cuc*cos(2*Phi_k);
    delta_r_k = Crs*sin(2*Phi_k) + Crc*cos(2*Phi_k);
    delta_i_k = Cis*sin(2*Phi_k) + Cic*cos(2*Phi_k);
    %����������γ�Ȳ������������
    u_k = Phi_k+delta_u_k;
    r_k = A_k*(1-e*cos(E_k))+delta_r_k;
    i_k = i_0 + i_0_dot*t_k + delta_i_k;
    %���������ڹ��ƽ���ڵ�����
    x_k = r_k*cos(u_k);
    y_k = r_k*sin(u_k);
    %������Ԫ������ľ��ȣ��ع�ϵ��������MEO/IGSO������CGS2000����ϵ�е�����
    Omega_k = Omega_0 + (Omega_dot_ref + Delta_Omega_dot - Omega_e_dot)*t_k - Omega_e_dot*t_oe;
    X_k = x_k*cos(Omega_k) - y_k*cos(i_k)*sin(Omega_k);
    Y_k = x_k*sin(Omega_k) + y_k*cos(i_k)*cos(Omega_k);
    Z_k = y_k*sin(i_k);
    
    satPos(1:3) = [X_k;Y_k;Z_k];
    
    %% ���������ٶ�
    %1. E_kһ�׵���
    E_k1 = n_A/(1-e*cos(E_k));
    %2. Phi_kһ�׵���
    Phi_k1 = sqrt(1-e^2)*E_k1/(1-e*cos(E_k));  
    %3. delta_u_k��delta_r_k��delta_i_kһ�׵���
    delta_u_k1 = 2*Phi_k1*(Cus*cos(2*Phi_k1)-Cuc*sin(2*Phi_k1));
    delta_r_k1 = 2*Phi_k1*(Crs*cos(2*Phi_k1)-Crc*sin(2*Phi_k1));
    delta_i_k1 = 2*Phi_k1*(Cis*cos(2*Phi_k1)-Cic*sin(2*Phi_k1));
    %4. u_k,r_k,i_k,Omega_k һ�׵���
    u_k1 = Phi_k1 + delta_u_k1;
    r_k1 = A_k*e*E_k1*sin(E_k) + delta_r_k1;
    i_k1 = i_0_dot + delta_i_k1;
    Omega_k1 = Omega_dot_ref + Delta_Omega_dot - Omega_e_dot;
    %5. x_k, y_k�ĵ���
    x_k1 = r_k1*cos(u_k) - r_k*u_k1*sin(u_k);
    y_k1 = r_k1*sin(u_k) + r_k*u_k1*cos(u_k);
    %6.����X_k1,Y_k1,Z_k1��vx,vy,vz
    X_k1 = -Y_k*Omega_k1 - (y_k1*cos(i_k)-Z_k*i_k1)*sin(Omega_k) + x_k1*cos(Omega_k);
    Y_k1 = X_k*Omega_k1 + (y_k1*cos(i_k)-Z_k*i_k1)*cos(Omega_k) + x_k1*sin(Omega_k);
    Z_k1 = y_k1*sin(i_k) + y_k*i_k1*cos(i_k);
    
    satPos(4:6) = [X_k1;Y_k1;Z_k1];
    
    %% ����Ƶ��Ư��
    dtr_dot = F*e*sqrt(A_k)*E_k1*cos(E_k); %��ȻCNAV�и���A�ĵ�����������ȵ�һ���С���ɺ���
    satClkCorr(2) = a_f1 + 2*a_f2*dt + dtr_dot;  
    
end %EOF:  if (naviType == 2)