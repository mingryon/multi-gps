 function  [prsmref,TOWSEC] = Range_corr
%%%%%ͨ��RINEX����α������Ϣ
filename='G:\trunk\roof_rinex\803739006u.15O';
decimate_factor = 1;
[C1I, L1I,ch,TOWSEC] = read_rinex(filename,decimate_factor);
prref = C1I;%�۲�α��
adrref = L1I*299792458/1561098000;%���ֶ����ճ��Բ���
smint = 50;%ƽ��ʱ��
%refxyz = [-2853445.340,4667464.957,3268291.032];%�ο�ϵ����
%prc = 0*ones(24,length(TOWSEC));%α������
value_rinex = zeros(30,2);
prsmref = zeros(30, length(TOWSEC));
    for i = 1:length(TOWSEC)
       svidref = ch(i,:);
       [prsmref(:,i),value_rinex] = ...
           hatch_BD(prref(:,i),adrref(:,i),svidref,smint,value_rinex);%�ز���λƽ���˲�
    end
 end
      
   
    