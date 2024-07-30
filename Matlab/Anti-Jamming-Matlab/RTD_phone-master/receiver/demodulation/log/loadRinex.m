function [pvtCalculator]= loadRinex(positionType, pvtCalculator)
   %% ����α�൥��У����
    if positionType == 10
        filename = pvtCalculator.diffFile;
        decimate_factor = 1;
        [C1, L1,ch,TOWSEC] = read_rinex(filename,decimate_factor);
        TOWSEC = TOWSEC-14 ; %%ò����˾�Ͻ��ջ����Ӳ�,������Ҫ��ȥ14�룬GPS����Ҫ
        pvtCalculator.prError = C1';
        pvtCalculator.carriError = L1';
        pvtCalculator.towSec = TOWSEC;
    end
    
    %% hatch smoothing
%     prref = C1I;%�۲�α��
%     adrref = L1I*299792458/1561098000;%���ֶ����ճ��Բ���
%     smint = 50;%ƽ��ʱ��
%     %refxyz = [-2853445.340,4667464.957,3268291.032];%�ο�ϵ����
%     value_rinex = zeros(30,2);
%     prsmref = zeros(30, length(TOWSEC));
%     for i = 1:length(TOWSEC)
%        svidref = ch(i,:);
%        [prsmref(:,i),value_rinex] = ...
%        hatch_BD(prref(:,i),adrref(:,i),svidref,smint,value_rinex);%�ز���λƽ���˲�
%     end
end