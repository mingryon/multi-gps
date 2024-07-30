% ���� : ���������ͽ��ջ�������Ϣ������������ǵ����Ƿ�λ��
% Input :   SOW : ���ݵ����������    matrix : [ 1 �� N ]
%           fileNameBds : ���������ļ���
%           fileNameGps : GPS�����ļ���
%           refPos  :  �������ǡ���λ�ǵĲο�λ������     matrix : [ 3 �� N ]

function [el, az] = sat_El_Az(ephemeris, prn_list, toe_matrix, prn, time, refPos, sys)

% [ephemeris_BDS, prn_list_BDS, updateTimes_BDS, isNorm_BDS, toe_matrix_BDS] = loadEphFromRINEX_C(fileNameBds);
% [ephemeris_GPS, prn_list_GPS, updateTimes_GPS, isNorm_GPS, toe_matrix_GPS] = loadEphFromRINEX_C(fileNameGps);
% % refPos = [-2851929.696633; 4653835.860388; 3288814.789700];

switch sys
    case 'GPS'
    %��������������������������������  ����GPS����״̬  ��������������������������������%
        if any(prn_list == prn)
            line = prn_list == prn;
            timeErr = abs(toe_matrix(line, :) - time);
            [~, index] = min(timeErr);
            [satPositions, ~] = GPS_calculateSatPosition_extra(time, ephemeris(line, index), prn);
            [az, el, ~] = topocent(refPos, satPositions(1:3)-refPos); 
        else
            el = 0;
            az = 0;
        end % if any(prn_list_BDS == prn)    ~   
    case 'BDS'
    %��������������������������������  ���㱱������״̬  ��������������������������������%   
            if any(prn_list == prn)
                line = prn_list == prn;
                timeErr = abs(toe_matrix(line, :) - time);
                [~, index] = min(timeErr);
                [satPositions, ~] = BD_calculateSatPosition_extra(time, ephemeris(line, index), prn);
                [az, el, ~] = topocent(refPos, satPositions(1:3)-refPos);
            else
                el = 0;
                az = 0;
            end % for prn = 1 : 14    
end




