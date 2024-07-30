%%%%%% Example of Training/Testing a 2d-mixture of 2 gaussians driven by
%%%%%% HMM
clear; clc;close all;


d                                   = 4;    % ״̬��Ŀ
m                                   = 1;   %  ��˹�ֲ�ά��
L                                   = 1;    % ����L������
R                                   = 1;    % ѵ��R������
Ntrain                              = 5000;    % ѵ��������
Ntest                               = 10000;    % ����������
options.nb_ite                      = 2000;      % ��������

PI                                  = [0.25; 0.25; 0.25; 0.25];  % ״̬��ʼ����
A                                = [0.85, 0.05, 0.05, 0.05;...
                                      0.05, 0.85, 0.05, 0.05;...
                                      0.05, 0.05, 0.85, 0.05;...
                                      0.05, 0.05, 0.05, 0.85;];  % ״̬ת�Ƹ��ʾ���
M                                   = cat(3 , [-49] , [-8], [-2], [0]); % ��ֵ����
S                                   = cat(3 , [3] , [4], [5], [6]);    % Э�������

[Ztrain , Xtrain]                   = sample_ghmm(Ntrain , PI , A , M , S , L);
Xtrain                              = Xtrain - 1;

%%%%% initial parameters %%%%
PI0 = [0.3 ; 0.3; 0.3; 0.1];  % ״̬��ʼ����

A0                                   = [0.6, 0.1, 0.1, 0.1;...
                                      0.2, 0.5, 0.1, 0.2;...
                                      0.1, 0.3, 0.7, 0.2;...
                                      0.1, 0.1, 0.1, 0.5;];  % ״̬ת�Ƹ��ʾ���

M0                                   = cat(3 , [-45] , [-10], [0], [2]); % ��ֵ����
S0                                   = cat(3 , [5] , [2], [6], [1]);    % Э�������

%%%%% EM algorithm %%%%

[logl , PIest , Aest , Mest , Sest] = em_ghmm(Ztrain , PI0 , A0 , M0 , S0 , options);


