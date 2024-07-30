function [positionXYZ, pvtCalculator] = carrDiffResult(pvtCalculator, activeChannel, checkNGEO)
refxyz = [-2853445.340, 4667464.957, 3268291.032];    % ��׼վ����--������
I0 = zeros(1,3);
positionXYZ = [0,0,0];
basePrn = pvtCalculator.doubleDiff.basePrn;    % �ο�����PRN��
timeInterval = 60;      % ������Ԫ֮���ʱ����
numUse = 0;
if length(activeChannel(1,:))>=4 && checkNGEO==1
    for i = 1:length(activeChannel(2,:))
        if activeChannel(2,i) ~= basePrn
            numUse = numUse + 1;
            useChannel(numUse) = activeChannel(2,i);
        end
    end
    if numUse==4 && pvtCalculator.doubleDiff.numTime>=3*timeInterval+1        % 4���۲ⷽ����Ҫ����4����Ԫ
        b = zeros(4*4,1);       % ��ʼ���۲����
        G = zeros(4*4,16);      % ��ʼ��ת�ƾ���
        I1 = eye(4);            % ����һ����λ����
        numTime1 = mod(pvtCalculator.doubleDiff.numTime, 100);     % ��Ԫ4��Ӧ����λ��
        if numTime1 == 0
            numTime1 = 100;
        end
        numTime2 = mod(pvtCalculator.doubleDiff.numTime-timeInterval, 100);     % ��Ԫ3��Ӧ����λ��
        if numTime2 == 0
            numTime2 = 100;
        end
        numTime3 = mod(pvtCalculator.doubleDiff.numTime-timeInterval*2, 100);     % ��Ԫ2��Ӧ����λ��
        if numTime3 == 0
            numTime3 = 100;
        end
        numTime4 = mod(pvtCalculator.doubleDiff.numTime-timeInterval*3, 100);     % ��Ԫ1��Ӧ����λ��
        if numTime4 == 0
            numTime4 = 100;
        end
        for i = 1:length(useChannel)

                b(i,1) = pvtCalculator.doubleDiff.obs(numTime4,useChannel(i));             % �����ĸ���Ԫ���ز���λ˫��۲�ֵ
                b(i+numUse,1) = pvtCalculator.doubleDiff.obs(numTime3,useChannel(i));
                b(i+2*numUse,1) = pvtCalculator.doubleDiff.obs(numTime2,useChannel(i));
                b(i+3*numUse,1) = pvtCalculator.doubleDiff.obs(numTime1,useChannel(i));
                G(i,:) = [pvtCalculator.doubleDiff.vector(useChannel(i),:,numTime4), I0, I0, I0, I1(i,:)];      %����ת�ƾ����һ��Ԫ��
                G(i+numUse,:) = [I0, pvtCalculator.doubleDiff.vector(useChannel(i),:,numTime3), I0, I0, I1(i,:)];
                G(i+2*numUse,:) = [I0, I0, pvtCalculator.doubleDiff.vector(useChannel(i),:,numTime2), I0, I1(i,:)];
                G(i+3*numUse,:) = [I0, I0, I0, pvtCalculator.doubleDiff.vector(useChannel(i),:,numTime1), I1(i,:)];
                deltaPhi(i,1) = pvtCalculator.doubleDiff.obs(numTime1,useChannel(i));      % ���뵱ǰ��Ԫ���ز���λ�۲�ֵ
                deltaI(i,:) = pvtCalculator.doubleDiff.vector(useChannel(i),:,numTime1);       % ��ǰ��Ԫ��ת�ƾ���

        end
        if pvtCalculator.doubleDiff.nfixedValue ==0
            x = G \ b;      % ��⸡���
            Q = inv(G'*G);  % ��Э�������
            Qn = Q(13:16,13:16);    % ģ���ȵ�Э�������
            [nfixed,sqnorm,Qahat,Z] = lambda1 (x(13:16), Qn, 2, 1);     % �������ģ����
            pvtCalculator.doubleDiff.nfixed = nfixed(:,1);              % ��������ģ���Ƚ�
            pvtCalculator.doubleDiff.nfixedValue = 1;                   % ����ģ���������
        end
        relativeVector = deltaI \ (deltaPhi-pvtCalculator.doubleDiff.nfixed);           % �����Ի�������
        positionXYZ = refxyz + relativeVector';
    end
    if numUse==5 && pvtCalculator.doubleDiff.numTime>=2*timeInterval+1        % 5���۲ⷽ����Ҫ����3����Ԫ
        b = zeros(5*3,1);       % ��ʼ���۲����
        G = zeros(5*3,14);      % ��ʼ��ת�ƾ���
        I1 = eye(5);            % ����һ����λ����
        numTime1 = mod(pvtCalculator.doubleDiff.numTime, 100);     % ��Ԫ3��Ӧ����λ��
        if numTime1 == 0
            numTime1 = 100;
        end
        numTime2 = mod(pvtCalculator.doubleDiff.numTime-timeInterval, 100);     % ��Ԫ2��Ӧ����λ��
        if numTime2 == 0
            numTime2 = 100;
        end
        numTime3 = mod(pvtCalculator.doubleDiff.numTime-timeInterval*2, 100);     % ��Ԫ1��Ӧ����λ��
        if numTime3 == 0
            numTime3 = 100;
        end
        for i = 1:length(useChannel)

                b(i,1) = pvtCalculator.doubleDiff.obs(numTime3,useChannel(i));             % �����ĸ���Ԫ���ز���λ˫��۲�ֵ
                b(i+numUse,1) = pvtCalculator.doubleDiff.obs(numTime2,useChannel(i));
                b(i+2*numUse,1) = pvtCalculator.doubleDiff.obs(numTime1,useChannel(i));

                G(i,:) = [pvtCalculator.doubleDiff.vector(useChannel(i),:,numTime3), I0, I0, I1(i,:)];      %����ת�ƾ����һ��Ԫ��
                G(i+numUse,:) = [I0, pvtCalculator.doubleDiff.vector(useChannel(i),:,numTime2), I0, I1(i,:)];
                G(i+2*numUse,:) = [I0, I0, pvtCalculator.doubleDiff.vector(useChannel(i),:,numTime1), I1(i,:)];

                deltaPhi(i,1) = pvtCalculator.doubleDiff.obs(numTime1,useChannel(i));      % ���뵱ǰ��Ԫ���ز���λ�۲�ֵ
                deltaI(i,:) = pvtCalculator.doubleDiff.vector(useChannel(i),:,numTime1);       % ��ǰ��Ԫ��ת�ƾ���

        end
        if pvtCalculator.doubleDiff.nfixedValue ==0
            x = G \ b;      % ��⸡���
            Q = inv(G'*G);  % ��Э�������
            Qn = Q(10:14,10:14);    % ģ���ȵ�Э�������
            [nfixed,sqnorm,Qahat,Z] = lambda1 (x(10:14), Qn, 2, 1);     % �������ģ����
            pvtCalculator.doubleDiff.nfixed = nfixed(:,1);              % ��������ģ���Ƚ�
            pvtCalculator.doubleDiff.nfixedValue = 1;                   % ����ģ���������
        end
        relativeVector = deltaI \ (deltaPhi-pvtCalculator.doubleDiff.nfixed);           % �����Ի�������
        positionXYZ = refxyz + relativeVector';
    end
    if numUse>=6 && pvtCalculator.doubleDiff.numTime>=timeInterval+1        % 6�������Ϲ۲ⷽ����Ҫ����2����Ԫ
        b = zeros(numUse*2,1);       % ��ʼ���۲����
        G = zeros(numUse*2,2*3+numUse);      % ��ʼ��ת�ƾ���
        I1 = eye(numUse);            % ����һ����λ����
        numTime1 = mod(pvtCalculator.doubleDiff.numTime, 100);     % ��Ԫ2��Ӧ����λ��
        if numTime1 == 0
            numTime1 = 100;
        end
        numTime2 = mod(pvtCalculator.doubleDiff.numTime-timeInterval, 100);     % ��Ԫ1��Ӧ����λ��
        if numTime2 == 0
            numTime2 = 100;
        end
        for i = 1:length(useChannel)

                b(i,1) = pvtCalculator.doubleDiff.obs(numTime2,useChannel(i));             % �����ĸ���Ԫ���ز���λ˫��۲�ֵ
                b(i+numUse,1) = pvtCalculator.doubleDiff.obs(numTime1,useChannel(i));           
                G(i,:) = [pvtCalculator.doubleDiff.vector(useChannel(i),:,numTime2), I0, I1(i,:)];      %����ת�ƾ����һ��Ԫ��
                G(i+numUse,:) = [I0, pvtCalculator.doubleDiff.vector(useChannel(i),:,numTime1), I1(i,:)];        
                deltaPhi(i,1) = pvtCalculator.doubleDiff.obs(numTime1,useChannel(i));      % ���뵱ǰ��Ԫ���ز���λ�۲�ֵ
                deltaI(i,:) = pvtCalculator.doubleDiff.vector(useChannel(i),:,numTime1);       % ��ǰ��Ԫ��ת�ƾ���

        end
        if pvtCalculator.doubleDiff.nfixedValue == 0
            x = G \ b;      % ��⸡���
            Q = inv(G'*G);  % ��Э�������
            Qn = Q(7:(2*3+numUse),7:(2*3+numUse));    % ģ���ȵ�Э�������
            [nfixed,sqnorm,Qahat,Z] = lambda1 (x(7:(2*3+numUse)), Qn, 2, 1);     % �������ģ����
            pvtCalculator.doubleDiff.nfixed = nfixed(:,1);              % ��������ģ���Ƚ�
            pvtCalculator.doubleDiff.nfixedValue = 1;                   % ����ģ���������
        end
        relativeVector = deltaI \ (deltaPhi-pvtCalculator.doubleDiff.nfixed);           % �����Ի�������
        positionXYZ = refxyz + relativeVector';
    end
end
end
