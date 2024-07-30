% �Ƿ����¶�ȡ�ļ�

close all;
clear;clc;fclose all;
isRead = 1;
isReadMat = 1;
num_file = '6';  
file_path = 'K:\�½��ļ���';
logFileName = strcat(file_path, '\Lujiazui_Static_Point_',...
    num_file,'\Lujiazui_Static_Point_',num_file,'_allObs.txt');
xlsName = strcat(file_path, '\Lujiazui_Static_Point_',...
    num_file, '\Lujiazui_Static_Point_',num_file,'_auto.xlsx'); 
paraName = strcat(file_path, '\Lujiazui_Static_Point_',...
    num_file, '\parameter_',num_file,'.mat'); 
sowName = strcat(file_path, '\Lujiazui_Static_Point_',...
    num_file, '\SOW_',num_file,'.mat'); 
if isRead
    if isReadMat
        paraName = 'parameters_xuhui.mat';
        sowName = 'SOW_xuhui.mat';
        load(paraName);
        load(sowName);
    else
        logFileName = 'K:\�½��ļ���\CHN-SH-Xuhui_20160316140000_allObs.txt';
        [parameter, SOW] = readObs(logFileName);
    end
end
prnBDS = parameter(1).prnMax;
prnGPS = parameter(2).prnMax;

timeIndex = SOW(1,:) - SOW(1,1);
sheetName = 'GPS';  % BDS_GEO / BDS_IGSO / BDS_MEO / GPS / occurance
prn = 2;
xlsLine = '2';
sys = 'BDS'; % BDS / GPS
isWriteXls = 0;
window = 200000; %�������Ƶ�ƵĴ��ڴ�С
timeInterval = 0.1; % second
loopPhase = 200; %�������ܵ���λ��

lifeTime_ALL = [1, length(timeIndex)]; % �ж������Ƿ���Լ�����������

%������������������������ԭʼ���ݼ�¼����������������%
[multiPara, multipathNum] = logRead_MP(parameter, sys, prn, timeIndex); 

%���������������������Զ������ݴ��� ��������������������
[multiPara] = MP_process_auto(multiPara , sys, multipathNum, sheetName, timeIndex);

%��������������������������Ҫ��¼������ ��������������������
[multiPara] = MPrecord_update(multiPara, multipathNum, lifeTime_ALL, timeIndex);
        
%����������������������ͼ������������������������%    
plot_MP_figure(multiPara, prn, multipathNum, sys); 

%����������������������¼excel�ĵ� ��������������������
if isWriteXls  
    MP_xls_write(xlsName, multiPara, sheetName, multipathNum, xlsLine, sys, prn);
end










