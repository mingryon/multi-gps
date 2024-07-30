
function [year,month,day]=calculate_yymmdd(weeknum, daySOW)
% ͨ��������������������
% ���룺 weeknum ����������
%        daySOW  ͨ���������������һ���е�����
% ����� year    ��
%       month    ��
%       day      ��
yearBegin = 2006;
yearnum = 0;
allDay = weeknum*7 + 1 + daySOW;    % ����������
leapyearDay = 0;
for ii = yearBegin:10000
     leapYear = 0;     
     if mod(ii,100)==0          %�ж��Ƿ�Ϊ����
        if mod(ii,400)==0
            leapYear=1;
         end
     else
         if  mod(ii,4)==0
            leapYear=1;
         end                
     end
       leapyearDay = leapyearDay + leapYear;    %����������
       yearnum = yearnum + 1;
       n_year_day = 365*yearnum + leapyearDay;
       rem_day = 365 + leapYear - (n_year_day - allDay);    %ʣ������
       if rem_day>=0 && rem_day<=365+leapYear
       break
       end
end


year=ii;
flog = leapYear;
A=[31, 59+flog, 90+flog, 120+flog, 151+flog, 181+flog, 212+flog, 243+flog, 273+flog, 304+flog,  334+flog,  365+flog];

for i=1:12
   if rem_day<A(i)+1
   month = i;
   break
   end
end
if i>1
   day = rem_day-A(i-1);
else
   day = rem_day;
end






      
