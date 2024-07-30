% ���� : ���������ͽ��ջ�������Ϣ������������ǵĸ���״̬
% Input :   SOW : ���ݵ����������    matrix : [ 1 �� N ]
%           fileNameBds : ���������ļ���
%           fileNameGps : GPS�����ļ���
%           refPos  :  �������ǡ���λ�ǵĲο�λ������     matrix : [ 3 �� N ]

function [satPara, prnList] = satPosVelEph(TransTime, prnNo, fileName, refPosVec, constel)
timeLen = size(TransTime, 2);
el_bound = 15; % ����б������
% ��������������������  �������ǵ�״̬����  ������������������������%
Para = struct(...
    'satPos',   zeros(3, timeLen),...
    'satVel',   zeros(3, timeLen),...
    'clkErr',   zeros(2, timeLen),...
    'vel_tan',   zeros(1, timeLen),...
    'El',       zeros(1, timeLen),...
    'Az',       zeros(1, timeLen),...
    'V_El',       zeros(1, timeLen),...
    'V_Az',       zeros(1, timeLen),...
    'V_El_Az',       zeros(1, timeLen),...
    'SOW',      zeros(1, timeLen),...
    'SYS',      ''...
    );
% ��������������������  ϵͳ����״̬����  ������������������������%
sys = struct(...
    'prnVisible', zeros(35, timeLen),...  % �ɼ����ǵ�PRN��
    'prnVisNum', zeros(1, timeLen),...    % �ɼ����ǵ����� 
    'GDOP', zeros(1, timeLen),...         % GDOPֵ
    'SYS',      ''...
    );

if strcmp(constel, 'BDS')
    [ephemeris_BDS, prn_list_BDS, updateTimes_BDS, isNorm_BDS, toe_matrix_BDS] = loadEphFromRINEX_C(fileName, constel);
    prnList.BDS =  prn_list_BDS;
    satPara.BDS.para(1:35) = Para;
    satPara.BDS.sys = sys;
elseif strcmp(constel, 'GPS')
    [ephemeris_GPS, prn_list_GPS, updateTimes_GPS, isNorm_GPS, toe_matrix_GPS] = loadEphFromRINEX_C(fileName, constel);
    prnList.GPS =  prn_list_GPS;
    satPara.GPS.para(1:35) = Para;
    satPara.GPS.sys = sys;
end


for i = 1 : timeLen
    refPos = refPosVec(:, i);
    G_mat = zeros(35, 4);
    prnRecev = prnNo(:, i);
    prnRecev(isnan(prnRecev)) = [];
    %% ��������������������������������  ����GPS����״̬  ��������������������������������%
    if strcmp(constel, 'GPS')
        for j = 1 : length(prnRecev)
            prn = prnRecev(j);
            time = TransTime(prn, i);
            if any(prn_list_GPS == prn)
                line = prn_list_GPS == prn;
                timeErr = abs(toe_matrix_GPS(line, :) - time);
                [~, index] = min(timeErr);
                [satPositions, satClkCorr] = GPS_calculateSatPosition_extra(time, ephemeris_GPS(line, index), prn);
                vector_norm = (satPositions(1:3)-refPos) / norm(satPositions(1:3)-refPos);
                Len = norm(satPositions(1:3)-refPos);
                vel_parallel = (vector_norm'*satPositions(4:6));
                vel_Orth = sqrt((norm(satPositions(4:6)))^2 - vel_parallel^2);
                satPara.GPS.para(prn).vel_tan(i) = vel_Orth / Len;
                [az, el, dist] = topocent(refPos, satPositions(1:3)-refPos);
                satPara.GPS.para(prn).satPos(:,i) = satPositions(1:3);
                satPara.GPS.para(prn).satVel(:,i) = satPositions(4:6);
                satPara.GPS.para(prn).clkErr(:,i) = satClkCorr;
                satPara.GPS.para(prn).El(i) = el;
                satPara.GPS.para(prn).Az(i) = az;
                % �����Ǵ���10�ȵ�������Ϊ�ɼ�����
                if el >= el_bound 
                    satPara.GPS.sys.prnVisNum(i) = satPara.GPS.sys.prnVisNum(i) + 1;
                    satPara.GPS.sys.prnVisible(satPara.GPS.sys.prnVisNum(i), i) = prn;
                    G_mat(satPara.GPS.sys.prnVisNum(i), :) = [-cos(el)*sin(az), ...
                            -cos(el)*cos(az), ...
                            -sin(el), 1];
                end
                % �������ǡ���λ�ǵı仯��
                if i > 1
                    satPara.GPS.para(prn).V_El(i) = el - satPara.GPS.para(prn).El(i-1);
                    satPara.GPS.para(prn).V_Az(i) = az - satPara.GPS.para(prn).Az(i-1);
                    if satPara.GPS.para(prn).V_Az(i)>180
                        satPara.GPS.para(prn).V_Az(i) = satPara.GPS.para(prn).V_Az(i) - 360;
                    elseif satPara.GPS.para(prn).V_Az(i)<-180
                        satPara.GPS.para(prn).V_Az(i) = satPara.GPS.para(prn).V_Az(i) + 360;
                    end
                else
                    satPara.GPS.para(prn).V_El(i) = 0;
                    satPara.GPS.para(prn).V_Az(i) = 0;
                end
                satPara.GPS.para(prn).V_El_Az(i) = sqrt((satPara.GPS.para(prn).V_El(i))^2 + (satPara.GPS.para(prn).V_Az(i))^2);
                satPara.GPS.para(prn).SOW(i) = time;
            end % if any(prn_list_BDS == prn)
        end % for prn = 1 : 32
        % �������������������� ����DOPֵ ����������������������������%
        if satPara.GPS.sys.prnVisNum(i) >= 4
            G_mat_valid = G_mat(1:satPara.GPS.sys.prnVisNum(i), :);
            H_mat =  inv(G_mat_valid' * G_mat_valid);
            satPara.GPS.sys.GDOP(i) = sqrt(H_mat(1,1)+H_mat(2,2)+H_mat(3,3)+H_mat(4,4));
            if satPara.GPS.sys.GDOP(i) > 10
                satPara.GPS.sys.GDOP(i) = 10;
            end
        else
            satPara.GPS.sys.GDOP(i) = 10;
        end
    %%     
    elseif strcmp(constel, 'BDS')
    %% ��������������������������������  ���㱱������״̬  ��������������������������������%
        for j = 1 : length(prnRecev)
            prn = prnRecev(j);
            time = TransTime(prn, i);
            if any(prn_list_BDS == prn)
                line = prn_list_BDS == prn;
                timeErr = abs(toe_matrix_BDS(line, :) - time);
                [~, index] = min(timeErr);
                [satPositions, satClkCorr] = BD_calculateSatPosition_extra(time, ephemeris_BDS(line, index), prn);
                vector_norm = (satPositions(1:3)-refPos) / norm(satPositions(1:3)-refPos);
                Len = norm(satPositions(1:3)-refPos);
                vel_parallel = (vector_norm'*satPositions(4:6));
                vel_Orth = sqrt((norm(satPositions(4:6)))^2 - vel_parallel^2);
                satPara.BDS.para(prn).vel_tan(i) = vel_Orth / Len;
                [az, el, dist] = topocent(refPos, satPositions(1:3)-refPos);
                satPara.BDS.para(prn).satPos(:,i) = satPositions(1:3);
                satPara.BDS.para(prn).satVel(:,i) = satPositions(4:6);
                satPara.BDS.para(prn).clkErr(:,i) = satClkCorr;
                satPara.BDS.para(prn).El(i) = el;
                satPara.BDS.para(prn).Az(i) = az;
                % �����Ǵ���3�ȵ�������Ϊ�ɼ�����
                if el >= el_bound 
                    satPara.BDS.sys.prnVisNum(i) = satPara.BDS.sys.prnVisNum(i) + 1;
                    satPara.BDS.sys.prnVisible(satPara.BDS.sys.prnVisNum(i), i) = prn;
                    G_mat(satPara.BDS.sys.prnVisNum(i), :) = [-cos(el)*sin(az), ...
                            -cos(el)*cos(az), ...
                            -sin(el), 1];
                end
                % �������ǡ���λ�ǵı仯��
                if i > 1
                    satPara.BDS.para(prn).V_El(i) = el - satPara.BDS.para(prn).El(i-1);
                    satPara.BDS.para(prn).V_Az(i) = az - satPara.BDS.para(prn).Az(i-1);
                    if satPara.BDS.para(prn).V_Az(i)>180
                        satPara.BDS.para(prn).V_Az(i) = satPara.BDS.para(prn).V_Az(i) - 360;
                    elseif satPara.BDS.para(prn).V_Az(i)<-180
                        satPara.BDS.para(prn).V_Az(i) = satPara.BDS.para(prn).V_Az(i) + 360;
                    end
                else
                    satPara.BDS.para(prn).V_El(i) = 0;
                    satPara.BDS.para(prn).V_Az(i) = 0;
                end
                satPara.BDS.para(prn).V_El_Az(i) = sqrt((satPara.BDS.para(prn).V_El(i))^2 + (satPara.BDS.para(prn).V_Az(i))^2);
                satPara.BDS.para(prn).SOW(i) = time;
            end % for prn = 1 : 14
        end % if any(prn_list_BDS == prn)
        % �������������������� ����DOPֵ ����������������������������%
        if satPara.BDS.sys.prnVisNum(i) >= 4
            G_mat_valid = G_mat(1:satPara.BDS.sys.prnVisNum(i), :);
            H_mat =  inv(G_mat_valid' * G_mat_valid);
            satPara.BDS.sys.GDOP(i) = sqrt(H_mat(1,1)+H_mat(2,2)+H_mat(3,3)+H_mat(4,4));
            if satPara.BDS.sys.GDOP(i) > 10
                satPara.BDS.sys.GDOP(i) = 10;
            end
        else
            satPara.BDS.sys.GDOP(i) = 10;
        end
    end % if strcmp(constel, 'GPS')
end % for i = 1 : length(SOW)



