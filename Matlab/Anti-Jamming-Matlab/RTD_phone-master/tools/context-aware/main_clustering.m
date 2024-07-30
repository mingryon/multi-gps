clc; 
close all;
isRead = 0;
if isRead
    clear; 
    load CNR_std_ublox.mat;
    isInt = 1;  % ����ȡ���봦���ݣ���Ϊ�궨���ݽ������봦
    class_name_all = categorical({'canyon', 'urban', 'surburb', 'open', 'viaduct_down', 'boulevard'});
    fileNum = 6;
    fileNo = [1:6];
    fileType = [1, 1, 1, 1, 1, 1];% [1, 1, 1, 2, 1, 1];% [1, 1, 1, 1, 3, 1, 1];  % �궨��������
    [filename, fileCalib, fileEphBds, fileEphGps, YYMMDD, TYPE] = fileNameInitial();
    [parameter, calibration] = paraInitial(fileNum);
    for k = 1 : length(fileNo)
        i = fileNo(k);
        [parameter(i)] = readNMEA(parameter(i), filename{i}, YYMMDD{i}, fileEphBds{i}, fileEphGps{i}, isInt, TYPE{i});
        [calibration(i)] = readCalib(calibration(i), fileCalib{i}, YYMMDD{i}, fileType(i));
        [parameter(i)] = ephStateCal(parameter(i), fileEphBds{i}, fileEphGps{i});
        [parameter(i)] = posENU_error(parameter(i), calibration(i), fileType(i));
    end
end

isFeaCal = 0; % ���¼����ź���������
isKmean = 1;
isGMM = 0;
isPosErr = 0; % ���ݶ�λ�����о������
isSmooth = 0; % ����������ƽ�����پ���
isMerge = 1; % �Ծ���������һ���������ϲ�
isPCA = 0; % ����PCA����
isPlot = 1; 
class_name = categorical();
mode = 3; % ����Ԥ����ģʽ: �������ƽ����1��  /   ����ʱ��ƽ����2�� /  ������3��
class_Num_all = 10; % ������������
cluster_Times = 1; % ���ڳ�ʼֵ��ͬ���ܵľ������
%% %%%%%%%%%%  ��������  %%%%%%%%%%%%%%%%%%
if isFeaCal %  3 4 5 7 8
    parameter(1).prnNo_useless = [18]; % ����������ȵ����Ǻ�
    parameter(6).prnNo_useless = [5, 13]; % ����������ȵ����Ǻ�
%     parameter(1).prnNo_useless = [7, 8]; % ����������ȵ����Ǻ�
    CNR_std_modi = [0, 2, -1, 0, 0, 0, 0]; % ��ͬ�ļ��ı�׼����Ȳ�ͬ����Ҫ��һ������
    [feaCluster, clusterLen, timeLen] = featureCluster(parameter, fileNum, CNR_std_ublox, CNR_std_modi, isInt);
    N_clu = sum(clusterLen);
    N_epoch = sum(timeLen);
    % ��������Ԥ����
    [feature_Modify] = featureModify(feaCluster.paraRaw_Norm_atan, timeLen, fileNum, parameter, mode);
    % ������������ȡ
    svNum = feature_Modify(:, 1); % �ɼ�������
    GDOP = feature_Modify(:, 2); % DOPֵ
    cnrMean = feature_Modify(:, 3); % ����Ⱦ�ֵ 
    cnrVar = feature_Modify(:, 4); % ����ȷ��� 
    cnrFluc = feature_Modify(:, 5); % ����Ȳ�����ֵ 
    blockNum = feature_Modify(:, 6); % �����ڵ���
    blockProp = feature_Modify(:, 7); % �ڵ�����
    GDOP_ratio = feature_Modify(:, 8); % DOPֵ�������
    ENU_err = feature_Modify(:, 9); % ����� 
    ENU_err_raw = feaCluster.paraRaw(:, 9); % ԭʼ����� 
end % if isFeaCal

%% ���ö�λ�����г�������
if isPosErr
    pos_clu = [1, 2, 3, 4, 5, 7, 9, 11, 15, 20, 30, 40, 50, 70, 100]; % ���������
    pos_clu_N = length(pos_clu) + 1;
    pos_err = feaCluster.paraRaw(:, 9); % ��λ���
    idx_posErr = zeros(N_epoch, 1);
    % �������������������� ���ݶ�λ������ ��������������������%
    for i = 1 : pos_clu_N
    if i == 1
        row = pos_err < pos_clu(i);
    elseif i == pos_clu_N
        row = pos_err>=pos_clu(i-1);
    else
        row = pos_err>=pos_clu(i-1) & pos_err<pos_clu(i);
    end
    idx_posErr(row) = i;    
    end
    
    if isMerge
        [idx_posErr] = clusterMerge(idx_posErr, feaCluster.smoothIndex);
    end
    
    % �������������������� ��ͼ ������������������������%
%     figure();
%     scatter(feaCluster.pos_enu(:, 1), feaCluster.pos_enu(:, 2), 6, idx_posErr, 'filled');
%     title('PosErr');
%     colormap(hsv(pos_clu_N));
%     colorbar;
end

%% %%%%%%%%%%%%  �������  %%%%%%%%%%%%%%%%%%%
% class_Num = 8;
feature_cluster = [cnrMean, cnrVar, cnrFluc,blockProp, GDOP_ratio];
if isPCA
    [coeff,~,latent] = pca(feature_cluster);
    feature_cluster = feature_cluster * coeff(:, 1:3);
end
class_N = length(class_Num_all);
[ValiIndex, dist_cluster] = ValiInitial(class_N);
for i = 1 : class_N
    class_Num = class_Num_all(i); % ѡ�������������
    
    for j = 1 : cluster_Times
        if isSmooth
            % ������������������������  k-means  ����������������������������
            idxExp = zeros(N_epoch, 1);
            if isKmean
                clu_method = 'Kmeans';
                [idx, k_center] = kmeans(feature_cluster, class_Num);
                for k = 1 : N_clu
                    st = feaCluster.smoothIndex(k, 1);
                    ed = feaCluster.smoothIndex(k, 2);
                    idxExp(st:ed) = idx(k);
                end
            end

            % ������������������������  GMM  ����������������������������
            if isGMM
                clu_method = 'GMM';
                options = statset('MaxIter', 3000);
                GMModel = fitgmdist(feature_cluster, class_Num, 'Options', options, 'RegularizationValue', 0.01);  % 'Start', S
                [idx, logl, P_matrix, M_distance] = cluster(GMModel, feature_cluster);
                for k = 1 : N_clu
                    st = feaCluster.smoothIndex(k, 1);
                    ed = feaCluster.smoothIndex(k, 2);
                    idxExp(st:ed) = idx(k);
                end
            end

        % ���������������� if isSmooth  �������������������� 
        else % if isSmooth
            if isKmean
                clu_method = 'Kmeans';
                [idx, k_center] = kmeans(feature_cluster, class_Num, 'MaxIter', 200);
                idxExp = idx;
            end
            if isGMM
                clu_method = 'GMM';
                options = statset('MaxIter', 3000);
                GMModel = fitgmdist(feature_cluster, class_Num, 'Options', options, 'RegularizationValue', 0.01);  % 'Start', S
                [idx, logl, P_matrix, M_distance] = cluster(GMModel, feature_cluster);
                idxExp = idx;
            end
        end % if isSmooth
        
        % �������������������������� ����������������ϲ� �������������������������������� %
        idxExpRaw = idxExp;
        if isMerge
            [idxExp] = clusterMerge(idxExp, feaCluster.smoothIndex);
        end
        [idxExp] = idxSort(idxExp, feaCluster.paraRaw(:, 3));  % ���������������
         % �������������������������������� ��������ͼ �������������������������������� %
        if isPlot
            figure();
            scatter(feaCluster.pos_enu(:, 1), feaCluster.pos_enu(:, 2), 7, idxExp, 'filled');
            title(clu_method);
            colormap(hsv(class_Num));
            colorbar;
            if isPCA
                figure();
                scatter3(feature_cluster(:, 1), feature_cluster(:, 2), feature_cluster(:, 3), 7, idxExp, 'filled');
                title('parameters����PCA');
                colormap(hsv(class_Num));
                colorbar;
            end
        end
        
        % �������������������������������� ���������� �������������������������������� %
        [ValiIndex_temp, dist_cluster_temp] = clusterScore(feature_cluster, idxExp, idx_posErr, class_Num);
        dist_cluster(i) = dist_cluster_temp;
        [ValiIndex(i)] = scoreCal(ValiIndex(i), ValiIndex_temp, j);
    end % for j = 1 : cluster_Times
end % for i = 1 : class_N
[feaEachClu] = feaStatistic(feaCluster, idxExp, idxExpRaw, class_Num);  
% eva = evalclusters(feature_cluster, 'kmeans', 'DaviesBouldin', 'KList',[2:20]);  
figure()
boxplot(feaCluster.paraRaw(:, 3), idxExp);
figure()
boxplot(feaCluster.paraRaw(:, 5), idxExp);
figure()
boxplot(feaCluster.paraRaw(:, 7), idxExp);
figure()
boxplot(feaCluster.paraRaw(:, 9), idxExp);

