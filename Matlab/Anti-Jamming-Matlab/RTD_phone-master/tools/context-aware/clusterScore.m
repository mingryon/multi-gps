function [ValiIndex, dist_cluster] = clusterScore(feature, cluster_No, cluster_Std_No, class_Num)
N = length(cluster_No);
ValiIndex = struct(...
    'JC',      0,...    % Jaccard ϵ��
    'FMI',     0,...    % FM ָ��
    'RI',      0,...    % Rand ָ��
    'DBI',     0,...    % DB ָ��
    'DI',      0 ...    % Dunn ָ��
    );
dist_cluster = struct(...
    'dmin',     [],...    % �ؼ���С���
    'dcen',     [],...    % �ؼ����ļ��
    'dmax',     [] ...    % �ؼ������
    );
%% �ⲿ����ָ�����
a = 0;
b = 0;
c = 0;
d = 0;
for i = 1 : (N-1)
    for j = (i+1) : N
        if cluster_No(i)==cluster_No(j) && cluster_Std_No(i)==cluster_Std_No(j)
            a = a + 1;
        end
        if cluster_No(i)==cluster_No(j) && cluster_Std_No(i)~=cluster_Std_No(j)
            b = b + 1;
        end
        if cluster_No(i)~=cluster_No(j) && cluster_Std_No(i)==cluster_Std_No(j)
            c = c + 1;
        end
        if cluster_No(i)~=cluster_No(j) && cluster_Std_No(i)~=cluster_Std_No(j)
            d = d + 1;
        end
    end
end
% ����Jaccardϵ��
JC = a / (a + b + c);
% ����FMָ��
FMI = sqrt(a^2 / ((a+b)*(a+c)));
% ����Randָ��
RI = 2 * (a + d) / (N*(N-1));

%% �ڲ�����ָ��
avg_C = zeros(1, class_Num);
diam_C = zeros(1, class_Num);
for i = 1 : class_Num
    row_No = cluster_No == i;
    avg_C(i) = mean(pdist(feature(row_No, :))); % �������ƽ������
    diam_C(i) = max(pdist(feature(row_No, :))); % �������������
end

dmin = zeros(class_Num, class_Num);
dcen = zeros(class_Num, class_Num);
dmax = zeros(class_Num, class_Num);
for i = 1 : class_Num-1
    for j = i+1 : class_Num
        row_No = cluster_No == i;
        feature_i = feature(row_No, :);
        row_No = cluster_No == j;
        feature_j = feature(row_No, :);
        dmin(i, j) = min(min(pdist2(feature_i, feature_j, 'euclidean'))); % ����ؼ����С����
        dmin(j, i) = dmin(i, j);
        dmax(i, j) = max(max(pdist2(feature_i, feature_j, 'euclidean'))); % ����ؼ����С����
        dmax(j, i) = dmax(i, j);
        feature_i_mean = mean(feature_i, 1);
        feature_j_mean = mean(feature_j, 1);
        dcen(i, j) = pdist2(feature_i_mean, feature_j_mean, 'euclidean'); % ����ؼ��ƽ������
        dcen(j, i) = dcen(i, j);
    end
end

% ����DBָ����Dunnָ��
DBI_part = nan(1, class_Num);
DI_part = nan(1, class_Num);
for i = 1 : class_Num
    for j = 1 : class_Num
        if i ~= j 
            % ����DBָ��
            DBI_temp = (avg_C(i) + avg_C(j)) / dcen(i, j);
            if isnan(DBI_part(i))
                DBI_part(i) = DBI_temp;
            else
                if DBI_part(i) < DBI_temp
                    DBI_part(i) = DBI_temp;
                end
            end
            % ����Dunnָ��
            DI_temp = dmin(i, j) / (max(diam_C));
            if isnan(DI_part(i))
                DI_part(i) = DI_temp;
            else
                if DI_part(i) > DI_temp
                    DI_part(i) = DI_temp;
                end
            end 
        end % if i ~= j 
    end % for j = 1 : class_Num
end % for i = 1 : class_Num          
DBI = mean(DBI_part);
DI = min(DI_part);
% ����ָ�긳ֵ
ValiIndex.JC = JC;
ValiIndex.FMI = FMI;
ValiIndex.RI = RI;
ValiIndex.DBI = DBI;
ValiIndex.DI = DI;
% ������֮��ľ��븳ֵ
dist_cluster.dmin = dmin;
dist_cluster.dcen = dcen;
dist_cluster.dmax = dmax;
