function timeDelay_CDF_plot(X1, YMatrix1)
%CREATEFIGURE(X1, YMATRIX1)
%  X1:  x ���ݵ�ʸ��
%  YMATRIX1:  y ���ݵľ���

%  �� MATLAB �� 30-Aug-2017 21:36:05 �Զ�����

% ���� figure
figure('InvertHardcopy','off','PaperSize',[20.99999864 29.69999902],...
    'Color',[1 1 1]);

% ���� axes
axes1 = axes;
hold(axes1,'on');

% ʹ�� plot �ľ������봴������
plot1 = plot(X1,YMatrix1,'LineWidth',3);
set(plot1(1),'DisplayName','elevation (0,15)','Color',[0 0 0]);
set(plot1(2),'DisplayName','elevation (15,30)',...
    'Color',[0.749019622802734 0 0.749019622802734]);
set(plot1(3),'DisplayName','elevation (30,45)',...
    'Color',[0 0.447058826684952 0.74117648601532]);
set(plot1(4),'DisplayName','elevation (45,60)',...
    'Color',[0.466666668653488 0.674509823322296 0.18823529779911]);
set(plot1(5),'DisplayName','elevation (60,75)',...
    'Color',[0.929411768913269 0.694117665290833 0.125490203499794]);
set(plot1(6),'DisplayName','elevation (75,90)',...
    'Color',[0.800000011920929 0 0]);

% ���� xlabel
xlabel({'Time delay (m)'},'Margin',2,'FontWeight','bold','FontName','Arial');

% ���� title
title({''},'Margin',2,'FontName','Arial');

% ���� ylabel
ylabel({'Cumulative distribution'},'Margin',2,'FontWeight','bold',...
    'FontName','Arial');

% ȡ�������е�ע���Ա���������� X ��Χ
xlim(axes1,[0 1000]);
% ȡ�������е�ע���Ա���������� Y ��Χ
ylim(axes1,[0 1]);
% ȡ�������е�ע���Ա���������� Z ��Χ
zlim(axes1,[-1 1]);
box(axes1,'on');
grid(axes1,'on');
% ������������������
set(axes1,'FontName','Arial','FontSize',24,'FontWeight','bold','XMinorGrid',...
    'on','YMinorGrid','on','YTick',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1],...
    'YTickLabel',...
    {'0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'},...
    'ZMinorGrid','on');
% ���� legend
legend1 = legend(axes1,'show');
set(legend1,...
    'Position',[0.660899653979238 0.583806949823068 0.297298578395001 0.273510963939201],...
    'FontSize',18,...
    'EdgeColor',[0 0 0]);

