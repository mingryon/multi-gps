function timeDelay_plot(xvector1, yvector1, X1, Y1, ...
    xvector2, yvector2, X2, Y2, ...
    xvector3, yvector3, X3, Y3, ...
    xvector4, yvector4, X4, Y4, ...
    xvector5, yvector5, X5, Y5, ...
    xvector6, yvector6, X6, Y6)
%CREATEFIGURE(XVECTOR1, YVECTOR1, X1, Y1, YVECTOR2, Y2, XVECTOR2, YVECTOR3, Y3, YVECTOR4, Y4, XVECTOR3, YVECTOR5, Y5, XVECTOR4, YVECTOR6, Y6)
%  XVECTOR1:  bar xvector
%  YVECTOR1:  bar yvector
%  X1:  x ���ݵ�ʸ��
%  Y1:  y ���ݵ�ʸ��
%  YVECTOR2:  bar yvector
%  Y2:  y ���ݵ�ʸ��
%  XVECTOR2:  bar xvector
%  YVECTOR3:  bar yvector
%  Y3:  y ���ݵ�ʸ��
%  YVECTOR4:  bar yvector
%  Y4:  y ���ݵ�ʸ��
%  XVECTOR3:  bar xvector
%  YVECTOR5:  bar yvector
%  Y5:  y ���ݵ�ʸ��
%  XVECTOR4:  bar xvector
%  YVECTOR6:  bar yvector
%  Y6:  y ���ݵ�ʸ��

%  �� MATLAB �� 30-Aug-2017 18:44:34 �Զ�����

% ���� figure
figure;

% ���� subplot
subplot1 = subplot(2,3,1);
hold(subplot1,'on');

% ���� bar
bar(xvector1,yvector1,'DisplayName','Experimental data');

% ���� plot
plot(X1,Y1,'ZDataSource','','DisplayName','Fitted distribution',...
    'LineWidth',3,...
    'Color',[1 0 0]);

% ���� title
title({'elevation (0, 15)'},'FontWeight','bold');

% ���� ylabel
ylabel({'Probability density'});

% ȡ�������е�ע���Ա���������� Y ��Χ
ylim(subplot1,[0 0.0075]);
box(subplot1,'on');
% ������������������
set(subplot1,'FontName','Arial','FontSize',16,'FontWeight','bold','XTick',...
    zeros(1,0));
% ���� legend
legend1 = legend(subplot1,'show');
set(legend1,...
    'Position',[0.199044312367083 0.867050696698932 0.142458097450782 0.0577889432260139],...
    'FontSize',10);

% ���� subplot
subplot2 = subplot(2,3,2);
hold(subplot2,'on');

% ���� bar
bar(xvector2,yvector2,'DisplayName','Experimental data');

% ���� plot
plot(X2,Y2,'ZDataSource','','DisplayName','Fitted distribution',...
    'LineWidth',3,...
    'Color',[1 0 0]);

% ���� title
title({'elevation (15, 30)'},'FontWeight','bold');

% ȡ�������е�ע���Ա���������� Y ��Χ
ylim(subplot2,[0 0.0075]);
box(subplot2,'on');
% ������������������
set(subplot2,'FontName','Arial','FontSize',16,'FontWeight','bold','XTick',...
    zeros(1,0),'YTick',zeros(1,0));
% ���� subplot
subplot3 = subplot(2,3,3);
hold(subplot3,'on');

% ���� bar
bar(xvector3,yvector3,'DisplayName','Experimental data');

% ���� plot
plot(X3,Y3,'ZDataSource','','DisplayName','Fitted distribution',...
    'LineWidth',3,...
    'Color',[1 0 0]);

% ���� title
title({'elevation (30, 45)'},'FontWeight','bold');

% ȡ�������е�ע���Ա���������� Y ��Χ
ylim(subplot3,[0 0.0075]);
box(subplot3,'on');
% ������������������
set(subplot3,'FontName','Arial','FontSize',16,'FontWeight','bold','XTick',...
    zeros(1,0),'YTick',zeros(1,0));
% ���� subplot
subplot4 = subplot(2,3,4);
hold(subplot4,'on');

% ���� bar
bar(xvector4,yvector4,'DisplayName','Experimental data');

% ���� plot
plot(X4,Y4,'ZDataSource','','DisplayName','Fitted distribution',...
    'LineWidth',3,...
    'Color',[1 0 0]);

% ���� xlabel
xlabel({'Time delay (m)'});

% ���� title
title({'elevation (45, 60)'},'FontWeight','bold');

% ���� ylabel
ylabel({'Probability density'});

% ȡ�������е�ע���Ա���������� Y ��Χ
ylim(subplot4,[0 0.0075]);
box(subplot4,'on');
% ������������������
set(subplot4,'FontName','Arial','FontSize',16,'FontWeight','bold');
% ���� subplot
subplot5 = subplot(2,3,5);
hold(subplot5,'on');

% ���� bar
bar(xvector5,yvector5,'DisplayName','Experimental data');

% ���� plot
plot(X5,Y5,'ZDataSource','','DisplayName','Fitted distribution',...
    'LineWidth',3,...
    'Color',[1 0 0]);

% ���� xlabel
xlabel({'Time delay (m)'});

% ���� title
title({'elevation (60, 75)'},'FontWeight','bold');

% ȡ�������е�ע���Ա���������� Y ��Χ
ylim(subplot5,[0 0.0075]);
box(subplot5,'on');
% ������������������
set(subplot5,'FontName','Arial','FontSize',16,'FontWeight','bold','YTick',...
    zeros(1,0));
% ���� subplot
subplot6 = subplot(2,3,6);
hold(subplot6,'on');

% ���� bar
bar(xvector6,yvector6,'DisplayName','Experimental data');

% ���� plot
plot(X6,Y6,'ZDataSource','','DisplayName','Fitted distribution',...
    'LineWidth',3,...
    'Color',[1 0 0]);

% ���� xlabel
xlabel({'Time delay (m)'});

% ���� title
title({'elevation (75, 90)'},'FontWeight','bold');

% ȡ�������е�ע���Ա���������� Y ��Χ
ylim(subplot6,[0 0.0075]);
box(subplot6,'on');
% ������������������
set(subplot6,'FontName','Arial','FontSize',16,'FontWeight','bold','YTick',...
    zeros(1,0));
