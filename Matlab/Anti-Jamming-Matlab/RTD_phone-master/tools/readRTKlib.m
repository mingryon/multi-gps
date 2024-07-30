function [XYZ, TOWSEC] = readRTKlib(filename)
% filename='G:\positionVisible\code\data file\MinhangTV_Moving_1-1050s_GPGGA.txt';   % �����ļ�����

fid = fopen(filename);
if fid==-1
   error('message data file not found or permission denied');
end
frewind(fid)
%  Loop through the file
k = 0;  breakflag = 0;
while 1     % this is the numeral '1'
   line = fgetl(fid);
   if ~ischar(line)
       breakflag = 1; 
       break;
   end
   if strcmp(line(1),'%')
       continue;
   end

   k = k + 1;    
   TOWSEC(k) = str2double(line(6:15));   % ��ǰ������������
   latitude(k) = str2double(line(19:30));
   longitude(k) = str2double(line(33:45));
   height(k) = str2double(line(48:56));         
   LLH(k,:) = [latitude(k), longitude(k), height(k)];
   XYZ(k,:) = llh2xyz(LLH(k,:));  % ת��Ϊxyz����   
%    waitbar(linecount/numlines,bar1)
end  % End the WHILE 1 Loop
fclose(fid);