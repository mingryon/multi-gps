function [pvtCalculator] = saveMatrix(doubleDiff, pvtCalculator, satPositions, activeChannel)
refxyz = [-2853445.340, 4667464.957, 3268291.032];    % ��׼վ����--������
basePrn = pvtCalculator.doubleDiff.basePrn;    % �ο�����PRN��
pvtCalculator.doubleDiff.numTime = pvtCalculator.doubleDiff.numTime + 1;    % ��Ԫ������1
if pvtCalculator.doubleDiff.numTime > 0 
    numTime = mod(pvtCalculator.doubleDiff.numTime, 100);     % ��ǰ�۲���Ԫ����
    if numTime == 0
        numTime = 100;
    end
    pvtCalculator.doubleDiff.obs(numTime, :) = doubleDiff;      % ���浱ǰ��Ԫ�Ĺ۲���˫��(�б�ʾ���Ǻ�)
    vectorBase = (satPositions(:,basePrn)'-refxyz)/norm(satPositions(:,basePrn)'-refxyz);         % �ο����Ƿ�������
    for i = 1:length(activeChannel(2,:))
        if activeChannel(2,i) ~= basePrn
            vectorUse = (satPositions(:,activeChannel(2,i))'-refxyz)/norm(satPositions(:,activeChannel(2,i))'-refxyz);   % �������Ƿ�������
            pvtCalculator.doubleDiff.vector(activeChannel(2,i),:,numTime) = (vectorBase - vectorUse)/(299792458/1561098000);     % ���ǹ۲ⷽ���б�ʾ���Ǻţ�
        end
    end
end
end

