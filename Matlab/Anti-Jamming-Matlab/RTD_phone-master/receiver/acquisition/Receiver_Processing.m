
function [CodPhs, fd] = Receiver_Processing(IFData, IF, Carphs, fcode, fs, PRNID , DispFlag)

global STR_Constants;

fd = -1;
CodPhs = -1;

global SNR_buffer
SNR_buffer= zeros(100,1);

for i = 1:20
    
    % Ƶ�ʵĴ�����������������Ϊ1/(2*T_Coherence)
%     fd_temp = (i-11)*500; 
    fd_temp = 0;
    
    % ���ն��±�Ƶ
    [DNCSig, ~] = TRX_DownConvert(IFData, IF + fd_temp, Carphs, fs);
        
%     [CM_CodPhs] = CM_SerialBlock_CodPhsSrh(DNCSig',fcode, PRNID, fs, DispFlag);
%     
    [CM_CodPhs] =CM_SerialBlockFold_CodPhsSrh(IFData',fcode, PRNID, fs, 1, DispFlag);
%     
%     [CM_CodPhs, dfreq] = CM_ParallelBlock_CodPhsSrh(DNCSig', fcode, PRNID, fs, DispFlag);

    if (CM_CodPhs>0)
        
        disp(['CH' num2str(PRNID) 'CM Code Phase Search Successed, Go into CL Code Phase Search!']);

        CodPhs = CL_CodPhs_Search(DNCSig', fcode, PRNID, CM_CodPhs, fs, DispFlag);
        
        fd = fd_temp;
        
        return;
        
    end
    
end

figure,plot(SNR_buffer(1:100));
xlabel('������ۼӴ���');
ylabel('��ֵ����׵ı�ֵ');


if (CM_CodPhs==-1) 
    
    disp(['CH' num2str(PRNID) 'CM Code Phase Search Failed!']);  
    
end
