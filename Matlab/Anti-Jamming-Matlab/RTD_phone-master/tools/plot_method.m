
% �������������������� ������ͼ�ϳ���ͼ��ʽ ������������������������
h0=figure;
hf=open('D:\�������Ĳ���\Journal\ͼ\NEW\fadingFrequency\IGSO_hist_90.fig'); 
h=findobj(hf);
figure(h0);hs=subplot(2,3,6); 
copyobj(h(3:end),hs) 
close(hf) 


fig = findall(gca,'type','line');
ydata_1 = get(fig, 'ydata');
y_2(1,:) = ydata_1{1};
y_2(2,:) = ydata_1{2};
y_2(3,:) = ydata_1{3};
y_2(4,:) = ydata_1{4};
y_2(5,:) = ydata_1{5};
x = 0 : 86400;

figure();
yyaxis left
plot(x, y_1(1,:))
yyaxis right
plot(x, y_2(1,:))
hold on

%���������� ��ͼ�� ������������%
open('figname.fig');
lh = findall(gca, 'type', 'hist');% ���ͼ���ж������ߣ�lhΪһ������
xc = get(lh, 'xdata');            % ȡ��x�����ݣ�xc��һ��Ԫ������
yc = get(lh, 'ydata');            % ȡ��y�����ݣ�yc��һ��Ԫ������
%�����ȡ�õ�2�����ߵ�x��y����
x2=xc{2};
y2=yc{2};

%������������ ��һ�ֶ��� ������������
h_line=get(gca,'Children');%get line handles
xdata=get(h_line,'Xdata');
ydata=get(h_line,'Ydata');

