function fadFreq_mean(X1, YMatrix1, Y1)
%CREATEFIGURE(X1, YMATRIX1, Y1)
%  X1:  x ���ݵ�ʸ��
%  YMATRIX1:  y ���ݵľ���
%  Y1:  y ���ݵ�ʸ��

%  �� MATLAB �� 31-Aug-2017 17:18:07 �Զ�����

% ���� figure
figure('InvertHardcopy','off','Color',[1 1 1]);

% ���� axes
axes1 = axes;
hold(axes1,'on');

% ����������� left ��
yyaxis(axes1,'left');
% ʹ�� plot �ľ������봴������
plot1 = plot(X1,YMatrix1,'LineWidth',3);
set(plot1(1),'DisplayName','MEO');
set(plot1(2),'DisplayName','IGSO','Color',[0 0.498039215803146 0]);

% ���� ylabel
ylabel('Mean of NGEO satellite (Hz)');

% ������������������
set(axes1,'YColor',[0 0.447 0.741]);
% ȡ�������е�ע���Ա���������� Y ��Χ
ylim(axes1,[0 0.12]);
% ����������� right ��
yyaxis(axes1,'right');
% ���� plot
plot(X1,Y1,'DisplayName','GEO','LineWidth',3,'Color',[1 0 0]);

% ���� ylabel
ylabel('Mean of GEO satellite (Hz)','FontSize',26.4);

% ������������������
set(axes1,'YColor',[0.85 0.325 0.098]);
% ȡ�������е�ע���Ա���������� Y ��Χ
ylim(axes1,[0 0.0012]);
% ȡ�������е�ע���Ա���������� X ��Χ
xlim(axes1,[0 90]);
% ȡ�������е�ע���Ա���������� Z ��Χ
zlim(axes1,[-1 0]);
box(axes1,'on');
% ������������������
set(axes1,'FontName','Arial','FontSize',24,'FontWeight','bold');
% ���� legend
legend1 = legend(axes1,'show');
set(legend1,...
    'Position',[0.749094043703852 0.760667164506039 0.127340821700447 0.170825331087534],...
    'FontSize',18);

