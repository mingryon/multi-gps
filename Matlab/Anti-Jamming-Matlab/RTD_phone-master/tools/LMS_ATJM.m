clc;clear;close all;
Rnk = 128;      %LMS����Ӧ�˲�������
u = 0.0000001;  %LMS����Ӧ�˲���Ȩֵ������
fs = 62e6;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fid = fopen('I:\gnssdata\CaoxiNorthRoadtoSJTUxuhui.dat','r');
data = fread(fid,2*62e6*0.1,'bit8');
fclose(fid);
N = length(data);
x_i = data(1:2:N)';
x_q = data(2:2:N)';
N=N/2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
w_i=zeros(1,Rnk);%I֧·�˲�����ӦȨֵ
w_q=zeros(1,Rnk);%Q֧·�˲�����ӦȨֵ
%�ֱ��I/Q֧·LMS����Ӧ�˲�����
%����ֱ�Ϊx_i,x_q���˲�����ֱ�Ϊe_i,e_q
for n=Rnk+1:N-100   
    y_i(n)= w_i*[x_i(n-1:-1:n-Rnk)]';
    e_i(n)= x_i(n)-y_i(n);
%     e_i(n)= -y_i(n);
    w_i=w_i+2*u*e_i(n)*[x_i(n-1:-1:n-Rnk)];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    y_q(n)= w_q*[x_q(n-1:-1:n-Rnk)]';
    e_q(n)= x_q(n)-y_q(n);
    w_q=w_q+2*u*e_q(n)*[x_q(n-1:-1:n-Rnk)];
end
N=N-100;
% figure,plot(20*log10(abs(fft(x_i+i*x_q))),'-*r') %�˲�����ԭʼƵ��
figure,plot((-N/2:N/2-1)*fs/N,20*log10(abs(fftshift(fft(x_i(1:N)+i*x_q(1:N))))),'-*r')
% figure,plot(20*log10(abs(fft(y_i+i*y_q))),'-*r') %�˲���������Ƶ��
figure,plot((-N/2:N/2-1)*fs/N,20*log10(abs(fftshift(fft(e_i(1:N)+i*e_q(1:N))))),'-*r')