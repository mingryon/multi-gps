function [iono, pvtCalculator] = Ionospheric_GPS_L1L2( ... 
    pvtCalculator, iono, el, L2toL1_delay, ISC, chN, prnList_L1L2)
%У����ʽ �� rho0 = rho1 - iono;
%iono = ( L2toL1_delay - L2toL1_devDelay + c*(ISC_L2C - gamma*ISC_L1CA) )/(gamma-1) + c*T_GD;
%���� iono = c*(T_GD-ISC_L1CA) + M(theta)*VTEC_L1;

%��� iono: �������ʱ�����Ǻͽ��ջ��豸��ʱ��У��ֵ�������L1α�ࣩ
%    pvtCalculator: ����L1Ƶ��Ĵ�ֱ�������ʱ���豸Ƶ����ʱ�Ĺ���ֵ

%���룺
%    pvtCalculator�� �õ����ջ��豸ʱ�ӵ���ʷֵ��ƽ��
%    el:�������� 1*32 (degree)
%    L2toL1_delay: ���ٻ�·�õ���Ƶ������ʱ 1*32
%    ISC�� �������������豸ʱ������ĵ������� 1*32 struct
%    chN�� ˫Ƶͨ������
%    prnList_L1L2: ˫Ƶ����prn�б� 1*32��chN

c = 299792458;
gamma = (77/60)^2;

if (chN==1)
    prn = prnList_L1L2(1);
    iono(prn) = ( L2toL1_delay(prn) - pvtCalculator.L2toL1_devDelay + c*ISC(prn).ISC_L2C - ...
        c*gamma*ISC(prn).ISC_L1CA )/(gamma-1) + c*ISC(prn).T_GD;
elseif (chN>1) %������С���˽�
    A = zeros(chN,2);
    b = zeros(chN,1);
    M = zeros(chN,1);
    A(:,1) = 1;
    for i=1:chN
        prn = prnList_L1L2(i);
        theta = el(prn)/180;
        M(i) = 1+16*(0.53-theta)^3;
        A(i,2) = (gamma-1)*M(i);
        b(i) = L2toL1_delay(prn) + c*( ISC(prn).ISC_L2C-ISC(prn).ISC_L1CA );     
    end
    x=(A.'*A)\A.'*b;
    
    %���豸��ʱ�͵��������������˲�ƽ��
    if (pvtCalculator.L2toL1_devDelay~=0)
        pvtCalculator.L2toL1_devDelay = 0.5*pvtCalculator.L2toL1_devDelay + 0.5*x(1);
    else
        pvtCalculator.L2toL1_devDelay = x(1);
    end
    
    if (pvtCalculator.VTEC_L1~=0)
        pvtCalculator.VTEC_L1 = 0.5*pvtCalculator.VTEC_L1 + 0.5*x(2);
    else
        pvtCalculator.VTEC_L1 = x(2);
    end
    
    %����У����
    for i=1:chN
        prn = prnList_L1L2(i);
        iono(prn) = c*(ISC(prn).T_GD-ISC(prn).ISC_L1CA) + M(i)*pvtCalculator.VTEC_L1;
    end

end
    