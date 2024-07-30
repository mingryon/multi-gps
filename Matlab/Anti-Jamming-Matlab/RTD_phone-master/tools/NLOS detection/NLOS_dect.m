
clear; clc; fclose all; 

syst = 'GPS_L1CA';
maxNum = 35;
fileName_Base = 'E:\��������\С���Ĳ���\ION2018\data\20180324_NanjjingEastRoad_baseStation.18O'; 
fileName_Move = 'E:\��������\С���Ĳ���\ION2018\data\20180324_NanjingEastRoad_GPS&GLONASS.18O'; 
fileNameBds = 'E:\��������\С���Ĳ���\ION2018\data\BDS_Eph_20180324.18p';
fileNameGps = 'E:\��������\С���Ĳ���\ION2018\data\GPS_Eph_20180324.18p';
filenameIE = 'E:\��������\С���Ĳ���\ION2018\data\20180324_NanjingEastRoad_calibration.txt';
refPos = [-2853445.926; 4667466.476; 3268291.272];
[paraRef, sowRef] = rinex2obs(fileName_Base, fileNameBds, fileNameGps, 2, refPos, syst); 
[paraMov, sowMov] = rinex2obs(fileName_Move, fileNameBds, fileNameGps, 1, refPos, syst); 
[movPosIE, ~, sowIE, HMS_IE] = readIE(filenameIE, '20180324');
sowIE = sowIE + 18; % UTCʱ��ת��ΪGPSʱ��

timeLen = length(sowMov);
prErrGPS = nan(maxNum, timeLen);

if strcmp(syst, 'GPS_L1CA')
    for i = 1 : timeLen
        satNo = paraMov(2).prnNo(:, i); % �˴������ƶ�վ�ɼ�����ȫ���ڻ�׼վ��ⷶΧ��
        satNo(isnan(satNo)) = [];
        for j = 1 : length(satNo)
            prn = satNo(j);
            % ��׼վ
            prRefPredict = norm(paraRef(2).satPos(prn).position(:, i) - refPos);
            prRefErr = prRefPredict - paraRef(2).Pseudorange(prn, i);
            % �ƶ�վ
            [~, col] = ismember(sowMov(i), sowIE);           
            prMovPredict = norm(paraMov(2).satPos(prn).position(:, i) - movPosIE(:, col));
            prMovErr = prMovPredict - paraMov(2).Pseudorange(prn, i);
            % ���
            prErrGPS(prn, i) = prMovErr - prRefErr;
        end
    end
end

% �ҵ�������ߵ����Ǻ�
[row, col] = find(paraMov(2).Elevation == max(max(paraMov(2).Elevation)));
%�������������������� ȥ�����ջ��Ӳ��Ӱ�� ����������������������������%
x_t = 1 : timeLen;
prErr_temp = prErrGPS(row, :); % ѡ��������ߵ���Ϊ�ο����Ǻ�
% �������ö���ʽ�������ȥ��
[fitresult, ~] = createFitPoly4(x_t, prErr_temp);
errResi = prErrGPS - (fitresult(x_t))';
clkErrResi = errResi(row, :);
% �����sin�������ȥ��
[fitresult, ~] = createFitSin8(x_t, clkErrResi);
errNoise = errResi - (fitresult(x_t))';



