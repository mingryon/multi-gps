function [day,hour,min,sec]=sow2BJT(sow)
% ���룺 sow       ���������루�����붨��Ϊÿ�ܵ���������0ʱΪ0�룬��ʼ������
% ����� day    	һ���е�����
%       hour       ʱ
%       min        ��
%       sec        ��
bjsow=sow;
day=floor(bjsow/86400);
hour=floor((bjsow-day*86400)/3600);
min=floor((bjsow-day*86400-hour*3600)/60);
sec=bjsow-day*86400-hour*3600-min*60;
end