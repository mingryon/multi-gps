function  bitSync_plot( array ,bitSyncResults,sv_acq_cfg)
%this program is to plot bitsync results
sv = bitSyncResults.sv;
figure(20+sv);mesh(array);
ylabel('Ƶ�ʲ���/��','fontsize',16);
xlabel('����λ��/ms','fontsize',16);
zlabel('���ֵ','fontsize',16)
end

