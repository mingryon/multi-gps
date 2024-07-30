function diff = GPS_L1L2_ionoCorr( channel_spc, ISC )

%���������ʱ�������豸��ʱ����λ����
% ��L1α��Ϊrho1,��У����ʽΪ��GPS-200H,p172):
... rho = rho1 + (rho2-rho1)/(1-gamma) + c*(ISC_L2C-gamma*ISC_L1CA)/(1-gamma) - c*T_GD;
... ���Ӹ��ٻ�·���Լ��㣺 rho2-rho1 = ��L1_codPhs - L2_codPhs��* c / 1.023MHz

%diff: ��ʱУ���� rho = rho1 + diff;
%channel_spc: ͨ��L1��L2������λ���Ի�ȡƵ������ʱ
%ISC: ���������������豸��ʱ��Ϣ

c = 299792458;
gamma = (77/60)^2; % (f1/f2)^2

p1 = channel_spc.LO_codPhs;   %local code phase of CA code
p2 = channel_spc.LO_codPhs_L2;

delta_phs = mod(p1-p2, 1023);
if (delta_phs>511.5)
    delta_phs = delta_phs - 1023;
end
delta_phs = (delta_phs * c/1.023e6)/(1-gamma); %���������Ϊ��λ

if (ISC.ISC_ready)
    ISC_corr =  c*(ISC.ISC_L2C - gamma * ISC.ISC_L1CA)/(1-gamma) - c*ISC.T_GD;
else
    ISC_corr = 0;
end

diff = delta_phs + ISC_corr;