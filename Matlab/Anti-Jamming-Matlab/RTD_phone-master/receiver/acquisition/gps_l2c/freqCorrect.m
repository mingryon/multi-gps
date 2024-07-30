function df = freqCorrect( array, peak_idx, d)
%����Ƶ�������ط���״����׼ȷ�ķ�ֵλ�ã���������������Ƿ���ƣ�����EPL��������
%������CM���񣬱���ͬ�������Ρ�
% ����-- array: ��ͬƵ�ʵ���ط�ֵ��1ά����  peak_idx:��ֵλ��  d:ÿ�����Ƶ�ʼ��
% ���-- df = ��ʵƵ��ֵ - ����Ƶ��ֵ

N = length(array);

if (peak_idx == N || peak_idx == 1)
    df = 0;
    return;
else
    E = array(peak_idx-1);
    P = array(peak_idx);
    L = array(peak_idx+1);
end

if E>L
    df = 0.5*d*(L-E)/(P-L);
else
    df = 0.5*d*(L-E)/(P-E);
end