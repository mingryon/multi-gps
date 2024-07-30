function [idxExp] = idxSort(idxExp_raw, cnrMeanRaw)
% ���������������
Num = max(idxExp_raw); % �������
idxMod = zeros(Num, 2); % [num, cnr]
idxExp = zeros(length(idxExp_raw), 1);

for i = 1 : Num
    idxMod(i, 1) = i;
    line = idxExp_raw==i;
    idxMod(i, 2) = mean(cnrMeanRaw(line));
end
idxMod = sortrows(idxMod, 2);% ��ŵ�����ʽ

for i = 1 : Num
   line = idxExp_raw==i;
   idxExp(line) = find(idxMod(:, 1)==i);
end