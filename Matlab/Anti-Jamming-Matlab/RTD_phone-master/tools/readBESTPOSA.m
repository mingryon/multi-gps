function [XYZ, LLH, Vel, TOWSEC] = readBESTPOSA(filename)
% filename='L:\20150803\20150803novatel\0803test.ASC';   % �����ļ�����
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
    numBit = 0; % ���ŵĸ���
    line = fgetl(fid);
    if ~ischar(line), breakflag = 1; break, end
    if ~strcmp(line(1:9), '#BESTPOSA')
        continue;
    end
    k = k + 1;    % 'k' is keeping track of our time steps
    len = length(line);
    for ii = 1:len
        if strcmp(line(ii), ',')
            numBit = numBit + 1;     % ���Ÿ�����1
            if numBit == 6
                TOWSEC(k) = str2double(line(ii+1:ii+9));   % ��ǰ������������
            end
            if numBit == 11
                latitude = str2double(line(ii+1:ii+14));
            end
            if numBit == 12
                longitude = str2double(line(ii+1:ii+15));
            end
            if numBit == 13
                height = str2double(line(ii+1:ii+6));
            end
            if numBit == 16
                Vx = str2double(line(ii+1:ii+6));
            end
            if numBit == 17
                Vy = str2double(line(ii+1:ii+6));
            end
            if numBit == 18
                Vz = str2double(line(ii+1:ii+6));
            end
            
        end
    end   % End the "for i = 1:numsvs(k)" Loop
    
    if breakflag == 1, break, end
    LLH(k,:) = [latitude, longitude, height];
    XYZ(k,:) = llh2xyz(LLH(k,:));  % ת��Ϊxyz����
    Vel(k,:) = [Vx, Vy, Vz];
    %    waitbar(linecount/numlines,bar1)
end  % End the WHILE 1 Loop
fclose(fid);
