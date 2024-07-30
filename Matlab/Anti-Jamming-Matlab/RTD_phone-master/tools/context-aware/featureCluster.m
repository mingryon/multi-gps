function [feaCluster, feaFile, clusterLen, timeLen] = featureCluster(parameter, fileNum, CNR_std_ublox, CNR_std_modi, isInt)

% ���������������� [�ɼ���������DOPֵ����ֵ����������ԣ����ڵ����������ڵ�����ϵ��, ���, �ۻ������] ��������������������������������
pNum = 9; % ����������
winLen = 50; % ƽ�����ڳ��� /m
minEpoch = 7; % ƽ�����ڵ���С��Ԫ��Ŀ
isSmooth = 1; % �Ƿ��������ƽ��

%% %������������������������ ����������ʼ�� ������������������������%
timeLen = zeros(fileNum, 1);  % ���ļ�����ȡ��������Ԫ��
clusterLen = zeros(fileNum, 1);  % ���ļ�����ƽ�������Ԫ��
for i = 1 : fileNum
    timeLen(i) = size(parameter(i).SOW, 2);
end
% [�ɼ���������DOPֵ����ֵ��������ڵ�������]
tNum = max(timeLen); % ����Ԫ����

% ������������������������ ���ļ������������ṹ���ʼ��  ����������������������������%
feaFile = struct(...
    'para',          [],...          % ԭʼ��������
    'paraSmooth',    [],...          % ƽ�������������
    'pos_xyz',       [],...          % λ������
    'vel',           [],...          % �ٶ�
    'pos_enu',       [],...          % ��άƽ���ͼ��
    'movLength',     [],...          % �ƶ�����
    'smoothIndex',   [], ...  % �ָ������ֹ����
    'time',           [] ...  % ʱ��ڵ�
    );

para = zeros(tNum, pNum);  % ԭʼ��������
paraSmooth = zeros(tNum, pNum);  % ƽ�������������
pos_xyz = zeros(tNum, 3);  % λ������
vel = zeros(tNum, 1);  % �ٶ�
pos_enu = zeros(tNum, 3);  % ��άƽ��ͼ
smoothIndex = zeros(tNum, 2); % ƽ������ֹ����
movLength = zeros(tNum, 1);  % �ٶ�
time = zeros(tNum, 4); 
feaFile.para = para; % ÿ���ļ�����������
feaFile.paraSmooth = paraSmooth; % ÿ���ļ�ƽ�������������
feaFile.pos_xyz = pos_xyz; % ÿ���ļ�����������
feaFile.vel = vel; % ÿ���ļ�����������
feaFile.pos_enu = pos_enu; % ��άƽ��ͼ
feaFile.movLength = movLength;
feaFile.smoothIndex = smoothIndex; % ÿ���ļ�����������
feaFile.time = time;
feaFile(1:fileNum) = feaFile;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ������������������������ �ܾ���������ʼ��  ����������������������������%
feaCluster = struct(...
    'paraRaw',               [],...  % ԭʼ��������
    'paraRaw_Norm',          [],...  % ��һ��
    'paraRaw_Norm_atan',     [],...  % ������
    'paraSmooth',            [],...  % ������ƽ�������������
    'paraSmooth_Norm',       [],...  % ��һ��
    'paraSmooth_Norm_atan',  [],...  % ������
    'pos_enu',               [],...  % ��άƽ���ͼ��
    'movLength',               [],...  % ����
    'smoothIndex',           [], ...  % �ָ������ֹ����
    'time',           [] ...  % ʱ��ڵ�
    );

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %������������������������  ����������ȡ  ��������������������������������

for i = 1 : fileNum
    index = 0;
    paraFile = parameter(i);  
    for k = 7 : timeLen(i)
        if abs(paraFile.SOW(1,k)-round(paraFile.SOW(1,k))) < 0.01  % ֻ��ȡ�����봦������
            index = index + 1;
            feaFile(i).pos_xyz(index, :) = paraFile.pos_xyz(:, k)';
            feaFile(i).vel(index) = paraFile.vel(k);
            feaFile(i).pos_enu(index, :) = paraFile.pos_enu(:, k)';
            feaFile(i).movLength(index) = paraFile.movLength(k);
            feaFile(i).time(index,:) = paraFile.SOW(1:4, k)';
            % ���������������� 1���ɼ����������� �������������������� %
            if isInt
                satNum = paraFile.satNum(k);
            else
                satNum = paraFile.satNum((k-4):k);
            end
            satNum(isnan(satNum)) = [];            
            feaFile(i).para(index, 1) = mean(satNum);

            %  ���������������� 2��GDOPֵ���� �������������������� %
            if isInt
                GDOP = paraFile.GDOP(k);
            else
                GDOP = paraFile.GDOP((k-4):k);
            end
            GDOP(isnan(GDOP)) = [];           
            feaFile(i).para(index, 2) = mean(GDOP);

            % �������������� 3~5������Ⱦ�ֵ������Ͳ����� ��������������%
            satNum_temp = paraFile.satNum(k);
            prnNo_temp = paraFile.prnNo(1:satNum_temp, k);
            for j = 1 : length(paraFile.prnNo_useless)
                prnNo_temp(prnNo_temp == paraFile.prnNo_useless(j)) = [];  % �˹�ȥ����Ҫɾ�������Ǻ�
            end
            satNum_temp = length(prnNo_temp);
            
            attenuation = zeros(1, satNum_temp);   % ��ֵ������
            atten_var = zeros(1, satNum_temp);   % ������
            if satNum_temp > 1
                for j = 1 : satNum_temp
                    prn = prnNo_temp(j);
                    el = paraFile.Elevation(prn, k);
                    if el == 0
                        CNR_std = CNR_std_ublox(1) + CNR_std_modi(i);
                    else
                        CNR_std = CNR_std_ublox(el) + CNR_std_modi(i);
                    end
                    if isInt
                        atten_temp = paraFile.CNR(prn, k) - CNR_std;
                    else
                        atten_temp = paraFile.CNR(prn, (k-4):k) - CNR_std;
                    end
                    atten_temp(isnan(atten_temp)) = [];
                    attenuation(j) = mean(atten_temp);
                    atten_var(j) = paraFile.CNR_Var(prn, k);
                end
                feaFile(i).para(index, 3) = -mean(attenuation);
                if feaFile(i).para(index, 3) < 0
                    feaFile(i).para(index, 3) = 0;
                end
                feaFile(i).para(index, 4) = sqrt(var(attenuation));
                feaFile(i).para(index, 5) = mean(atten_var);
            elseif satNum_temp == 1
                prn = paraFile.prnNo(1, k);
                el = paraFile.Elevation(prn, k);
                if el == 0
                    CNR_std = CNR_std_ublox(1) + CNR_std_modi(i);
                else
                    CNR_std = CNR_std_ublox(el) + CNR_std_modi(i);
                end
                if isInt
                    atten_temp = paraFile.CNR(prn, k) - CNR_std;
                else
                    atten_temp = paraFile.CNR(prn, (k-4):k) - CNR_std;
                end
                atten_temp(isnan(atten_temp)) = [];
                attenuation(1) = mean(atten_temp);
                atten_var(1) = paraFile.CNR_Var(prn, k);
                feaFile(i).para(index, 3) = -attenuation;
                feaFile(i).para(index, 4) = feaFile(i).para(index-1, 4); % ����ֻ��1����������Ĭ����Ϊ5
                feaFile(i).para(index, 5) = mean(atten_var);
            elseif  satNum_temp == 0
                feaFile(i).para(index, 3) = 40;
                feaFile(i).para(index, 4) = feaFile(i).para(index-1, 4); % ����ֻ��0����������Ĭ����Ϊ5
                feaFile(i).para(index, 5) = feaFile(i).para(index-1, 5);
            end % if paraFile.satNum(k) > 1

            % �������������������� 6�����ڵ������� ��������������������%
            if isInt
                blockNum = paraFile.blockNum(k);
            else
                blockNum = paraFile.blockNum((k-4):k);
            end
            blockNum(isnan(blockNum)) = [];            
            feaFile(i).para(index, 6) = mean(blockNum);

            % �������������������� 7�������ڵ�����ϵ�� ��������������������%
            feaFile(i).para(index, 7) = feaFile(i).para(index, 6) / (feaFile(i).para(index, 6)+feaFile(i).para(index, 1));

            % �������������������� 8��GDOP������� ��������������������%
            if isInt 
                GDOP_ratio = paraFile.GDOP_ratio(k);
            else
                GDOP_ratio = paraFile.GDOP_ratio((k-4):k);
            end
            GDOP_ratio(isnan(GDOP_ratio)) = [];            
            feaFile(i).para(index, 8) = mean(GDOP_ratio);

            % �������������������� 9����λ��� ��������������������%
            feaFile(i).para(index, 9) = paraFile.ENU_error(4, k);
            
        end % if abs(paraFile.SOW-round(paraFile.SOW)) < 0.01
    end % for k = 1 : timeLen(i)
    
    % ����������������  ȥ����Ч�ĵ�  ������������������������%
    feaFile(i).para = feaFile(i).para(1:index, :); % 
    feaFile(i).pos_xyz = feaFile(i).pos_xyz(1:index, :);
    feaFile(i).vel = feaFile(i).vel(1:index, :);
    feaFile(i).pos_enu = feaFile(i).pos_enu(1:index, :);
    feaFile(i).movLength = feaFile(i).movLength(1:index, :);
    feaFile(i).time = feaFile(i).time(1:index, :);
    timeLen(i) = index;  % ����feature��Ŀ
    
end % for i = 1 : fileNum


%% %%%%%%%%%%% �Ը����������ƽ�� %%%%%%%%%%%%%%
if isSmooth
    for i = 1 : fileNum
        % ������������������100��·�ζ����ݽ��зָ����ָ��·�ε���ֹ���� ����������������������������%
        partN = 0;
        st = 1;
        while 1
            partN = partN + 1;
            feaFile(i).smoothIndex(partN, 1) = st;
            lenEnd = feaFile(i).movLength(st) + winLen;
            [~, ed] = min(abs(feaFile(i).movLength - lenEnd));
            if ed - st < minEpoch  % ·�μ����С��minEpoch����Ԫ
                ed = st + minEpoch;
            end
            if (ed > timeLen(i)) || (ed==timeLen(i)-1)   % ��ֹ���겻�������ݳ���
                ed = timeLen(i);
            end
            feaFile(i).smoothIndex(partN, 2) = ed;
            st = ed + 1;
            if st > timeLen(i)
                break;
            end
        end
        feaFile(i).smoothIndex = feaFile(i).smoothIndex(1:partN, :);
        clusterLen(i) = partN;

         % ������������������100��·�ζ����ݽ��зָ����ָ��·�ε�����ֵ ����������������������������%
        for j = 1 : partN
           
            st = feaFile(i).smoothIndex(j, 1);
            ed = feaFile(i).smoothIndex(j, 2);
%             partIndexAll(index, 1) = st + indexAdd;
%             partIndexAll(index, 2) = ed + indexAdd;
            % ���������������� 1���ɼ����������� �������������������� %
            feaFile(i).paraSmooth(j, 1) = mean(feaFile(i).para(st:ed, 1));
            %  ���������������� 2��GDOPֵ���� �������������������� %
            feaFile(i).paraSmooth(j, 2) = mean(feaFile(i).para(st:ed, 2));
            %  ���������������� 3������Ⱦ�ֵ �������������������� %
            feaFile(i).paraSmooth(j, 3) = mean(feaFile(i).para(st:ed, 3));
            %  ���������������� 4������ȷ��� �������������������� %
            feaFile(i).paraSmooth(j, 4) = mean(feaFile(i).para(st:ed, 4));
            %  ���������������� 5������Ȳ����� �������������������� %
            feaFile(i).paraSmooth(j, 5) = mean(feaFile(i).para(st:ed, 5));
            %  ���������������� 6�����ڵ������� �������������������� %
            feaFile(i).paraSmooth(j, 6) = mean(feaFile(i).para(st:ed, 6));
            %  ���������������� 7�������ڵ�����ϵ�� �������������������� %
            feaFile(i).paraSmooth(j, 7) = mean(feaFile(i).para(st:ed, 7));
            %  ���������������� 8��GDOP������� �������������������� %
            feaFile(i).paraSmooth(j, 8) = mean(feaFile(i).para(st:ed, 8));
            %  ���������������� 9����λ��� �������������������� %
            feaFile(i).paraSmooth(j, 9) = mean(feaFile(i).para(st:ed, 9));
        end % for j = 1 : partN
        feaFile(i).paraSmooth = feaFile(i).paraSmooth(1:partN, :);
    end % for i = 1 : fileNum
end % if isSmooth

%% ���������������� �������ļ��ľ�������ϲ� ����������������������������%
for i = 1 : fileNum
    feaCluster.paraRaw = [feaCluster.paraRaw; feaFile(i).para];
    feaCluster.paraSmooth = [feaCluster.paraSmooth; feaFile(i).paraSmooth];
    feaCluster.movLength = [feaCluster.movLength; feaFile(i).movLength];
    feaCluster.time = [feaCluster.time; feaFile(i).time];
    if isempty(feaCluster.smoothIndex)
        smoothAdd = 0;
    else
        smoothAdd = max(feaCluster.smoothIndex(:,2));
    end
    feaCluster.smoothIndex = [feaCluster.smoothIndex; feaFile(i).smoothIndex + smoothAdd];
    
    ENU_temp = feaFile(i).pos_enu;
    if isempty(feaCluster.pos_enu)
        st_map = 0;
    else
        st_map = max(feaCluster.pos_enu(:,1));
    end
    ENU_temp(:, 1) = ENU_temp(:, 1) + (st_map - min(ENU_temp(:,1)) + 500);
    feaCluster.pos_enu = [feaCluster.pos_enu; ENU_temp];
end


%% %%%%%%%%%%% ������һ�� %%%%%%%%%%%%%%
for i = 1 : pNum    
%     Mu = median(feature(:, i));
%     sigma = sum(abs(feature(:, i) - Mu))/N;
    N_raw = sum(timeLen);
    Mu_raw = mean(feaCluster.paraRaw(:, i));
    sigma_raw = sqrt(sum((feaCluster.paraRaw(:, i) - Mu_raw).^2) /N_raw);   
    feaCluster.paraRaw_Norm(:, i) = (feaCluster.paraRaw(:, i) - Mu_raw) / sigma_raw;
    feaCluster.paraRaw_Norm_atan(:, i) = atan(feaCluster.paraRaw_Norm(:, i)); 
    
    N_Smo = sum(clusterLen);
    Mu_Smo = mean(feaCluster.paraSmooth(:, i));
    sigma_Smo = sqrt(sum((feaCluster.paraSmooth(:, i) - Mu_Smo).^2) /N_Smo);   
    feaCluster.paraSmooth_Norm(:, i) = (feaCluster.paraSmooth(:, i) - Mu_Smo) / sigma_Smo;
    feaCluster.paraSmooth_Norm_atan(:, i) = atan(feaCluster.paraSmooth_Norm(:, i));
end

%% %%%%%%%%%%% �����ͼ��ʾ�õ�ENU���� %%%%%%%%%%%%%%
% index = 1;
% for i = 1 : fileNum
%     
%     ENU_temp = parameter(i).pos_enu;
%     enuMap(:,index:(index+timeLen(i)-1)) = ENU_temp + [(max(enuMap(1,:)) - min(ENU_temp(1,:)) + 500);0;0];
%     index = index + timeLen(i);
% end   

end % EOF : function