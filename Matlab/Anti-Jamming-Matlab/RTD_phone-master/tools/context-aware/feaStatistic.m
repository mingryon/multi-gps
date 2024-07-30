function [feaEachClu] = feaStatistic(feaCluster, idxExp, idxExpRaw, class_Num)
feaEachClu = struct(...
    'paraRaw',               [],...  % ԭʼ��������
    'paraRaw_Norm',          [],...  % ��һ��
    'paraRaw_Norm_atan',     [],...  % ������
    'idxExpRaw',             []...  % ������
    );
feaEachClu(1:class_Num) = feaEachClu;
for i = 1 : class_Num
    row_No = idxExp == i;
    feaEachClu(i).paraRaw = feaCluster.paraRaw(row_No, :);
    feaEachClu(i).paraRaw_Norm = feaCluster.paraRaw_Norm(row_No, :);
    feaEachClu(i).paraRaw_Norm_atan = feaCluster.paraRaw_Norm_atan(row_No, :);
    feaEachClu(i).idxExpRaw = idxExpRaw(row_No);
end