function fadFreq_GEO(xvector1, yvector1, X1, Y1)
%CREATEFIGURE(XVECTOR1, YVECTOR1, X1, Y1)
%  XVECTOR1:  bar xvector
%  YVECTOR1:  bar yvector
%  X1:  x ���ݵ�ʸ��
%  Y1:  y ���ݵ�ʸ��

%  �� MATLAB �� 01-Sep-2017 13:36:06 �Զ�����

% ���� figure
figure('InvertHardcopy','off','PaperSize',[20.99999864 29.69999902],...
    'Color',[1 1 1]);

% ���� axes
axes1 = axes;
hold(axes1,'on');

% ���� bar
bar1 = bar(xvector1,yvector1,'DisplayName','Experomental data');
baseline1 = get(bar1,'BaseLine');
set(baseline1,'Color',[0 0 0]);

% ���� plot
plot(X1,Y1,'ZDataSource','','DisplayName','Fitted distribution',...
    'LineWidth',3,...
    'Color',[1 0 0]);

% ���� xlabel
xlabel('Fading frequency (Hz)');

% ���� ylabel
ylabel('Probability density');

% ȡ�������е�ע���Ա���������� X ��Χ
xlim(axes1,[0 0.003]);
% ȡ�������е�ע���Ա���������� Y ��Χ
ylim(axes1,[0 1600]);
% ȡ�������е�ע���Ա���������� Z ��Χ
zlim(axes1,[-1 1]);
box(axes1,'on');
% ������������������
set(axes1,'FontName','Arial','FontSize',24,'FontWeight','bold');
% ���� legend
legend1 = legend(axes1,'show');
set(legend1,...
    'Position',[0.731401270262578 0.860171412425591 0.197607313843613 0.0859826787981089],...
    'FontSize',18);

