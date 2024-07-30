function [XYZ, LLH, TOWSEC, HHMMSS] = readCalib_IE(filename)
%   function :  Read the calibration file which is processed by Inertial Explorer
%         
%   Input:
%       filename = 'E:\calibration\xxx.txt';  % The file name with detailed path
%   
%	Output:
%       calibPara = 
%       llh(3) = height above ellipsoid in meters
%
%	xyz(1) = ECEF x-coordinate in meters
%	xyz(2) = ECEF y-coordinate in meters
%	xyz(3) = ECEF z-coordinate in meters



fid = fopen(filename);
if fid==-1
   error('Calibration file not found or permission denied');
end
frewind(fid)
%�������������������� ��ȡ�ܹ���¼ʱ�̴��� ����������������%
lineNum = 0;
while ~feof(fid)
    line = fgetl(fid);
    lineNum = lineNum + 1;
    if strcmp(line(1:9), 'Data Date')
        year = str2double(line(14:17));
        month = str2double(line(19:20));
        day = str2double(line(22:23));
    end
    if strcmp(line(1:5), 'START')
        headLineNum = lineNum; % the line number of head message
        fidData = fid;
    end
end
epochNum = lineNum - headLineNum; % the line number of data calibration message
frewind(fid)


calibPara = struct(...
    'SOW',           [],...                          % �˶��������пɼ������źŵ�PRN��
    'LLH',              nan(epochNum,3),...      % ��ǰʱ�̿ɼ����ǵ�PRN��
    'XYZ',              nan(epochNum,logCount),...             % PDOPֵ [1 �� ��¼ʱ��]
    'localClkErr',      nan(1,logCount),...             % �����Ӳ� [1 �� ��¼ʱ��]
    'localClkDrift',    nan(1,logCount),...             % ������Ư [1 �� ��¼ʱ��]
    'Elevation',        nan(maxPrnNo,logCount),...      % ���� [����PRN�� �� ��¼ʱ��]
    'Azimuth',          nan(maxPrnNo,logCount),...      % ��λ�� [����PRN�� �� ��¼ʱ��]
    'Pseudorange',      nan(maxPrnNo,logCount),...      % α�� [����PRN�� �� ��¼ʱ��]
    'InteDopp',         nan(maxPrnNo,logCount),...      % ���ֶ����� [����PRN�� �� ��¼ʱ��]
    'TransTime',        nan(maxPrnNo,logCount),...      % �źŷ���ʱ�� [����PRN�� �� ��¼ʱ��]
    'carriErr',         nan(maxPrnNo,logCount),...      % �ز����������� ���㣩[����PRN�� �� ��¼ʱ��]
    'carriPhase',       nan(maxPrnNo,logCount),...      % �ز���λֵ [����PRN�� �� ��¼ʱ��]
    'doppFreq',        nan(maxPrnNo,logCount),...      % �ز�Ƶ�� [����PRN�� �� ��¼ʱ��]
    'codePhase',        nan(maxPrnNo,logCount),...      % ��Ƶ����λ [����PRN�� �� ��¼ʱ��]
    'satPos',           '',...                          % ����λ��
    'satClkErr',        nan(maxPrnNo,logCount),...      % �����Ӳ� [����PRN�� �� ��¼ʱ��]
    'satClkDrift',      nan(maxPrnNo,logCount),...      % �����Ӳ�Ư�� [����PRN�� �� ��¼ʱ��]
    'pathNum',          nan(maxPrnNo,logCount),...      % �ź�·����Ŀ [����PRN�� �� ��¼ʱ��]
    'codePhaseErr',     nan(maxPrnNo,logCount),...      % �ྶ���������λƫ�� [����PRN�� �� ��¼ʱ��]
    'pathPara',         ''...
    );






%  Loop through the file
k = 0;  breakflag = 0;
headEnd = 0;  % ����ͷ�ļ�
while 1     % this is the numeral '1'
   line = fgetl(fid);
   if ~ischar(line)
       breakflag = 1; 
       break;
   end
   if strcmp(line(1:5),'ho mi')
       headEnd = 1;
       continue;
   end
   if headEnd == 0
       continue;
   end
   k = k + 1;    
   hour = str2double(line(1:2));
   min  = str2double(line(4:5));
   sec  = str2double(line(7:11));
   todsec = 3600*hour + 60*min + sec;  % time of day in seconds       
   daynum = dayofweek(year,month,day);
   TOWSEC(k) = todsec + 86400*daynum;   % ��ǰ������������
   HHMMSS(1, k) = hour;
   HHMMSS(2, k) = min;
   HHMMSS(3, k) = sec;
   latitude(k) = str2double(line(13:26));
   longitude(k) = str2double(line(28:41));
   height(k) = str2double(line(43:54));         
   LLH(k,:) = [latitude(k), longitude(k), height(k)];
   XYZ(k,:) = llh2xyz(LLH(k,:));  % ת��Ϊxyz����   
%    waitbar(linecount/numlines,bar1)
end  % End the WHILE 1 Loop
fclose(fid);