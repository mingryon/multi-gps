function timeDelay_mean_plot(X1, Y1, X2, Y2)
%CREATEFIGURE(X1, Y1, X2, Y2)
%  X1:  x ���ݵ�ʸ��
%  Y1:  y ���ݵ�ʸ��
%  X2:  x ���ݵ�ʸ��
%  Y2:  y ���ݵ�ʸ��

%  �� MATLAB �� 30-Aug-2017 21:33:13 �Զ�����

% ���� figure
figure('InvertHardcopy','off','Color',[1 1 1]);

% ���� axes
axes1 = axes;
hold(axes1,'on');

% ���� plot
plot(X1,Y1,'DisplayName','Experimental data',...
    'MarkerFaceColor',[0 0.447058826684952 0.74117648601532],...
    'MarkerSize',10,...
    'Marker','o',...
    'LineStyle','none');

% ���� plot
plot(X2,Y2,'DisplayName','Fitted distribution','LineWidth',3,...
    'Color',[1 0 0]);

% ���� xlabel
xlabel({'Elevation angle (��)'});

% ���� ylabel
ylabel({'Mean of time delay (m)'});

% ȡ�������е�ע���Ա���������� X ��Χ
xlim(axes1,[0 90]);
% ȡ�������е�ע���Ա���������� Y ��Χ
ylim(axes1,[50 400]);
% ȡ�������е�ע���Ա���������� Z ��Χ
zlim(axes1,[-1 1]);
box(axes1,'on');
% ������������������
set(axes1,'FontName','Arial','FontSize',24,'FontWeight','bold');
% ���� legend
legend1 = legend(axes1,'show');
set(legend1,...
    'Position',[0.643193211277981 0.82816048349508 0.335640129814786 0.143707331416939],...
    'FontSize',21.6);

