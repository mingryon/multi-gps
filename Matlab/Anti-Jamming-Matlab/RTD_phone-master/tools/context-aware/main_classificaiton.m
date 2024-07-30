clc; 
close all;
isRead = 0;
if isRead
    clear; 
    load CNR_std_ublox.mat;
    isInt = 0;  % ����ȡ���봦���ݣ���Ϊ�궨���ݽ������봦
    class_name_all = categorical({'canyon', 'urban', 'surburb', 'viaduct_up', 'viaduct_down', 'boulevard'});
    fileNum = 6;
    fileNo = [1:6];
    fileType = [1, 1, 1, 3, 1, 1, 3];% [1, 1, 1, 2, 1, 1];% [1, 1, 1, 1, 3, 1, 1];  % �궨��������
    [filename, fileCalib, fileEphBds, fileEphGps, YYMMDD, TYPE] = fileNameInitial();
    [parameter, calibration] = paraInitial(fileNum);
    for k = 1 : fileNum
        i = fileNo(k);
        [parameter(i)] = readNMEA(parameter(i), filename{i}, YYMMDD{i}, fileEphBds{i}, fileEphGps{i}, isInt, TYPE{i});
        [calibration(i)] = readCalib(calibration(i), fileCalib{i}, YYMMDD{i}, fileType(i));
        [parameter(i)] = ephStateCal(parameter(i), fileEphBds{i}, fileEphGps{i});
        [parameter(i)] = posENU_error(parameter(i), calibration(i), fileType(i));
    end
    % �������������������� ��ʼ����֤���ݲ��� ������������������������%
    i = i + 1; % ��7���ļ���������֤ʶ���㷨
    [parameter_NewData, calibration_NewData] = paraInitial(1);
    [parameter_NewData] = readNMEA(parameter_NewData, filename{i}, YYMMDD{i}, fileEphBds{i}, fileEphGps{i}, isInt, TYPE{i});
    [calibration_NewData] = readCalib(calibration_NewData, fileCalib{i}, YYMMDD{i}, fileType(i));
    [parameter_NewData] = ephStateCal(parameter_NewData, fileEphBds{i}, fileEphGps{i});
    [parameter_NewData] = posENU_error(parameter_NewData, calibration_NewData, fileType(i));
end

isTrain = 1; % ѵ������
isPredict = 1; % Ԥ��������
isSVM = 1;
class_name = categorical();
processMode = 3; % ����Ԥ����ģʽ: �������ƽ����1��  /   ����ʱ��ƽ����2�� /  ������3��
valueMode = 1; % ��һ���Ҿ���atan�任��1��  /  ��һ�������� ��2��  /  ԭʼ���� ��3��
isSmooth = 0; % Ԥ�����˲�ƽ��
feaChoose = 2; % ������ȡ����������1��  /   ��ͳ��������2��  /  ���ԣ�3��

%% %%%%%%%%%%  ��������  %%%%%%%%%%%%%%%%%%
if isTrain %  3 4 5 7 8
%     CNR_std_modi = [0, 0, 1, 2, 0, 0]; % ��ͬ�ļ��ı�׼����Ȳ�ͬ����Ҫ��һ������
    CNR_std_modi = [4, -3, 1, 2, 0, 0]; % ��ͬ�ļ��ı�׼����Ȳ�ͬ����Ҫ��һ������
    [feaCluster, feaFile, clusterLen, timeLen] = featureCluster(parameter, fileNum, CNR_std_ublox, CNR_std_modi, isInt);
    % �Ը����������ϳ�������ǩ
    for i = 1 : fileNum
        class_name_part = categorical();
        class_name_part(1:timeLen(i), 1) = class_name_all(i);
        class_name = [class_name; class_name_part];
    end
    % ��������Ԥ����  paraRaw_Norm_atan / paraRaw_Norm
    switch valueMode
        case 1
            feaUsed = feaCluster.paraRaw_Norm_atan;
        case 2
            feaUsed = feaCluster.paraRaw_Norm;
        case 3
            feaUsed = feaCluster.paraRaw;
    end
    [feature_Modify] = featureModify(feaUsed, timeLen, fileNum, parameter, processMode); 
    N = sum(timeLen);
    % ������������ȡ
    svNum = feature_Modify(:, 1); % �ɼ�������
    GDOP = feature_Modify(:, 2); % DOPֵ
    cnrMean = feature_Modify(:, 3); % ����Ⱦ�ֵ 
    cnrVar = feature_Modify(:, 4); % ����ȷ��� 
    cnrFluc = feature_Modify(:, 5); % ����Ȳ�����ֵ 
    blockNum = feature_Modify(:, 6); % �����ڵ���
    blockProp = feature_Modify(:, 7); % �ڵ�����
    GDOP_ratio = feature_Modify(:, 8); % DOPֵ�������
    % ������Ծ���ͷ��������
    if feaChoose == 1
        feature_class = table(cnrMean, cnrVar, cnrFluc, blockProp, GDOP_ratio, class_name);
        predictorNames = {'cnrMean', 'cnrVar', 'cnrFluc', 'blockProp', 'GDOP_ratio'};
    elseif feaChoose == 2
        feature_class = table(cnrMean, cnrVar, svNum, GDOP, class_name);
        predictorNames = {'cnrMean', 'cnrVar', 'svNum', 'GDOP'};
    elseif feaChoose == 3
        feature_class = table(cnrMean, cnrVar, cnrFluc, class_name);
        predictorNames = {'cnrMean', 'cnrVar', 'cnrFluc'};
    end
   %%%%%%%%%%%%  ����ѵ��  %%%%%%%%%%%%%%%%%%%
    % ��������������������  SVM  ������������������������%
    if isSVM
        [trClass_SVM, valAccu_SVM, valPredi_SVM, valScores_SVM] = trainClassifier_SVM(feature_class, predictorNames);
        [ScoreSVMModel,ScoreTransform] = fitPosterior(trClass_SVM);
        [valPredi_SVM_Num, standard_Num] = plotClassResult(valPredi_SVM, class_name, N, class_name_all);
        if isSmooth
            [valPredi_SVM_Num] = predictSmooth(valPredi_SVM_Num, feaFile, timeLen, fileNum);
        end
        [predictResult, Predi_SVM_bin] = resultAnalysis(valPredi_SVM_Num, standard_Num, fileNum, timeLen);
    end
end % if isTrain




%% ��������������������  ������Ԥ��  ������������������������%
if isPredict
     % ��֤����
    CNR_std_modi_NewData = 0;
    [feaCluster_NewData, feaFile_NewData, clusterLen_NewData, timeLen_NewData] = featureCluster(parameter_NewData, 1, CNR_std_ublox, CNR_std_modi_NewData, isInt);
    switch valueMode
        case 1
            feaUsed = feaCluster_NewData.paraRaw_Norm_atan;
        case 2
            feaUsed = feaCluster_NewData.paraRaw_Norm;
        case 3
            feaUsed = feaCluster_NewData.paraRaw;
    end
    [feature_Modify_NewData] = featureModify(feaUsed, timeLen_NewData, 1, parameter_NewData, processMode);
    N_NewData = sum(timeLen_NewData);

     % ��֤���ݲ���
    svNum = feature_Modify_NewData(:, 1); % �ɼ�������
    GDOP = feature_Modify_NewData(:, 2); % DOPֵ
    cnrMean = feature_Modify_NewData(:, 3); % ����Ⱦ�ֵ 
    cnrVar = feature_Modify_NewData(:, 4); % ����ȷ��� 
    cnrFluc = feature_Modify_NewData(:, 5); % ����Ȳ�����ֵ 
    blockNum = feature_Modify_NewData(:, 6); % �����ڵ���
    blockProp = feature_Modify_NewData(:, 7); % �ڵ�����
    GDOP_ratio = feature_Modify_NewData(:, 8); % DOPֵ�������
     % ������Ծ���ͷ��������
    if feaChoose == 1
        feature_class_NewData = table(cnrMean, cnrVar, cnrFluc, blockProp, GDOP_ratio);   
    elseif feaChoose == 2
        feature_class_NewData = table(cnrMean, cnrVar, svNum, GDOP);
    elseif feaChoose == 3
        feature_class_NewData = table(cnrMean, cnrVar, cnrFluc);
    end
    % ������Ԥ��
    [yfit, valScores_SVM_NewData] = trClass_SVM.predictFcn(feature_class_NewData);
    yfit_Num = zeros(N_NewData, 1);
    for j = 1 : fileNum
        index_1 = yfit == class_name_all(j);
        yfit_Num(index_1) = j;
    end
    if isSmooth
        [yfit_Num] = predictSmooth(yfit_Num, feaFile_NewData, timeLen_NewData, 1);
    end
    figure();
    scatter(feaCluster_NewData.pos_enu(:, 1), feaCluster_NewData.pos_enu(:, 2), fileNum, yfit_Num, 'filled');
    title('NewDataPrediction');
    colormap(hsv(fileNum));
    colorbar;
end


% yfit_Num_temple = yfit_Num(3660 : 4270);
% predictResult_temp = zeros(6,1);
% for i = 1 : 6
%     predictResult_temp(i) = sum(yfit_Num_temple==i)/length(yfit_Num_temple);
% end






















% clc; 
% close all;
% isRead = 1;
% if isRead
%     clear; 
%     load CNR_std_ublox.mat;
%     class_Num = 6;
%     isInt = 1;  % ����ȡ���봦���ݣ���Ϊ�궨���ݽ������봦
%     class_name_all = categorical({'canyon', 'urban', 'surburb', 'viaduct_up', 'viaduct_down', 'boulevard'});
%     fileNum = 6;
%     fileType = [1, 2, 1, 2, 1, 1];  % �궨��������
%     [filename, fileCalib, fileEphBds, fileEphGps, YYMMDD, TYPE] = fileNameInitial();
%     [parameter, calibration] = paraInitial(fileNum);
%     for i = 1 : fileNum
%         [parameter(i)] = readNMEA(parameter(i), filename{i}, YYMMDD{i}, fileEphBds{i}, fileEphGps{i}, isInt, TYPE{i});
%         [calibration(i)] = readCalib(calibration(i), fileCalib{i}, YYMMDD{i}, fileType(i));
%         [parameter(i)] = ephStateCal(parameter(i), fileEphBds{i}, fileEphGps{i});
%         [parameter(i)] = posENU_error(parameter(i), calibration(i), fileType(i));
%     end
% end
% isKNN = 0;
% isSVM = 1;
% isKMEAN = 0;
% isGMM = 0;
% isHCLU = 0;
% class_name = categorical();
% mode = 3; % ����Ԥ����ģʽ: �������ƽ����1��  /   ����ʱ��ƽ����2�� /  ������3��
% %% %%%%%%%%%%  ��������  %%%%%%%%%%%%%%%%%%
% [feature_Norm, feature, timeLen, pos_xyz, vel, enuMap] = featureGet(parameter, fileNum, CNR_std_ublox);
% N = sum(timeLen);
% % �Ը����������ϳ�������ǩ
% for i = 1 : fileNum
%     class_name_part = categorical();
%     class_name_part(1:timeLen(i), 1) = class_name_all(i);
%     class_name = [class_name; class_name_part];
% end
% 
% % ��������Ԥ����
% [feature_Modify] = featureModify(feature_Norm, timeLen, fileNum, parameter, mode);
% % ������������ȡ
% svNum = feature_Modify(:, 1); % �ɼ�������
% GDOP = feature_Modify(:, 2); % DOPֵ
% cnrMean = feature_Modify(:, 3); % ����Ⱦ�ֵ
% cnrVar = feature_Modify(:, 4); % ����ȷ���
% cnrFluc = feature_Modify(:, 5); % ����Ȳ�����ֵ
% blockNum = feature_Modify(:, 6); % �����ڵ���
% blockProp = feature_Modify(:, 7); % �ڵ�����
% GDOP_ratio = feature_Modify(:, 8); % DOPֵ�������
% % ������Ծ���ͷ��������
% feature_class = table(svNum, GDOP, cnrMean, cnrVar, cnrFluc, blockNum, blockProp, GDOP_ratio, class_name);
% 
% %% %%%%%%%%%%%%  ����ѵ��  %%%%%%%%%%%%%%%%%%%
% predictorNames = {'svNum', 'GDOP', 'cnrMean', 'cnrVar'};
% % ��������������������  KNN  ������������������������%
% if isKNN
%     [trClass_KNN, valAccu_KNN, valPredi_KNN, valScores_KNN] = trainClassifier_KNN(feature_class, predictorNames);
%     [valPredi_KNN_Num, standard_Num] = plotClassResult(valPredi_KNN, class_name, enuMap, N, class_name_all, 'KNN');
% end
% 
% % ��������������������  SVM  ������������������������%
% if isSVM
%     [trClass_SVM, valAccu_SVM, valPredi_SVM, valScores_SVM] = trainClassifier_SVM(feature_class, predictorNames);
%     [valPredi_SVM_Num, standard_Num] = plotClassResult(valPredi_SVM, class_name, enuMap, N, class_name_all, 'SVM');
% %     [valPredi_SVM_Num] = predictSmooth(valPredi_SVM_Num, parameter, timeLen, fileNum);
%     [predictResult, Predi_SVM_bin] = resultAnalysis(valPredi_SVM_Num, standard_Num, fileNum, timeLen);
% end




