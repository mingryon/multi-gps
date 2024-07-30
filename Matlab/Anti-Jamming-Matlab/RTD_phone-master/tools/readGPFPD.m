function [XYZ, TOWSEC] = readGPFPD(filename)
% filename='G:\positionVisible\code\data file\guandaogpfpd.txt';   % �����ļ�����
decimate_factor=1;     %  If it is equal to '1', then every data point is read in and stored.  If it is equal
%                        to '2', then every second data point is stored.
%                        If '3', then every third data point is stored,
%                        et cetera.
if decimate_factor < 1, error('decimate_factor must be a positive integer'), end
if rem(decimate_factor,1) > 0, error('decimate_factor must be a positive integer'), end
fid = fopen(filename);
if fid==-1
   error('message data file not found or permission denied');
end
% numlines = 0;
% while 1     % this is the numeral '1'
%    numlines = numlines + 1;
%    %
%    line = fgetl(fid);
%    if ~ischar(line), break, end
% end
frewind(fid)
%  Loop through the file
k = 0;  breakflag = 0;
while 1     % this is the numeral '1'
   k = k + 1;    % 'k' is keeping track of our time steps
   numBit = 0; % ���ŵĸ���
   for ideci = 1:decimate_factor,
       %
       line = fgetl(fid);
       if ~ischar(line), breakflag = 1; break, end 
       len = length(line);    
       for ii = 1:len 
           if strcmp(line(ii), ',')
               numBit = numBit + 1;     % ���Ÿ�����1
               if numBit == 2                 
                   TOWSEC(k) = str2double(line(ii+1:ii+10));   % ��ǰ������������
               end
               if numBit == 6
                   latitude(k) = str2double(line(ii+1:ii+10));
               end
               if numBit == 7
                   longitude(k) = str2double(line(ii+1:ii+11));
               end
               if numBit == 8
                   height(k) = str2double(line(ii+1:ii+5));
               end
               if numBit == 9
                   if strcmp(line(ii+1),'-')
                       velocity_E(k) = str2double(line(ii+1:ii+6));
                   else 
                       velocity_E(k) = str2double(line(ii+1:ii+5));
                   end
               end
               if numBit == 10
                   if strcmp(line(ii+1),'-')
                       velocity_N(k) = str2double(line(ii+1:ii+6));
                   else 
                       velocity_N(k) = str2double(line(ii+1:ii+5));
                   end
               end 
               if numBit == 11
                   if strcmp(line(ii+1),'-')
                       velocity_U(k) = str2double(line(ii+1:ii+6));
                   else 
                       velocity_U(k) = str2double(line(ii+1:ii+5));
                   end
               end
           end
       end   % End the "for i = 1:numsvs(k)" Loop
   end  % End the "for ideci = 1:decimate_factor" Loop
   if breakflag == 1, break, end
   LLH(k,:) = [latitude(k), longitude(k), height(k)];
   XYZ(k,:) = llh2xyz(LLH(k,:));  % ת��Ϊxyz����   
%    waitbar(linecount/numlines,bar1)
end  % End the WHILE 1 Loop
fclose(fid);
