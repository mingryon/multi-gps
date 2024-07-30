function [parameter, SOW] = rinex2obs_basestation(filename_RinexObs, fileNameBds, fileNameGps, decimate_factor, refPos, syst,Acc_WGS84,V_WGS84_s)
% clear;
% filename_RinexObs = 'E:\��������\С���Ĳ���\ION2018\data\20180326_NanjingEastRoad.obs'; 
% fileNameBds = 'E:\��������\С���Ĳ���\ION2018\data\BDS_Eph_20180324.18p';
% fileNameGps = 'E:\��������\С���Ĳ���\ION2018\data\GPS_Eph_20180324.18p';

%% rinex��ȡ
[C1, L1, S1, D1, ch, SOW] = read_rinex(filename_RinexObs, decimate_factor);
% refPos = [-2850197.286; 4655185.885; 3288382.972];  % ��̬��
refPos = repmat(refPos, 1, length(SOW));
c = 299792458;

%% obs��ʼ��
maxPrnNo = 35;      % ϵͳPRN�����ֵ
maxPath = 5;        % ÿ�������ź����ﵽ·����Ŀ
logCount = length(SOW);    % ��ȡ�ܼ�¼����
%������������������������ ������ʼ�� ������������������������%
parameter = struct(...
    'SYST',              '',...                         % ϵͳ
    'prnMax',           [],...                          % �˶��������пɼ������źŵ�PRN��
    'prnNo',            nan(maxPrnNo,logCount),...      % ��ǰʱ�̿ɼ����ǵ�PRN��
    'PDOP',             nan(1,logCount),...             % PDOPֵ [1 �� ��¼ʱ��]
    'localClkErr',      nan(1,logCount),...             % �����Ӳ� [1 �� ��¼ʱ��]
    'localClkDrift',    nan(1,logCount),...             % ������Ư [1 �� ��¼ʱ��]
    'Elevation',        nan(maxPrnNo,logCount),...      % ���� [����PRN�� �� ��¼ʱ��]
    'Azimuth',          nan(maxPrnNo,logCount),...      % ��λ�� [����PRN�� �� ��¼ʱ��]
    'Pseudorange',      nan(maxPrnNo,logCount),...      % α�� [����PRN�� �� ��¼ʱ��]
    'InteDopp',         nan(maxPrnNo,logCount),...      % ���ֶ����� [����PRN�� �� ��¼ʱ��]
    'TransTime',        nan(maxPrnNo,logCount),...      % �źŷ���ʱ�� [����PRN�� �� ��¼ʱ��]
    'carriErr',         nan(maxPrnNo,logCount),...      % �ز����������� ���㣩[����PRN�� �� ��¼ʱ��]
    'carriPhase',       nan(maxPrnNo,logCount),...      % �ز���λֵ [����PRN�� �� ��¼ʱ��]
    'doppFreq',         nan(maxPrnNo,logCount),...       % ������Ƶ�� [����PRN�� �� ��¼ʱ��]
    'codePhase',        nan(maxPrnNo,logCount),...      % ��Ƶ����λ [����PRN�� �� ��¼ʱ��]
    'satPos',           '',...                          % ����λ��
    'satClkErr',        nan(maxPrnNo,logCount),...      % �����Ӳ� [����PRN�� �� ��¼ʱ��]
    'satClkDrift',      nan(maxPrnNo,logCount),...      % �����Ӳ�Ư�� [����PRN�� �� ��¼ʱ��]
    'pathNum',          nan(maxPrnNo,logCount),...      % �ź�·����Ŀ [����PRN�� �� ��¼ʱ��]
    'codePhaseErr',     nan(maxPrnNo,logCount),...      % �ྶ���������λƫ�� [����PRN�� �� ��¼ʱ��]
     'IMU_vx',           0,...
     'IMU_vy',           0,...
     'IMU_vz',           0,...
    'IMU_ax',           0,...
    'IMU_ay',               0,...
    'IMU_az',               0,...
    'pathPara',         ''...
    );
parameter(1:2,1) = parameter;
satPos = struct(...
    'position',         nan(3,logCount),...             % ����λ�� [(X Y Z) �� ��¼ʱ��]
    'velocity',         nan(3,logCount)...              % �����ٶ� [(Vx Vy Vz) �� ��¼ʱ��]
    );
pathPara = struct(...
    'codePhaseDelay',   nan(maxPath,logCount),...             % ����λ��ʱ [1 �� ��¼ʱ��]
    'ampI',             nan(maxPath,logCount),...             % I·�źŷ�ֵ [1 �� ��¼ʱ��]
    'ampQ',             nan(maxPath,logCount),...             % Q·�źŷ�ֵ [1 �� ��¼ʱ��]
    'SNR',              nan(maxPath,logCount),...             % ����� [1 �� ��¼ʱ��]
    'CNR',              nan(maxPath,logCount)...              % ����� [1 �� ��¼ʱ��]
    );
parameter(1).SYST = 'BDS_B1I';      % ��һ�м�¼����B1I�źŲ���
parameter(2).SYST = 'GPS_L1CA';     % �ڶ��м�¼GPS L1CA�źŲ���
parameter(1).satPos = satPos;
parameter(1).satPos(1:maxPrnNo,1) = parameter(1).satPos;
parameter(2).satPos = satPos;
parameter(2).satPos(1:maxPrnNo,1) = parameter(2).satPos;
parameter(1).pathPara = pathPara;
parameter(1).pathPara(1:maxPrnNo,1) = parameter(1).pathPara;
parameter(2).pathPara = pathPara;
parameter(2).pathPara(1:maxPrnNo,1) = parameter(2).pathPara;

%% �������������������� �������ǲ�����ֵ ������������������������%
if strcmp(syst, 'BDS_B1I') || strcmp(syst, 'B1I_L1CA')
    sat_BDS = unique(ch.BDS);
    sat_BDS(isnan(sat_BDS)) = [];
    parameter(1).prnMax = sat_BDS(2:end)';  
    parameter(1).prnNo = ch.BDS;
    parameter(1).Pseudorange = C1.BDS;
    [row,col] = find(parameter(1).Pseudorange>6e7);
    if ~isempty(row)
        for i = 1 : length(row)
            parameter(1).prnNo(parameter(1).prnNo(:, col(i))==row(i), col(i)) = nan;
        end
    end
    parameter(1).InteDopp = L1.BDS;
    parameter(1).TransTime = repmat(SOW, maxPrnNo, 1) - 14 - parameter(1).Pseudorange/c;
    parameter(1).doppFreq = D1.BDS;
    parameter(1).pathNum = ones(maxPrnNo,logCount);
    [satPara, PrnList] = satPosVelEph(parameter(1).TransTime, parameter(1).prnNo, fileNameBds, refPos, 'BDS');
    for i = 1 : maxPrnNo
        parameter(1).Elevation(i, :) = satPara.BDS.para(i).El;
        parameter(1).Azimuth(i, :) = satPara.BDS.para(i).Az;
        parameter(1).satPos(i).position = satPara.BDS.para(i).satPos;
        parameter(1).satPos(i).velocity = satPara.BDS.para(i).satVel;
        parameter(1).satClkErr(i, :) = satPara.BDS.para(i).clkErr(1, :) * c;
        parameter(1).satClkDrift(i, :) = satPara.BDS.para(i).clkErr(2, :) * c;
        parameter(1).pathPara(i).codePhaseDelay(1, :) = zeros(1, logCount);
        parameter(1).pathPara(i).CNR(1, :) = S1.BDS(i, :);
    end%
    %��������������������ȥ���������Ǻš�����������������������%
    for i = 1 : length(parameter(1).prnMax)
        if ~ismember(parameter(1).prnMax(i), PrnList.BDS)
            errPrn = parameter(1).prnMax(i);
            parameter(1).prnNo(parameter(1).prnNo==errPrn) = nan;
        end
    end
end % if strcmp(syst, 'BDS_B1I') || strcmp(syst, 'B1I_L1CA')

%% �������������������� GPS���ǲ�����ֵ ������������������������%
if strcmp(syst, 'GPS_L1CA') || strcmp(syst, 'B1I_L1CA')
    sat_GPS = unique(ch.GPS);  
    sat_GPS(isnan(sat_GPS)) = [];
    parameter(2).prnMax = sat_GPS(2:end)';  
    parameter(2).prnNo = ch.GPS;
    parameter(2).Pseudorange = C1.GPS;
    [row,col] = find(parameter(2).Pseudorange>6e7);
    Acc_WGS84(:,1) = 0;
        Acc_WGS84(:,2) = 0;
            Acc_WGS84(:,3) = 0;
    parameter(2).IMU_ax = Acc_WGS84(:,1);
    parameter(2).IMU_ay = Acc_WGS84(:,2);
    parameter(2).IMU_az = Acc_WGS84(:,3);
    parameter(2).IMU_vx = V_WGS84_s(:,1);
    parameter(2).IMU_vy = V_WGS84_s(:,2);
    parameter(2).IMU_vz = V_WGS84_s(:,3);
    
    if ~isempty(row)
        for i = 1 : length(row)
            parameter(2).prnNo(parameter(2).prnNo(:, col(i))==row(i), col(i)) = nan;
        end
    end
    parameter(2).InteDopp = L1.GPS;
    parameter(2).TransTime = repmat(SOW, maxPrnNo, 1) - parameter(2).Pseudorange/c;
    parameter(2).doppFreq = D1.GPS;
    parameter(2).pathNum = ones(maxPrnNo,logCount);
    [satPara, PrnList] = satPosVelEph(parameter(2).TransTime, parameter(2).prnNo, fileNameGps, refPos, 'GPS');
    for i = 1 : maxPrnNo
        parameter(2).Elevation(i, :) = satPara.GPS.para(i).El;
        parameter(2).Azimuth(i, :) = satPara.GPS.para(i).Az;
        parameter(2).satPos(i).position = satPara.GPS.para(i).satPos;
        parameter(2).satPos(i).velocity = satPara.GPS.para(i).satVel;
        parameter(2).satClkErr(i, :) = satPara.GPS.para(i).clkErr(1, :) * c;
        parameter(2).satClkDrift(i, :) = satPara.GPS.para(i).clkErr(2, :) * c;
        parameter(2).pathPara(i).codePhaseDelay(1, :) = zeros(1, logCount);
        parameter(2).pathPara(i).CNR(1, :) = S1.GPS(i, :);
    end
    %��������������������ȥ���������Ǻš�����������������������%
    for i = 1 : length(parameter(2).prnMax)
        if ~ismember(parameter(2).prnMax(i), PrnList.GPS)
            errPrn = parameter(2).prnMax(i);
            parameter(2).prnNo(parameter(2).prnNo==errPrn) = nan;
        end
    end
end % if strcmp(syst, 'GPS_L1CA') || strcmp(syst, 'B1I_L1CA')

