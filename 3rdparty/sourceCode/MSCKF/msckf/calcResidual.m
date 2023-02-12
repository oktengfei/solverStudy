function [r_j] = calcResidual(p_f_G, camStates, measurements)
%�������ܣ������Ż�������3D���������ƥ��������֮�����ͶӰ�в�
%
%����ֵ��
%      r_j���������Ӧ�����еĹ۲�͹���ֵ�Ĳв�
%����ֵ��
%      p_f_G��������3D����
%      camStates�����״̬
%      measurements���������������ϵ������

%CALCRESIDUAL Calculates the residual for a feature position

% measurements is 2 x M_j
% camStates is a cell array of the camState structs for the states
%   included in measurements
    r_j = NaN(2*size(camStates,2), 1);
    for i = 1:size(camStates,2)
        %��global����ϵ��3D������ת����camera����ϵ��
        C_CG = quatToRotMat(camStates{i}.q_CG);
        p_f_C = C_CG * (p_f_G - camStates{i}.p_C_G);
        %�����������3D�������������ƥ���֮�����ͶӰ�в�
        %�õ���������camera����ϵ�µ��������
        zhat_i_j = p_f_C(1:2)/p_f_C(3);
        iStart = 2*(i-1)+1;
        iEnd = 2*i;
        r_j(iStart:iEnd) = measurements(:,i) - zhat_i_j;
    end
        
end