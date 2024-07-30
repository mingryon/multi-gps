clc; 
close all;
isRead = 0;
if isRead
    clear; 
    load CNR_std_ublox.mat;
    isInt = 0;  % ����ȡ���봦���ݣ���Ϊ�궨���ݽ������봦
    class_name_all = categorical({'canyon', 'urban', 'surburb', 'boulevard', 'viaduct_down'});
    fileNum = 5;
    fileNo = 1:5; 
    [filename, fileCalib, fileEphBds, fileEphGps, YYMMDD, TYPE] = fileNameInitial();
    [parameter, calibration] = paraInitial(fileNum);
    for k = 1 : length(fileNo)
        i = fileNo(k);
        [parameter(i)] = readNMEA(parameter(i), filename{i}, YYMMDD{i}, fileEphBds{i}, fileEphGps{i}, isInt, TYPE{i});
        [parameter(i)] = ephStateCal(parameter(i), fileEphBds{i}, fileEphGps{i});
    end
end

isFeaCal = 1; % ���¼����ź���������
isKmean = 1;

isPlot = 1; 
class_name = categorical();
mode = 3; % ����Ԥ����ģʽ: �������ƽ����1��  /   ����ʱ��ƽ����2�� /  ������3��

%% %%%%%%%%%%  ��������  %%%%%%%%%%%%%%%%%%
if isFeaCal %  3 4 5 7 8
%     parameter(1).prnNo_useless = [18]; % ����������ȵ����Ǻ�
%     parameter(6).prnNo_useless = [5, 13]; % ����������ȵ����Ǻ�

    CNR_std_modi = [0, 0, 0, 0, 0, 0, 0]; % ��ͬ�ļ��ı�׼����Ȳ�ͬ����Ҫ��һ������

    [feaCluster, feaFile, timeLen] = featrueDatabase(parameter, fileNum, CNR_std_ublox, CNR_std_modi, isInt);
    % ��������Ԥ����
    [feature_Modify] = featureModify(feaCluster.paraRaw_Norm_atan, timeLen, fileNum, parameter, mode);
    % ������������ȡ
    inSvRatio = feature_Modify(:, 1); % ���ɼ����Ǳ���
    attRatio = feature_Modify(:, 2); % �źŲ����ǵı���
    attDegree = feature_Modify(:, 3); % �źŲ����ǵľ�ֵ
    cnrFluc = feature_Modify(:, 4); % ����Ȳ�����ֵ 
    GDOP_ratio = feature_Modify(:, 5); % DOPֵ�������
end % if isFeaCal

feaStatis = zeros(fileNum, 5);
for i = 1 : fileNum
    feaStatis(i, :) = mean(feaFile(i).para, 1);
end



