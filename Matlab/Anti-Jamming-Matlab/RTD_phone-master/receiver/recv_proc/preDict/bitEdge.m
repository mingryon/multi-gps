function Samp_Posi = bitEdge(channel, SYST)
% ����������Ϣ��������λ��������bit��Եλ��
global GSAR_CONSTANTS;

switch SYST
    case {'GPS_L1CA','GPS_L1CA_L2C'}
        time = ((GSAR_CONSTANTS.STR_L1CA.ChipNum-channel.LO_CodPhs) + (GSAR_CONSTANTS.STR_L1CA.NT1ms_in_bit-channel.T1ms_N-1)*GSAR_CONSTANTS.STR_L1CA.ChipNum)...
            / (channel.LO_Fcode0 + channel.LO_Fcode_fd); % ���㵽bit��Ե�������ʱ��
    case 'BDS_B1I'
        if strcmp(channel.navType, 'B1I_D1')
            time = ((GSAR_CONSTANTS.STR_B1I.ChipNum-channel.LO_CodPhs) + (GSAR_CONSTANTS.STR_B1I.NT1ms_in_D1-channel.T1ms_N-1)*GSAR_CONSTANTS.STR_B1I.ChipNum)...
                / (channel.LO_Fcode0 + channel.LO_Fcode_fd); % ���㵽bit��Ե�������ʱ��
        else
            time = ((GSAR_CONSTANTS.STR_B1I.ChipNum-channel.LO_CodPhs) + (GSAR_CONSTANTS.STR_B1I.NT1ms_in_D2-channel.T1ms_N-1)*GSAR_CONSTANTS.STR_B1I.ChipNum)...
                / (channel.LO_Fcode0 + channel.LO_Fcode_fd); % ���㵽bit��Ե�������ʱ��
        end
end

Samp_Posi = round(time * GSAR_CONSTANTS.STR_RECV.fs);%�����������

