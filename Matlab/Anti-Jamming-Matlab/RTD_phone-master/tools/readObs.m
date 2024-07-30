function [parameter, SOW] = readObs(filename)


% ���ܣ�������ջ��������LOG�ļ���ȡ����
% ���룺
%       filename : �ļ�·�����ļ���
% �����
%       SOW :   ��¼ʱ�̵�SOWֵ     [1 �� ��¼ʱ��]
%       parameter : ��ϸ��¼����    [ϵͳ �� ������Ŀ]
%                   ������������˵���ο�parameter��ʼ��ע��
% ˵����SOW�еļ�¼ʱ������������еļ�¼ʱ�����Ӧ��ͬһ��¼ʱ��ʱ��һ�¡�
%       ��¼ֵΪNaN��ʾ�˿��޸��������ݼ�¼��
%--------------------------------------------------------------------------
% clear;clc;
% filename = 'E:\½�������ݴ������\m\logfile\Lujiazui_static_point_10_2016-5-18_9-24-36_allObs.txt';
maxPrnNo = 35;      % ϵͳPRN�����ֵ
maxPath = 5;        % ÿ�������ź����ﵽ·����Ŀ
firstEpoch = 1;     % ��¼�����Ŀ�ʼʱ��
endEpoch = 100000000;  % ��¼�����Ľ���ʱ��
wrongLine = [];     % ��¼�������Ϣ�к�
logCountAll = 0;    % ��ȡ�ܼ�¼����
linecount = 0;      % ��ǰ��ȡ��Ϣ�����ļ��е��к�
debug = 0;          % ��Ϊ����״̬����Ϊ1
fid = fopen(filename);
if fid == -1
    error('message data file not found or permission denied');
end
%�������������������� ��ȡ�ܹ���¼ʱ�̴��� ����������������%
while 1
    line = fgetl(fid);
    if ~ischar(line)
        break;
    end
    if strcmp(line(1), '>')
        logCountAll = logCountAll + 1;
    end
end
 fclose(fid); 
 if endEpoch > logCountAll
     endEpoch = logCountAll;
 end
 logCount = endEpoch - firstEpoch + 1;
%% ��ʼ��
%������������������������ ������ʼ�� ������������������������%
SOW = nan(4,logCount);          % ��¼ʱ�̵�SOWֵ��ʱ���֡��� [4 �� ��¼ʱ��]
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
    'doppFreq',        nan(maxPrnNo,logCount),...       % ������Ƶ�� [����PRN�� �� ��¼ʱ��]
    'codePhase',        nan(maxPrnNo,logCount),...      % ��Ƶ����λ [����PRN�� �� ��¼ʱ��]
    'satPos',           '',...                          % ����λ��
    'satClkErr',        nan(maxPrnNo,logCount),...      % �����Ӳ� [����PRN�� �� ��¼ʱ��]
    'satClkDrift',      nan(maxPrnNo,logCount),...      % �����Ӳ�Ư�� [����PRN�� �� ��¼ʱ��]
    'pathNum',          nan(maxPrnNo,logCount),...      % �ź�·����Ŀ [����PRN�� �� ��¼ʱ��]
    'codePhaseErr',     nan(maxPrnNo,logCount),...      % �ྶ���������λƫ�� [����PRN�� �� ��¼ʱ��]
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

%% ��ȡ����
fid = fopen(filename);
if fid == -1
   error('message data file not found or permission denied');
end

% �������������������� ��ȡ�ļ�ͷ��Ϣ ��������������������%
while 1   % this is the numeral '1'
    line = fgetl(fid);
    linecount = linecount + 1;
    len = length(line);
    if len < 80, line(len+1:80) = '0'; end 
    if strcmp(line(61:73),'END OF HEADER')
        break
    end
    if strcmp(line(61:79), 'APPROX POSITION XYZ')
        POSITION_XYZ(1) = str2double(line(1:14));
        POSITION_XYZ(2) = str2double(line(15:28));
        POSITION_XYZ(3) = str2double(line(29:42));
    end
    if strcmp(line(61:80), 'ANTENNA: DELTA H/E/N')
        ANTDELTA(1) = str2double(line(1:14));
        ANTDELTA(2) = str2double(line(15:28));
        ANTDELTA(3) = str2double(line(29:42));
    end
    if strcmp(line(61:79), 'SYS / # / OBS TYPES')
        numobs = str2double(line(5:6));
        if numobs > 9
            error('number of types of observations > 9')
        end
        obtype(1,:) = line(8:10);
        obtype(2,:) = line(12:14);
        obtype(3,:) = line(16:18);
        obtype(4,:) = line(20:22);
    end
    if strcmp(line(61:68), 'INTERVAL')
        OBSINT = str2double(line(1:10));
    end
end

%���������������������������� ��ȡ�����۲��� ������������������������%
k = 0;              % ��ȡ�ļ�����Ԫ����
breakflag = 0;      % ѭ��������־λ
while 1
    %�������������������� ��ȡ��¼ʱ����Ϣ ��������������������%
    k = k + 1;                      % ��ȡ��Ԫ������1
    linecount = linecount + 1;      % ��ȡ������1
    if k < firstEpoch
        continue;
    elseif k > endEpoch
        break;
    end
    line = fgetl(fid);
    if ~ischar(line)
        breakflag = 1; 
        break;
    end
    year = str2double(line(3:6));
    month = str2double(line(8:9));
    day = str2double(line(11:12));
    hour = str2double(line(14:15));
    minute = str2double(line(17:18));
    second = str2double(line(20:29));
    todsec = 3600*hour + 60*minute + second;  % time of day in seconds
    daynum = dayofweek(year,month,day);
    SOW(1, k) = todsec + 86400*daynum; % ���������գ�����SOWֵ
    SOW(2, k) = hour;
    SOW(3, k) = minute;
    SOW(4, k) = second;
    satNum = str2double(line(31:32));
    parameter(1).PDOP(k) = str2double(line(34:39));
    parameter(2).PDOP(k) = str2double(line(34:39));
    parameter(1).localClkErr(k) = str2double(line(41:55));
    parameter(1).localClkDrift(k) = str2double(line(57:64));
    parameter(2).localClkErr(k) = str2double(line(66:80));
    parameter(2).localClkDrift(k) = str2double(line(82:89));
    satNum_BDS = 0;
    satNum_GPS = 0;
   %�������������������� ��ȡÿ�����ǵĹ۲��� ��������������������%
    for i = 1 : satNum
        line = fgetl(fid);
        sys = line(1);
        linecount = linecount + 1;
        switch sys
            case 'C' % ����ϵͳ
                satNum_BDS = satNum_BDS + 1;
                prn = str2double(line(2:3));
                parameter(1).prnNo(satNum_BDS, k) = prn;
                if ~ismember(prn, parameter(1).prnMax)
                    parameter(1).prnMax = [parameter(1).prnMax, prn];
                end
                parameter(1).Elevation(prn,k) = str2double(line(5:9));
                if parameter(1).Elevation(prn,k) < 0 % ����¼����С��0��������
                    wrongLine = [wrongLine, linecount]; % �����¼������ı��к�
                    if debug == 0
                        continue;
                    end
                end
                parameter(1).Azimuth(prn,k) = str2double(line(11:16));
                Pseudorange = str2double(line(18:31));
                if abs(Pseudorange) > 99999999 % ����¼α���쳣��������
                    wrongLine = [wrongLine, linecount]; % �����¼������ı��к�
                    if debug == 0
                        continue;
                    end
                end
                parameter(1).Pseudorange(prn,k) = Pseudorange;
                parameter(1).InteDopp(prn,k) = str2double(line(33:46));
                parameter(1).TransTime(prn,k) = str2double(line(48:66));
                parameter(1).carriErr(prn,k) = str2double(line(68:75))*360;
                parameter(1).carriPhase(prn,k) = str2double(line(77:84));
                parameter(1).doppFreq(prn,k) = str2double(line(86:98)) - 1561098000;
                parameter(1).codePhase(prn,k) = str2double(line(100:109));
                parameter(1).satClkErr(prn,k) = str2double(line(189:202));
                parameter(1).satClkDrift(prn,k) = str2double(line(204:211));
                parameter(1).satPos(prn).position(1:3,k) = [str2double(line(111:124));str2double(line(126:139));str2double(line(141:154))];
                parameter(1).satPos(prn).velocity(1:3,k) = [str2double(line(156:165));str2double(line(167:176));str2double(line(178:187))];
                parameter(1).pathNum(prn,k) = str2double(line(213:214));
                pathNo = parameter(1).pathNum(prn,k);
                if pathNo > 5 % ����¼α���쳣��������
                    wrongLine = [wrongLine, linecount]; % �����¼������ı��к�
                    if debug == 0
                        continue;
                    end
                end
                for j = 1 : pathNo  % ��ȡ������ÿ�����ﾶ����
                    index = 215 + 48*(j-1);
                    No = str2double(line(index+(1:2)));
                    if No == 1
                        parameter(1).pathPara(prn).codePhaseDelay(No,k) = 0;
                        parameter(1).codePhaseErr(prn, k) = str2double(line(index+(4:11)));
                    else
                        parameter(1).pathPara(prn).codePhaseDelay(No,k) = str2double(line(index+(4:11)));
                    end
                    parameter(1).pathPara(prn).ampI(No,k) = str2double(line(index+(13:23)));
                    parameter(1).pathPara(prn).ampQ(No,k) = str2double(line(index+(25:35)));
                    parameter(1).pathPara(prn).SNR(No,k) = str2double(line(index+(37:41)));
                    parameter(1).pathPara(prn).CNR(No,k) = str2double(line(index+(43:47)));
                end
            case 'G' % GPSϵͳ
                satNum_GPS = satNum_GPS + 1;
                prn = str2double(line(2:3));
                parameter(2).prnNo(satNum_GPS, k) = prn;
                if ~ismember(prn, parameter(2).prnMax)
                    parameter(2).prnMax = [parameter(2).prnMax, prn];
                end
                parameter(2).Elevation(prn,k) = str2double(line(5:9));
                if parameter(2).Elevation(prn,k) < 0 % ����¼����С��0��������
                    wrongLine = [wrongLine, linecount]; % �����¼������ı��к�
                    if debug == 0
                        continue;
                    end
                end
                parameter(2).Azimuth(prn,k) = str2double(line(11:16));
                Pseudorange = str2double(line(18:31));
                if abs(Pseudorange) > 99999999 % ����¼α���쳣��������
                    wrongLine = [wrongLine, linecount]; % �����¼������ı��к�
                    if debug == 0
                        continue;
                    end
                end
                parameter(2).Pseudorange(prn,k) = Pseudorange;
                parameter(2).InteDopp(prn,k) = str2double(line(33:46));
                parameter(2).TransTime(prn,k) = str2double(line(48:66));
                parameter(2).carriErr(prn,k) = str2double(line(68:75))*360;
                parameter(2).carriPhase(prn,k) = str2double(line(77:84));
                parameter(2).doppFreq(prn,k) = str2double(line(86:98)) - 1575420000;
                parameter(2).codePhase(prn,k) = str2double(line(100:109));
                parameter(2).satClkErr(prn,k)= str2double(line(189:202));
                parameter(2).satClkDrift(prn,k) = str2double(line(204:211));
                parameter(2).satPos(prn).position(1:3,k) = [str2double(line(111:124));str2double(line(126:139));str2double(line(141:154))];
                parameter(2).satPos(prn).velocity(1:3,k) = [str2double(line(156:165));str2double(line(167:176));str2double(line(178:187))];
                parameter(2).pathNum(prn,k) = str2double(line(213:214));
                pathNo = parameter(2).pathNum(prn,k);
                if pathNo > 5 % ����¼α���쳣��������
                    wrongLine = [wrongLine, linecount]; % �����¼������ı��к�
                    if debug == 0
                        continue;
                    end
                end
                for j = 1 : pathNo  % ��ȡ������ÿ�����ﾶ����
                    index = 215 + 48*(j-1);
                    No = str2double(line(index+(1:2)));
                    if No == 1
                        parameter(2).pathPara(prn).codePhaseDelay(No,k) = 0;
                        parameter(2).codePhaseErr(prn, k) = str2double(line(index+(4:11)));
                    else
                        parameter(2).pathPara(prn).codePhaseDelay(No,k) = str2double(line(index+(4:11)));
                    end
                    parameter(2).pathPara(prn).ampI(No,k) = str2double(line(index+(13:23)));
                    parameter(2).pathPara(prn).ampQ(No,k) = str2double(line(index+(25:35)));
                    parameter(2).pathPara(prn).SNR(No,k) = str2double(line(index+(37:41)));
                    parameter(2).pathPara(prn).CNR(No,k) = str2double(line(index+(43:47)));
                end
        end % EOF : switch sys
    end % EOF : for i = 1 : satNum
end % EOF : while 1
parameter(1).prnMax = sort(parameter(1).prnMax);
parameter(2).prnMax = sort(parameter(2).prnMax);