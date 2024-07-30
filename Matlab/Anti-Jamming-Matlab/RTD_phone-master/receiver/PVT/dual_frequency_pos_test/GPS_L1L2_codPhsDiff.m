function delta_phs = GPS_L1L2_codPhsDiff( channel_spc )

%��������λ��ʱУ����(m),��L1α��Ϊ��׼

% delta_phs = (codPhs_L1 - codPhs_L2)*c/1.023MHz = rho2 - rho1; 


c = 299792458;

delta_phs = mod( channel_spc.LO_CodPhs - channel_spc.LO_CodPhs_L2, 1023 );
if (delta_phs>511.5)
    delta_phs = delta_phs - 1023;
end
delta_phs = delta_phs*c/1.023e6;
