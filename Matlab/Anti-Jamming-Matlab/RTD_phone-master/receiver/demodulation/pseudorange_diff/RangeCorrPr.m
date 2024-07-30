function  [DiffPara] = RangeCorrPr(channels,activeChannel, DiffPara, EphAll)
    %%%%%ͨ��RINEX����α������Ϣ
    if  ~isequal(DiffPara.PrevEph, EphAll)
        filename='F:\wangyz\trunk\roof_rinex\803739092q.15O';
        decimate_factor = 1;
        refxyz = [-2853445.340,4667464.957,3268291.032]';%�ο�ϵ����
        [C1I, L1I,ch,TOWSEC] = read_rinex(filename,decimate_factor);
        TOWSEC = TOWSEC -14; %%ò����˾�Ͻ��ջ����Ӳ�
        PR_error = zeros(length(TOWSEC), 30);
        prref = C1I';%�۲�α��
        adrref = L1I*299792458/1561098000;%���ֶ����ճ��Բ���
        transmitTime = zeros(1,30);
        satpos_corr = zeros(3,30);
        for j = 1:length(TOWSEC)
            for jj = 1:length(ch(j,:))
                if ch(j,jj) ~= 0
                    transmitTime(ch(j,jj)) = TOWSEC(j) - prref(j,ch(j,jj))/299792458;
                end
            end
            [satPositions, satClkCorr,eph_all] = BD_calculateSatPosition(transmitTime, ...
                 channels,activeChannel);    
            for jj = 1:length(ch(j,:))
                if ch(j,jj) ~= 0
                    satpos_corr(:, ch(j,jj)) = e_r_corr(...
                        prref(j,ch(j,jj))/299792458 + satClkCorr(ch(j,jj)), satPositions(1:3, ch(j,jj)));%����i����������ת�������λ��
                    PR_error(j,ch(j,jj)) =prref(j,ch(j,jj)) - norm(refxyz - satpos_corr(1:3,ch(j,jj)));
                end
            end
        end
        DiffPara.PrevEph = EphAll;
        DiffPara.PrError = PR_error;
        DiffPara.TowSec  = TOWSEC;
    end
end

% % smint = 50;%ƽ��ʱ��
% % %refxyz = [-2853445.340,4667464.957,3268291.032];%�ο�ϵ����
% % %prc = 0*ones(24,length(TOWSEC));%α������
% % value_rinex = zeros(30,2);
% % prsmref = zeros(30, length(TOWSEC));
% %     for i = 1:length(TOWSEC)
% %        svidref = ch(i,:);
% %        [prsmref(:,i),value_rinex] = ...
% %            hatch_BD(prref(:,i),adrref(:,i),svidref,smint,value_rinex);%�ز���λƽ���˲�
% %     end
% %  end
      
   
    