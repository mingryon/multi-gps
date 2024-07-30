function [feature_Norm, feature, timeLen, pos_xyz, vel, enuMap] = featureGet(parameter, fileNum, CNR_std_ublox)

% ���������������� [�ɼ���������DOPֵ����ֵ����������ԣ����ڵ����������ڵ�����ϵ��, ���] ��������������������������������
pNum = 9; % ����������

%% %������������������������ ����������ʼ�� ������������������������%
index = 0;
timeLen = zeros(fileNum, 1);
for i = 1 : fileNum
    timeLen(i) = size(parameter(i).SOW, 2);
end
% [�ɼ���������DOPֵ����ֵ��������ڵ�������]
tNum = sum(timeLen); % ����Ԫ����
feature = zeros(tNum, pNum);
feature_Norm = zeros(tNum, pNum);
pos_xyz = zeros(tNum, 3);
vel = zeros(sum(timeLen), 1);
enuMap = zeros(3, sum(timeLen));
%% %������������������������  ����������ȡ  ��������������������������������
for i = 1 : fileNum
    paraFile = parameter(i);
    for k = 1 : timeLen(i)
        index = index + 1;
        pos_xyz(index, :) = paraFile.pos_xyz(:, k)';
        vel(index) = paraFile.vel(k);
        
        % ���������������� 1���ɼ����������� �������������������� %
        feature(index, 1) = paraFile.satNum(k);
        
        %  ���������������� 2��GDOPֵ���� �������������������� %
        feature(index, 2) = paraFile.GDOP(k);
        
        % �������������� 3~5������Ⱦ�ֵ������Ͳ����� ��������������%
        attenuation = zeros(1, paraFile.satNum(k));   % ��ֵ������
        atten_var = zeros(1, paraFile.satNum(k));   % ������
        if paraFile.satNum(k) > 1
            for j = 1 : paraFile.satNum(k)
                prn = paraFile.prnNo(j, k);
                el = paraFile.Elevation(prn, k);
                if el == 0
                    CNR_std = CNR_std_ublox(1);
                else
                    CNR_std = CNR_std_ublox(el);
                end
                attenuation(j) = paraFile.CNR(prn, k) - CNR_std;
                atten_var(j) = paraFile.CNR_Var(prn, k);
            end
            feature(index, 3) = mean(attenuation);
            feature(index, 4) = sqrt(var(attenuation));
            feature(index, 5) = mean(atten_var);
        elseif paraFile.satNum(k) == 1
            prn = paraFile.prnNo(1, k);
            el = paraFile.Elevation(prn, k);
            if el == 0
                CNR_std = CNR_std_ublox(1);
            else
                CNR_std = CNR_std_ublox(el);
            end
            attenuation(1) = paraFile.CNR(prn, k) - CNR_std;
            feature(index, 3) = mean(attenuation);
            feature(index, 4) = feature(index-1, 4); % ����ֻ��1����������Ĭ����Ϊ5
            feature(index, 5) = mean(atten_var);
        elseif  paraFile.satNum(k) == 0
            feature(index, 3) = -40;
            feature(index, 4) = feature(index-1, 4); % ����ֻ��0����������Ĭ����Ϊ5
            feature(index, 5) = feature(index-1, 5);
        end % if paraFile.satNum(k) > 1
        
        % �������������������� 6�����ڵ������� ��������������������%
        feature(index, 6) = paraFile.blockNum(k);
        
        % �������������������� 7�������ڵ�����ϵ�� ��������������������%
        feature(index, 7) = feature(index, 6) / (feature(index, 6)+feature(index, 1));
        
         % �������������������� 8��GDOP������� ��������������������%
        feature(index, 8) = paraFile.GDOP_ratio(k);
        
        % �������������������� 9����λ��� ��������������������%
        feature(index, 9) = paraFile.ENU_error(4, k);
       
    end % for k = 1 : timeLen(i)
end % for i = 1 : fileNum

%% %%%%%%%%%%% ������һ�� %%%%%%%%%%%%%%
for i = 1 : pNum    
%     Mu = median(feature(:, i));
%     sigma = sum(abs(feature(:, i) - Mu))/N;
    Mu = mean(feature(:, i));
    sigma = sqrt(sum((feature(:, i) - Mu).^2) /tNum);   
    feature_Norm(:, i) = (feature(:, i) - Mu) / sigma;
end

%% %%%%%%%%%%% �����ͼ��ʾ�õ�ENU���� %%%%%%%%%%%%%%
index = 1;
for i = 1 : fileNum
    ENU_temp = parameter(i).pos_enu;
    enuMap(:,index:(index+timeLen(i)-1)) = ENU_temp + [(max(enuMap(1,:)) - min(ENU_temp(1,:)) + 500);0;0];
    index = index + timeLen(i);
end   

end % EOF : function