function [raimFlag, posiChannel,activeChannel,svnum] =raim(prError, raimG, raimB, posiChannel, raimFlag, SYST, svnum, pvtCalculator, recv_time, rawP, activeChannel)
% if isempty(raimG)  % �״ν���raim��ȥ��α��۲�������� 
%     if ~isempty(activeChannel.BDS)
%         for i =size(activeChannel.BDS, 2) : -1 : 1
%             if rawP.BDS(activeChannel.BDS(2,i))<9999999 || rawP.BDS(activeChannel.BDS(2,i))>99999999    % �����������Ϊ�������
%                 activeChannel.BDS(:,i) = [];
%                 posiChannel.BDS(:,i) = [];
%             end
%         end
%     end
%     if ~isempty(activeChannel.GPS)
%         for i =size(activeChannel.GPS, 2) : -1 : 1
%             if rawP.GPS(activeChannel.GPS(2,i))<9999999 || rawP.GPS(activeChannel.GPS(2,i))>99999999    % �����������Ϊ�������
%                 activeChannel.GPS(:,i) = [];
%                 posiChannel.GPS(:,i) = [];
%             end
%         end
%     end
% end   
if ~isempty(raimG)
    if size(raimG,1) >= 5
        if strcmp(SYST,'BDS_B1I') || (strcmp(SYST,'B1I_L1CA')&&svnum.GPS==0)
            bEsti = raimB - raimG/(raimG'*raimG)*raimG'*raimB;    % �������
            WSSE = (norm(bEsti))^2;         % �����ֵ
            if WSSE > chi2inv(0.99999, size(raimG,1)-4)
                if (recv_time.recvSOW-pvtCalculator.timeLast)<5 && pvtCalculator.posiLast(1)~=0 && pvtCalculator.posiCheck==1   % ��Ϊ��һʱ��λ����Ϣ��Ч
                    [~, maxNum] = max(abs(prError));
                    posiChannel.BDS(:, maxNum) = [];
                    svnum.BDS = svnum.BDS - 1;
                else
                    [~, maxNum] = max(abs(bEsti));
                    posiChannel.BDS(:, maxNum) = [];
                    svnum.BDS = svnum.BDS - 1;
                end
            else
                raimFlag = 1;   % �������Ҫ��
            end
        elseif strcmp(SYST,'GPS_L1CA') || (strcmp(SYST,'B1I_L1CA')&&svnum.BDS==0)
            bEsti = raimB - raimG/(raimG'*raimG)*raimG'*raimB;    % �������
            WSSE = (norm(bEsti))^2;         % �����ֵ
            if WSSE > chi2inv(0.99999, size(raimG,1)-4)
                if (recv_time.recvSOW-pvtCalculator.timeLast)<5 && pvtCalculator.posiLast(1)~=0 && pvtCalculator.posiCheck==1   % ��Ϊ��һʱ��λ����Ϣ��Ч
                    [~, maxNum] = max(abs(prError));
                    posiChannel.GPS(:, maxNum) = [];
                    svnum.GPS = svnum.GPS - 1;
                else
                    [~, maxNum] = max(abs(bEsti));
                    posiChannel.GPS(:, maxNum) = [];
                    svnum.GPS = svnum.GPS - 1;
                end
            else
                raimFlag = 1;   % �������Ҫ��
            end
        elseif  strcmp(SYST,'B1I_L1CA')
            bEsti = raimB - raimG/(raimG'*raimG)*raimG'*raimB;    % �������
            WSSE = (norm(bEsti))^2;         % �����ֵ
            if WSSE > chi2inv(0.99999, size(raimG,1)-4)
                if (recv_time.recvSOW-pvtCalculator.timeLast)<5 && pvtCalculator.posiLast(1)~=0 && pvtCalculator.posiCheck==1   % ��Ϊ��һʱ��λ����Ϣ��Ч
                    [~, maxNum] = max(abs(prError));
                    numBD = size(posiChannel.BDS, 2);   % ˫ϵͳ��λ�б�������ʹ�õ���Ŀ
                    if maxNum <= numBD
                        posiChannel.BDS(:, maxNum) = [];
                        svnum.BDS = svnum.BDS - 1;
                    else
                        posiChannel.GPS(:, maxNum-numBD) = [];
                        svnum.GPS = svnum.GPS - 1;
                    end
                else
                    [~, maxNum] = max(abs(bEsti));
                    numBD = size(posiChannel.BDS, 2);   % ˫ϵͳ��λ�б�������ʹ�õ���Ŀ
                    if maxNum <= numBD
                        posiChannel.BDS(:, maxNum) = [];
                        svnum.BDS = svnum.BDS - 1;
                    else
                        posiChannel.GPS(:, maxNum-numBD) = [];
                        svnum.GPS = svnum.GPS - 1;
                    end
                end
            else
                raimFlag = 1;   % �������Ҫ��
            end
        end
    else
        raimFlag = 1;   % С��5�������޷�ʹ��raim�㷨
    end
end
