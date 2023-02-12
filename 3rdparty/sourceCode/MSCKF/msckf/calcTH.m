function [T_H, Q_1] = calcTH(H_o)
%�������ܣ�QR�ֽ�H_o���󣬲����޳�Q�е����У��Լ�R�ж�Ӧ����
%����ֵ��
%      T_H��R����
%      Q_1��Q����
%����ֵ��
%      H_o�����ֽ����

%CALCTH Calculates T_H matrix according to Mourikis 2007

%��H�������QR�ֽ�
[Q,R] = qr(H_o);

%Find all zero rows of R
%�ж�R�����Ƿ�ĳһ��ȫΪ0
%���磺
%     |1 2 4|
% R = |0 0 0|
%     |3 5 6|
%��all(R==0,2)=[0;1;0]
isZeroRow = all(R==0, 2);

%Extract relevant matrices
%H_o = Q * R
%             |R1|
%    = |Q1 Q2||0 |
%��ȡR�����з����е�Ԫ��
T_H = R(~isZeroRow, :);
%��ȡQ�����з����е�Ԫ��
Q_1 = Q(:, ~isZeroRow);

end

