% �Ƿ����¶�ȡ�ļ�
clc;
close all;clear;clc;fclose all;
fileNum = 26;
fileNo = [1:23, 25, 26, 27];

file = struct(...
    'logFileName', '',...
    'paraName',    '',...
    'sowName',    '',...
    'xlsName',     '',...
    'xlsName_all', ''... %��ͳ�Ʊ��
    );
file(1:fileNum) = file;
%������������������¼�ļ�����������������������������%
file_path = 'E:\���ݴ�����\Lujiazui_Static_Point_v2';
for ii = 1: fileNum 
    num_file = num2str(fileNo(ii));
    file(ii).logFileName = strcat(file_path, '\Lujiazui_Static_Point_',...
        num_file,'\Lujiazui_Static_Point_',num_file,'_allObs.txt');
    
    file(ii).paraName = strcat(file_path, '\Lujiazui_Static_Point_',...
        num_file, '\parameter_',num_file,'.mat'); 
    
    file(ii).sowName = strcat(file_path, '\Lujiazui_Static_Point_',...
        num_file, '\SOW_',num_file,'.mat'); 
    
end


% ������������ͨ�����ò�����������������������%

for ii = 1 : fileNum
    num_file = num2str(fileNo(ii));
    fprintf('���ڴ����ļ��ţ� %d \n', fileNo(ii));
    %�����������������ļ�ѭ��������������%
    clear parameter;
    clear SOW;

    [parameter, SOW] = readObs(file(ii).logFileName);
    save(file(ii).paraName, 'parameter');
    save(file(ii).sowName, 'SOW');
 
end



