function [H_o_j, A_j, H_x_j] = calcHoj(p_f_G, msckfState, camStateIndices)
%�������ܣ�������ͶӰ����MSCKF״̬�����ſ˱Ⱦ���MSCKF�۲�ģ�ͣ�
%
%����ֵ��
%      H_o_j��A_j'*H_x_j
%      A_j��ΪH_f_j�������ռ�任����
%           H_f_j���������ϵ���������(x y)����������ϵ��3D����ſ˱Ⱦ���           
%      H_x_j���õ��������ϵ���������(x y)��msckf��״̬�����ſ˱Ⱦ���
%����ֵ��
%      p_f_G����������global����ϵ������
%      msckfState����ǰmsckf״̬
%      camStateIndices����ǰ���������״̬����

%CALCHOJ Calculates H_o_j according to Mourikis 2007
% Inputs: p_f_G: feature location in the Global frame
%         msckfState: the current window of states
%         camStateIndex: i, with camState being the ith camera pose in the window       
% Outputs: H_o_j, A


N = length(msckfState.camStates);
M = length(camStateIndices);
H_f_j = zeros(2*M, 3);
H_x_j = zeros(2*M, 12 + 6*N);


c_i = 1;
for camStateIndex = camStateIndices
    camState = msckfState.camStates{camStateIndex};

    C_CG = quatToRotMat(camState.q_CG);
    %The feature position in the camera frame
    %�õ�3D���ڵ�ǰ�������ϵ�µ�����
    p_f_C = C_CG*(p_f_G - camState.p_C_G);

    X = p_f_C(1);
    Y = p_f_C(2);
    Z = p_f_C(3);

    %�õ��������ϵ���������Է����������ſ˱Ⱦ���
    % x = X/Z y = Y/Z
    % |1/Z  0   -X/Z^2|
    % |0   1/Z  -Y/Z^2|
    J_i = (1/Z)*[1 0 -X/Z; 0 1 -Y/Z];

    %�õ��������ϵ���������(x y)����������ϵ��3D����ſ˱Ⱦ���
    H_f_j((2*c_i - 1):2*c_i, :) = J_i*C_CG;

    %ע�⣺msckf��״̬�������״̬����ͶӰ���ֻ������йأ����ֻ�������̬��λ���󵼵��ſ˱Ȳ�Ϊ0
    %�õ��������ϵ���������(x y)�������̬���ſ˱Ⱦ���
    H_x_j((2*c_i - 1):2*c_i,12+6*(camStateIndex-1) + 1:12+6*(camStateIndex-1) + 3) = J_i*crossMat(p_f_C);
    %�õ��������ϵ���������(x y)�����λ�õ��ſ˱Ⱦ���
    H_x_j((2*c_i - 1):2*c_i,(12+6*(camStateIndex-1) + 4):(12+6*(camStateIndex-1) + 6)) = -J_i*C_CG;

    c_i = c_i + 1;
end

%�ο����ף���The Battle for Filter Supremacy: A Comparative Study of the
%      Multi-State Constraint Kalman Filter and the Sliding Window Filter��
%��ʽ47
%error = z - z_hat = H_x_j * x + H_f_j * p + R_j(x��msckf�е�״̬��p��3D�㣬R_jΪ����)
% ����ͬ��H_f_j����ռ�任����A_j��
% ==> A_j' * error = A_j' * H_x_j * x + A_j' * H_f_j * p + A_j' * R_j * A_j
% ==> A_j' * error = A_j' * H_x_j * x + 0 + A_j' * R_j * A_j
A_j = null(H_f_j');
H_o_j = A_j'*H_x_j;

end

