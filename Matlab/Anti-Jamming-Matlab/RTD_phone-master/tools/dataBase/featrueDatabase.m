function [feaCluster, feaFile, timeLen] = featrueDatabase(parameter, fileNum, CNR_std_ublox, CNR_std_modi, isInt)

% ���������������� [�ɼ���������DOPֵ����ֵ����������ԣ����ڵ����������ڵ�����ϵ��, ���, �ۻ������] ��������������������������������
pNum = 5; % ����������

%% %������������������������ ����������ʼ�� ������������������������%
timeLen = zeros(fileNum, 1);  % ���ļ�����ȡ��������Ԫ��
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
    'pos_enu',               [],...  % ��άƽ���ͼ��
    'movLength',               [],...  % ����
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
            % ���������������� 1�����ɼ�������ռ�� �������������������� %
            if isInt
                satNum = paraFile.satNum(k);
            else
                satNum = paraFile.satNum((k-4):k);
            end
            satNum(isnan(satNum)) = [];     
            
            if isInt
                blockNum = paraFile.blockNum(k);
            else
                blockNum = paraFile.blockNum((k-4):k);
            end
            blockNum(isnan(blockNum)) = [];       
           
            feaFile(i).para(index, 1) = mean(blockNum) / (mean(blockNum) + mean(satNum));

            % �������������� 2~4�����źű��������źž�ֵ���źŲ���ֵ ��������������%
            satNum_temp = paraFile.satNum(k);
            prnNo_temp = paraFile.prnNo(1:satNum_temp, k);
            for j = 1 : length(paraFile.prnNo_useless)
                prnNo_temp(prnNo_temp == paraFile.prnNo_useless(j)) = [];  % �˹�ȥ����Ҫɾ�������Ǻ�
            end
            satNum_temp = length(prnNo_temp);
            attenuation = zeros(1, satNum_temp);   % ��ֵ������
            atten_var = zeros(1, satNum_temp);   % ������
            if satNum_temp > 0
                for j = 1 : satNum_temp
                    prn = prnNo_temp(j);
                    el = paraFile.Elevation(prn, k);
                    if el == 0
                        el = 1;
                    end
                    CNR_std = CNR_std_ublox(el) + CNR_std_modi(i);
                    
                    if isInt
                        atten_temp = CNR_std - paraFile.CNR(prn, k);
                    else
                        atten_temp = CNR_std - paraFile.CNR(prn, (k-4):k);
                    end
                    atten_temp(isnan(atten_temp)) = [];
                    attenuation(j) = mean(atten_temp);
                    atten_var(j) = paraFile.CNR_Var(prn, k);
                end
                feaFile(i).para(index, 2) = length(find(attenuation>5)) / satNum_temp;
                if feaFile(i).para(index, 2) > 0
                    feaFile(i).para(index, 3) = mean(attenuation(attenuation>5));
                else
                    feaFile(i).para(index, 3) = 0;
                end
                feaFile(i).para(index, 4) = mean(atten_var);
            elseif  satNum_temp == 0
                feaFile(i).para(index, 2) = feaFile(i).para(index-1, 2);
                feaFile(i).para(index, 3) = feaFile(i).para(index-1, 3); % ����ֻ��0����������Ĭ����Ϊ5
                feaFile(i).para(index, 4) = feaFile(i).para(index-1, 4);
            end % if paraFile.satNum(k) > 1

            % �������������������� 5��GDOP������� ��������������������%
            if isInt 
                GDOP_ratio = paraFile.GDOP_ratio(k);
            else
                GDOP_ratio = paraFile.GDOP_ratio((k-4):k);
            end
            GDOP_ratio(isnan(GDOP_ratio)) = [];            
            feaFile(i).para(index, 5) = mean(GDOP_ratio);
            
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

%% ���������������� �������ļ��ľ�������ϲ� ����������������������������%
for i = 1 : fileNum
    feaCluster.paraRaw = [feaCluster.paraRaw; feaFile(i).para];
    feaCluster.time = [feaCluster.time; feaFile(i).time];
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