function  [parameter] = ephStateCal(parameter, fileNameBds, fileNameGps)
% �����º������ļ�����������״̬����

[satPara, ~] = satellite_status_cal(parameter.SOW(1,:), fileNameBds, fileNameGps, parameter.pos_xyz);
% ���㱻�ڵ����ǵ���Ŀ
parameter.blockNum = satPara.GPS.sys.prnVisNum - parameter.satNum;
parameter.GDOP_ratio = parameter.GDOP./ satPara.GPS.sys.GDOP;

    
