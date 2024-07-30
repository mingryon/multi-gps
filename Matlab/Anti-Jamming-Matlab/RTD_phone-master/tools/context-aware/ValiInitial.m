function [ValiIndex, dist_cluster] = ValiInitial(cluTimes_N)
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
ValiIndex(1:cluTimes_N) = ValiIndex;
dist_cluster(1:cluTimes_N) = dist_cluster;